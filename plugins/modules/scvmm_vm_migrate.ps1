#!powershell

# Copyright: (c) 2026, Ansible Project
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        name = @{
            type = "str"
            required = $true
        }
        vmm_server = @{
            type = "str"
            required = $true
        }
        destination_host = @{
            type = "str"
            required = $false
        }
        destination_path = @{
            type = "str"
            required = $false
        }
        migration_type = @{
            type = "str"
            required = $false
            choices = @("auto", "live", "cluster", "lan")
            default = "auto"
        }
        start_vm_on_target = @{
            type = "bool"
            default = $false
        }
        highly_available = @{
            type = "bool"
            required = $false
        }
        block_if_host_busy = @{
            type = "bool"
            default = $false
        }
        timeout = @{
            type = "int"
            default = 600
        }
    }
    required_one_of = @(
        ,@("destination_host", "destination_path")
    )
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name
$vmm_server = $module.Params.vmm_server
$destination_host = $module.Params.destination_host
$destination_path = $module.Params.destination_path
$migration_type = $module.Params.migration_type
$start_vm_on_target = $module.Params.start_vm_on_target
$highly_available = $module.Params.highly_available
$block_if_host_busy = $module.Params.block_if_host_busy
$timeout = $module.Params.timeout

$module.Result.changed = $false
$module.Result.vm_name = $name
$module.Result.source_host = $null
$module.Result.destination_host = $null
$module.Result.source_path = $null
$module.Result.destination_path = $null
$module.Result.migration_method = $null

# Import VirtualMachineManager module
try {
    Import-Module VirtualMachineManager -ErrorAction Stop
} catch {
    $module.FailJson("Failed to import VirtualMachineManager module: $($_.Exception.Message)")
}

# Connect to SCVMM server
try {
    $vmmConnection = Get-SCVMMServer -ComputerName $vmm_server -ErrorAction Stop
} catch {
    $module.FailJson("Failed to connect to SCVMM server '$vmm_server': $($_.Exception.Message)")
}

# Get the VM
try {
    $vm = Get-SCVirtualMachine -VMMServer $vmmConnection -Name $name -ErrorAction Stop
} catch {
    $module.FailJson("Failed to find VM '$name': $($_.Exception.Message)")
}

# Store current state for result
$module.Result.source_host = $vm.VMHost.Name
$module.Result.source_path = $vm.Location

# Get destination host object if specified
$targetHost = $null
if ($destination_host) {
    try {
        $targetHost = Get-SCVMHost -VMMServer $vmmConnection -ComputerName $destination_host -ErrorAction Stop
    } catch {
        $module.FailJson("Failed to find destination host '$destination_host': $($_.Exception.Message)")
    }
}

# Check if migration is needed (idempotency)
$needs_migration = $false
$migration_reason = @()

# Check if host migration is needed
if ($destination_host) {
    if ($vm.VMHost.Name -ne $destination_host) {
        $needs_migration = $true
        $migration_reason += "host change required (current: $($vm.VMHost.Name), desired: $destination_host)"
    }
}

