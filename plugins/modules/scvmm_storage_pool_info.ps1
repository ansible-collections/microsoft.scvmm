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

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "total_capacity_gb"; Property = "TotalManagedSpace"; Type = "bytes_to_gb" }
    @{ Param = "free_capacity_gb"; Property = "RemainingManagedSpace"; Type = "bytes_to_gb" }
    @{ Param = "is_managed"; Property = "IsManaged"; Type = "bool" }
    @{ Param = "enabled"; Property = "Enabled"; Type = "bool" }
    @{ Param = "health_status"; Property = "HealthStatus"; Type = "enum" }
)

$pools = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCStoragePool' -Name $module.Params.name `
    -ObjectType 'storage pool'

if ($module.Params.name) {
    $pools = if ($pools) { @($pools) } else { @() }
}

$module.Result.storage_pools = @($pools | ForEach-Object {
        $result = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
        $result.classification = if ($_.Classification) { $_.Classification.Name } else { $null }
        $result
    })

$module.ExitJson()
