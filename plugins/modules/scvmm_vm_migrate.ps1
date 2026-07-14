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
    $vmmConnection = Connect-SCVMMServerSession -VMMServer $vmmServer -Module $module

    $vm = Get-SCVMMVirtualMachine -Module $module -VMMConnection $vmmConnection -Name $name

    $destHost = Get-SCVMHost -VMMServer $vmmConnection -ComputerName $destinationHost -ErrorAction Stop

    if (-not $destHost) {
        $module.FailJson("Destination host '$destinationHost' not found")
    }

    $currentHost = $vm.VMHost.Name
    $module.Result.source_host = $currentHost
    $module.Result.destination_host = $destinationHost

    if ($currentHost -eq $destinationHost) {
        $module.Result.changed = $false
        $module.ExitJson()
    }

    $module.Diff.before = @{
        host = $currentHost
    }

    $module.Diff.after = @{
        host = $destinationHost
    }

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