# Check if storage migration is needed
if ($destination_path) {
    # Normalize paths for comparison (remove trailing slashes)
    $currentPath = $vm.Location.TrimEnd('\')
    $desiredPath = $destination_path.TrimEnd('\')

    if ($currentPath -ne $desiredPath) {
        $needs_migration = $true
        $migration_reason += "storage path change required (current: $currentPath, desired: $desiredPath)"
    }
}

# If no migration needed, exit with success
if (-not $needs_migration) {
    $module.Result.msg = "VM is already at the desired location"
    $module.Result.destination_host = $vm.VMHost.Name
    $module.Result.destination_path = $vm.Location
    $module.ExitJson()
}

# Build migration parameters
$migrationParams = @{
    VM = $vm
    ErrorAction = "Stop"
}

# Add destination host if specified
if ($targetHost) {
    $migrationParams.VMHost = $targetHost
}

# Add destination path if specified
if ($destination_path) {
    $migrationParams.Path = $destination_path
}

# Apply migration type options
switch ($migration_type) {
    "lan" {
        # Force LAN transfer (network migration)
        $migrationParams.UseLAN = $true
        $module.Result.migration_method = "network_transfer"
    }
    "cluster" {
        # Force cluster migration (for saved state VMs)
        $migrationParams.UseCluster = $true
        $module.Result.migration_method = "cluster_migration"
    }
    "live" {
        # Let SCVMM use live migration (default for running VMs)
        # No special parameter needed - SCVMM will use live migration if available
        $module.Result.migration_method = "live_migration"
    }
    "auto" {
        # Let SCVMM choose the fastest available method
        $module.Result.migration_method = "automatic"
    }
}

# Add optional parameters
if ($start_vm_on_target) {
    $migrationParams.StartVMOnTarget = $true
}

if ($null -ne $highly_available) {
    $migrationParams.HighlyAvailable = $highly_available
}

if ($block_if_host_busy) {
    $migrationParams.BlockLiveMigrationIfHostBusy = $true
}

# Perform the migration
if (-not $module.CheckMode) {
    try {
        # Start the migration
        $migrationJob = Move-SCVirtualMachine @migrationParams -RunAsynchronously

        # Wait for the job to complete with timeout
        $deadline = (Get-Date).AddSeconds($timeout)
        $jobCompleted = $false

        while ((Get-Date) -lt $deadline) {
            # Refresh job status
            $currentJob = Get-SCJob -ID $migrationJob.ID -ErrorAction SilentlyContinue

            if ($null -eq $currentJob) {
                # Job might have completed and been cleared
                break
            }

            switch ($currentJob.Status) {
                "Completed" {
                    $jobCompleted = $true
                    break
                }
                "Failed" {
                    $errorMsg = if ($currentJob.ErrorInfo.Count -gt 0) {
                        $currentJob.ErrorInfo[0].Problem
                    } else {
                        "Migration job failed"
                    }
                    $module.FailJson("Migration failed: $errorMsg")
                }
                "CompletedWithErrors" {
                    $errorMsg = if ($currentJob.ErrorInfo.Count -gt 0) {
                        $currentJob.ErrorInfo[0].Problem
                    } else {
                        "Unknown error"
                    }
                    $module.FailJson("Migration completed with errors: $errorMsg")
                }
                "Canceled" {
                    $module.FailJson("Migration was canceled")
                }
            }

            if ($jobCompleted) {
                break
            }

            Start-Sleep -Seconds 5
        }

        if (-not $jobCompleted) {
            # Attempt to stop the job if it's still running
            try {
                Stop-SCJob -Job $currentJob -ErrorAction SilentlyContinue | Out-Null
            } catch {
                # Ignore errors when stopping job
            }
            $module.FailJson("Migration timed out after $timeout seconds")
        }

        # Get updated VM information
        $vm = Get-SCVirtualMachine -VMMServer $vmmConnection -Name $name -ErrorAction Stop

        # Update result with final state
        $module.Result.destination_host = $vm.VMHost.Name
        $module.Result.destination_path = $vm.Location
        $module.Result.changed = $true

        # Build success message
        $migrationDetails = @()
        if ($destination_host) {
            $migrationDetails += "host: $($module.Result.source_host) -> $($vm.VMHost.Name)"
        }
        if ($destination_path) {
            $migrationDetails += "path: $($module.Result.source_path) -> $($vm.Location)"
        }

        $module.Result.msg = "VM migrated successfully ($($migrationDetails -join ', '))"

    } catch {
        $module.FailJson("Failed to migrate VM: $($_.Exception.Message)")
    }
} else {
    # Check mode
    $module.Result.destination_host = if ($destination_host) { $destination_host } else { $vm.VMHost.Name }
    $module.Result.destination_path = if ($destination_path) { $destination_path } else { $vm.Location }
    $module.Result.msg = "Would migrate VM: $($migration_reason -join ', ')"
    $module.Result.changed = $true
}

$module.ExitJson()
