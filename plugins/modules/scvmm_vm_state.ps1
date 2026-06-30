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
        state = @{
            type = "str"
            required = $true
            choices = @("started", "stopped", "restarted", "suspended", "saved", "paused")
        }
        force = @{
            type = "bool"
            default = $false
        }
        timeout = @{
            type = "int"
            default = 300
        }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name
$vmm_server = $module.Params.vmm_server
$desired_state = $module.Params.state
$force = $module.Params.force
$timeout = $module.Params.timeout

$module.Result.changed = $false
$module.Result.vm_name = $name
$module.Result.previous_state = $null
$module.Result.current_state = $null

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
    $vm = Get-SCVirtualMachine -VMMServer $vmmConnection -Name $name -ErrorAction SilentlyContinue
} catch {
    $module.FailJson("Failed to query VM '$name': $($_.Exception.Message)")
}

# Check if VM exists
if ($null -eq $vm) {
    $module.FailJson("VM '$name' not found on SCVMM server '$vmm_server'.")
}

# Map VM status to Ansible state names
Function Get-AnsibleStateFromVM {
    param($VM)

    switch ($VM.Status) {
        "Running" { return "started" }
        "PowerOff" { return "stopped" }
        "Paused" { return "paused" }
        "Saved" { return "saved" }
        "Suspended" { return "suspended" }
        default { return $VM.Status.ToString().ToLower() }
    }
}

# Wait for VM to reach desired state
Function Wait-VMState {
    param(
        [object]$VM,
        [string[]]$ExpectedStates,
        [int]$TimeoutSeconds
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)

    while ((Get-Date) -lt $deadline) {
        $currentVM = Get-SCVirtualMachine -VMMServer $vmmConnection -Name $VM.Name -ErrorAction Stop
        $currentState = Get-AnsibleStateFromVM -VM $currentVM

        if ($currentState -in $ExpectedStates) {
            return $currentVM
        }

        # Also check if VM is in a transition state
        if ($currentVM.Status -eq "Running" -and "started" -in $ExpectedStates) {
            return $currentVM
        }

        Start-Sleep -Seconds 2
    }

    $module.FailJson("Timeout waiting for VM to reach state: $($ExpectedStates -join ', ')")
}

# Get current state
$current_state = Get-AnsibleStateFromVM -VM $vm
$module.Result.previous_state = $current_state

# Check if already in desired state (idempotency)
$state_matches = $false

switch ($desired_state) {
    "started" {
        if ($current_state -eq "started") {
            $state_matches = $true
        }
    }
    "stopped" {
        if ($current_state -eq "stopped") {
            $state_matches = $true
        }
    }
    "paused" {
        if ($current_state -eq "paused") {
            $state_matches = $true
        }
    }
    "saved" {
        if ($current_state -eq "saved") {
            $state_matches = $true
        }
    }
    "suspended" {
        if ($current_state -eq "suspended") {
            $state_matches = $true
        }
    }
    "restarted" {
        # Restart always causes a change
        $state_matches = $false
    }
}

if ($state_matches) {
    $module.Result.current_state = $current_state
    $module.Result.msg = "VM is already in desired state '$desired_state'"
    $module.ExitJson()
}

# Perform state transition
if (-not $module.CheckMode) {
    try {
        switch ($desired_state) {
            "started" {
                # Resume if paused, otherwise start
                if ($current_state -eq "paused") {
                    Resume-SCVirtualMachine -VM $vm -ErrorAction Stop | Out-Null
                    $vm = Wait-VMState -VM $vm -ExpectedStates @("started") -TimeoutSeconds $timeout
                } else {
                    Start-SCVirtualMachine -VM $vm -ErrorAction Stop | Out-Null
                    $vm = Wait-VMState -VM $vm -ExpectedStates @("started") -TimeoutSeconds $timeout
                }
                $module.Result.msg = "VM started successfully"
            }

            "stopped" {
                if ($force) {
                    Stop-SCVirtualMachine -VM $vm -Force -ErrorAction Stop | Out-Null
                } else {
                    Stop-SCVirtualMachine -VM $vm -Shutdown -ErrorAction Stop | Out-Null
                }
                $vm = Wait-VMState -VM $vm -ExpectedStates @("stopped") -TimeoutSeconds $timeout
                $module.Result.msg = if ($force) { "VM stopped forcefully" } else { "VM stopped gracefully" }
            }

            "restarted" {
                if ($force) {
                    # Force restart: hard stop then start
                    Stop-SCVirtualMachine -VM $vm -Force -ErrorAction Stop | Out-Null
                    $vm = Wait-VMState -VM $vm -ExpectedStates @("stopped") -TimeoutSeconds $timeout
                    Start-SCVirtualMachine -VM $vm -ErrorAction Stop | Out-Null
                    $vm = Wait-VMState -VM $vm -ExpectedStates @("started") -TimeoutSeconds $timeout
                } else {
                    # Graceful restart
                    Restart-SCVirtualMachine -VM $vm -Shutdown -ErrorAction Stop | Out-Null
                    $vm = Wait-VMState -VM $vm -ExpectedStates @("started") -TimeoutSeconds $timeout
                }
                $module.Result.msg = if ($force) { "VM restarted forcefully" } else { "VM restarted gracefully" }
            }

            "suspended" {
                Suspend-SCVirtualMachine -VM $vm -ErrorAction Stop | Out-Null
                $vm = Wait-VMState -VM $vm -ExpectedStates @("suspended") -TimeoutSeconds $timeout
                $module.Result.msg = "VM suspended successfully"
            }

            "saved" {
                Save-SCVirtualMachine -VM $vm -ErrorAction Stop | Out-Null
                $vm = Wait-VMState -VM $vm -ExpectedStates @("saved") -TimeoutSeconds $timeout
                $module.Result.msg = "VM saved successfully"
            }

            "paused" {
                Suspend-SCVirtualMachine -VM $vm -ErrorAction Stop | Out-Null
                $vm = Wait-VMState -VM $vm -ExpectedStates @("paused", "suspended") -TimeoutSeconds $timeout
                $module.Result.msg = "VM paused successfully"
            }
        }

        $module.Result.current_state = Get-AnsibleStateFromVM -VM $vm
        $module.Result.changed = $true

    } catch {
        $module.FailJson("Failed to change VM state to '$desired_state': $($_.Exception.Message)")
    }
} else {
    # Check mode
    $module.Result.current_state = $current_state
    $module.Result.msg = "Would change VM state from '$current_state' to '$desired_state'"
    $module.Result.changed = $true
}

$module.ExitJson()
