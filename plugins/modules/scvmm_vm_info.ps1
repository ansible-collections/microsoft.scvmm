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

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{ Param = "status"; Property = "Status"; Type = "enum" }
    @{ Param = "host"; Property = "VMHost"; Type = "nested_name" }
    @{ Param = "cpu_count"; Property = "CPUCount"; Type = "int" }
    @{ Param = "memory_mb"; Property = "Memory"; Type = "int" }
    @{ Param = "generation"; Property = "Generation"; Type = "int" }
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "cloud"; Property = "Cloud"; Type = "nested_name" }
    @{ Param = "creation_time"; Property = "CreationTime"; Type = "datetime_iso" }
    @{ Param = "operating_system"; Property = "OperatingSystem"; Type = "nested_name" }
)

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
        Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
    })

$module.ExitJson()
