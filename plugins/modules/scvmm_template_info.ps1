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

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "owner"; Property = "Owner"; Type = "string" }
    @{ Param = "cpu_count"; Property = "CPUCount"; Type = "int" }
    @{ Param = "memory_mb"; Property = "Memory"; Type = "int" }
    @{ Param = "generation"; Property = "Generation"; Type = "int" }
    @{ Param = "dynamic_memory"; Property = "DynamicMemoryEnabled"; Type = "bool" }
    @{ Param = "operating_system"; Property = "OperatingSystem"; Type = "nested_name" }
    @{ Param = "status"; Property = "Status"; Type = "enum" }
    @{ Param = "creation_time"; Property = "AddedTime"; Type = "datetime_iso" }
    @{ Param = "enabled"; Property = "Enabled"; Type = "bool" }
)

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
        Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
    })

$module.ExitJson()
