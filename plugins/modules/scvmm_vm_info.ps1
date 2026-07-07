#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = "str" }
        vmm_server = @{ type = "str" }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

try {
    if ($module.Params.name) {
        $vms = @(Get-SCVirtualMachine -VMMServer $vmmConnection -Name $module.Params.name -ErrorAction Stop)
    }
    else {
        $vms = @(Get-SCVirtualMachine -VMMServer $vmmConnection -ErrorAction Stop)
    }
}
catch {
    $module.FailJson("Failed to query virtual machines: $($_.Exception.Message)", $_)
}

$module.Result.virtual_machines = @($vms | ForEach-Object {
        $hostName = $null
        if ($_.VMHost) {
            $hostName = $_.VMHost.Name
        }
        $cloudName = $null
        if ($_.Cloud) {
            $cloudName = $_.Cloud.Name
        }
        $creationTime = $null
        if ($_.CreationTime) {
            $creationTime = $_.CreationTime.ToString("o")
        }
        $osName = $null
        if ($_.OperatingSystem) {
            $osName = $_.OperatingSystem.Name
        }
        @{
            id = $_.ID.ToString()
            name = $_.Name
            status = $_.Status.ToString()
            host = $hostName
            cpu_count = $_.CPUCount
            memory_mb = $_.Memory
            generation = $_.Generation
            description = $_.Description
            cloud = $cloudName
            creation_time = $creationTime
            operating_system = $osName
        }
    })

$module.ExitJson()
