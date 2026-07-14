#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        cloud = @{ type = 'str'; required = $true }
        vmm_server = @{ type = 'str' }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

$cloudObj = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCCloud' -Name $module.Params.cloud `
    -ObjectType 'cloud' -FailIfNotFound $true

try {
    $capacity = Get-SCCloudCapacity -Cloud $cloudObj -ErrorAction Stop
}
catch {
    $module.FailJson("Failed to get cloud capacity for '$($module.Params.cloud)': $($_.Exception.Message)", $_)
}

$propertyMap = @(
    @{ Param = "cpu_count"; Property = "CPUCount"; Type = "int" }
    @{ Param = "memory_gb"; Property = "MemoryMB"; Type = "mb_to_gb" }
    @{ Param = "storage_gb"; Property = "StorageGB"; Type = "int" }
    @{ Param = "vm_count"; Property = "VMCount"; Type = "int" }
    @{ Param = "used_cpu_count"; Property = "UsedCPUCount"; Type = "int" }
    @{ Param = "used_memory_gb"; Property = "UsedMemoryMB"; Type = "mb_to_gb" }
    @{ Param = "used_storage_gb"; Property = "UsedStorageGB"; Type = "int" }
    @{ Param = "used_vm_count"; Property = "UsedVMCount"; Type = "int" }
)

$module.Result.cloud_capacity = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $capacity
$module.Result.cloud_capacity['cloud'] = $cloudObj.Name

$module.ExitJson()
