#!powershell

# Copyright: (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = "str"; required = $true }
        destination_host = @{ type = "str"; required = $true }
        vmm_server = @{ type = "str"; required = $false }
        path = @{ type = "str"; required = $false }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name
$destinationHost = $module.Params.destination_host
$vmmServer = $module.Params.vmm_server
$path = $module.Params.path

$module.Result.changed = $false

try {
    # Connect to SCVMM server
    $vmmConnection = Connect-SCVMMServerSession -VMMServer $vmmServer -Module $module

    # Get the virtual machine
    $vm = Get-SCVirtualMachine -VMMServer $vmmConnection -Name $name -ErrorAction Stop

    if (-not $vm) {
        $module.FailJson("Virtual machine '$name' not found")
    }

    # Get the destination host
    $destHost = Get-SCVMHost -VMMServer $vmmConnection -ComputerName $destinationHost -ErrorAction Stop

    if (-not $destHost) {
        $module.FailJson("Destination host '$destinationHost' not found")
    }

    # Get current host information
    $currentHost = $vm.VMHost.Name

    # Set return values
    $module.Result.source_host = $currentHost
    $module.Result.destination_host = $destinationHost

    # Check if VM is already on the destination host
    if ($currentHost -eq $destinationHost) {
        $module.Result.changed = $false
        $module.ExitJson()
    }

    # Set diff information
    $module.Diff.before = @{
        host = $currentHost
    }

    $module.Diff.after = @{
        host = $destinationHost
    }

    # Perform migration if not in check mode
    if (-not $module.CheckMode) {
        $migrateParams = @{
            VM = $vm
            VMHost = $destHost
        }

        if ($path) {
            $migrateParams.Path = $path
        }

        try {
            Move-SCVirtualMachine @migrateParams -ErrorAction Stop | Out-Null
        }
        catch {
            $module.FailJson("Failed to migrate VM: $($_.Exception.Message)")
        }
    }

    $module.Result.changed = $true
    $module.ExitJson()
}
catch {
    $module.FailJson("An error occurred: $($_.Exception.Message)", $_)
}
