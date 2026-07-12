#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        storage_classification = @{ type = 'str' }
        description = @{ type = 'str' }
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

$updateMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string" }
)

$pool = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCStoragePool' -Name $module.Params.name `
    -ObjectType 'storage pool' -FailIfNotFound $true

$needsUpdate = Test-SCVMMPropertiesChanged -PropertyMap $updateMap -CurrentObject $pool -AnsibleParams $module.Params

# Classification requires object lookup — handle separately
if ($module.Params.storage_classification) {
    $currentClassification = if ($pool.Classification) { $pool.Classification.Name } else { $null }
    if ($currentClassification -ne $module.Params.storage_classification) {
        $needsUpdate = $true
    }
}

if ($needsUpdate) {
    $module.Result.changed = $true
    if (-not $module.CheckMode) {
        $setParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap -AnsibleParams $module.Params
        $setParams['StoragePool'] = $pool
        $setParams['ErrorAction'] = 'Stop'

        if ($module.Params.storage_classification) {
            $currentClassification = if ($pool.Classification) { $pool.Classification.Name } else { $null }
            if ($currentClassification -ne $module.Params.storage_classification) {
                $classificationObj = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
                    -CmdletName 'Get-SCStorageClassification' -Name $module.Params.storage_classification `
                    -ObjectType 'storage classification' -FailIfNotFound $true
                $setParams['StorageClassification'] = $classificationObj
            }
        }

        try {
            $pool = Set-SCStoragePool @setParams
        }
        catch {
            $module.FailJson("Failed to update storage pool '$($module.Params.name)': $($_.Exception.Message)", $_)
        }
    }
}

$result = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $pool
$result.classification = if ($pool.Classification) { $pool.Classification.Name } else { $null }
$module.Result.storage_pool = $result

$module.ExitJson()
