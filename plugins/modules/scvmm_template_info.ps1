#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str' }
        vmm_server = @{ type = 'str' }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

try {
    if ($module.Params.name) {
        $templates = @(Get-SCVMTemplate -VMMServer $vmmConnection -Name $module.Params.name -ErrorAction Stop)
    }
    else {
        $templates = @(Get-SCVMTemplate -VMMServer $vmmConnection -ErrorAction Stop)
    }
}
catch {
    $module.FailJson("Failed to query templates: $($_.Exception.Message)", $_)
}

$module.Result.templates = @($templates | ForEach-Object {
        $osName = $null
        if ($_.OperatingSystem) {
            $osName = $_.OperatingSystem.Name
        }
        $creationTime = $null
        if ($_.AddedTime) {
            $creationTime = $_.AddedTime.ToString('o')
        }
        @{
            id = $_.ID.ToString()
            name = $_.Name
            description = $_.Description
            owner = $_.Owner
            cpu_count = $_.CPUCount
            memory_mb = $_.Memory
            generation = $_.Generation
            dynamic_memory = $_.DynamicMemoryEnabled
            operating_system = $osName
            status = $_.Status.ToString()
            creation_time = $creationTime
            enabled = $_.Enabled
        }
    })

$module.ExitJson()
