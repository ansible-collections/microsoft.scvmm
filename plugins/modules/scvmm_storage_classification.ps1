#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        description = @{ type = 'str' }
        state = @{
            type = 'str'
            default = 'present'
            choices = @('present', 'absent')
        }
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
    @{ Param = "enabled"; Property = "Enabled"; Type = "bool" }
    @{ Param = "storage_pools"; Property = "StoragePool"; Type = "name_list" }
)

$updateMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string" }
)

$classification = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCStorageClassification' -Name $module.Params.name `
    -ObjectType 'storage classification'

if ($module.Params.state -eq 'present') {
    if (-not $classification) {
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            $newParams = @{
                Name = $module.Params.name
                VMMServer = $vmmConnection
                ErrorAction = 'Stop'
            }
            if ($null -ne $module.Params.description) {
                $newParams['Description'] = $module.Params.description
            }
            try {
                $classification = New-SCStorageClassification @newParams
            }
            catch {
                $module.FailJson("Failed to create storage classification '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
    }
    else {
        if (Test-SCVMMPropertiesChanged -PropertyMap $updateMap -CurrentObject $classification -AnsibleParams $module.Params) {
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                $setParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap -AnsibleParams $module.Params
                $setParams['StorageClassification'] = $classification
                $setParams['ErrorAction'] = 'Stop'
                try {
                    $classification = Set-SCStorageClassification @setParams
                }
                catch {
                    $module.FailJson("Failed to update storage classification '$($module.Params.name)': $($_.Exception.Message)", $_)
                }
            }
        }
    }

    if ($classification) {
        $module.Result.storage_classification = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $classification
    }
    elseif ($module.CheckMode) {
        $module.Result.storage_classification = @{
            name = $module.Params.name
            description = $module.Params.description
        }
    }
}
else {
    if ($classification) {
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                Remove-SCStorageClassification -StorageClassification $classification -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove storage classification '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
