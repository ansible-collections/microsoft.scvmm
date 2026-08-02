#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        description = @{ type = 'str' }
        owner = @{ type = 'str' }
        tag = @{ type = 'str' }
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
    @{ Param = "owner"; Property = "Owner"; Type = "string" }
    @{ Param = "tag"; Property = "Tag"; Type = "string" }
    @{ Param = "enabled"; Property = "Enabled"; Type = "bool" }
    @{ Param = "creation_time"; Property = "AddedTime"; Type = "datetime_iso" }
    @{ Param = "modified_time"; Property = "ModifiedTime"; Type = "datetime_iso" }
)

$updateMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string"; CmdletParam = "Description" }
    @{ Param = "owner"; Property = "Owner"; Type = "string"; CmdletParam = "Owner" }
    @{ Param = "tag"; Property = "Tag"; Type = "string"; CmdletParam = "Tag" }
)

$name = $module.Params.name

$existing = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCSQLProfile' -Name $name -ObjectType 'SQL profile'

if ($module.Params.state -eq 'present') {
    if (-not $existing) {
        $module.Diff.before = @{}
        $module.Result.changed = $true

        $createParams = @{
            Name = $name
            VMMServer = $vmmConnection
            ErrorAction = 'Stop'
        }
        $mapParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap -AnsibleParams $module.Params
        foreach ($key in $mapParams.Keys) { $createParams[$key] = $mapParams[$key] }

        if (-not $module.CheckMode) {
            try {
                $existing = New-SCSQLProfile @createParams
                $module.Result.sql_profile = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $existing
                $module.Diff.after = $module.Result.sql_profile
            }
            catch {
                $module.FailJson("Failed to create SQL profile '$name': $($_.Exception.Message)", $_)
            }
        }
        else {
            $module.Result.sql_profile = @{
                id = $null
                name = $name
                description = $module.Params.description
                owner = $module.Params.owner
                tag = $module.Params.tag
                enabled = $null
                creation_time = $null
                modified_time = $null
            }
            $module.Diff.after = $module.Result.sql_profile
        }
    }
    else {
        $currentResult = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $existing

        $updateParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap `
            -AnsibleParams $module.Params -CurrentObject $existing
        $needsUpdate = $updateParams.Count -gt 0

        if ($needsUpdate) {
            $module.Diff.before = $currentResult
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                $updateParams['SQLProfile'] = $existing
                $updateParams['ErrorAction'] = 'Stop'
                try {
                    $existing = Set-SCSQLProfile @updateParams
                }
                catch {
                    $module.FailJson("Failed to update SQL profile '$name': $($_.Exception.Message)", $_)
                }
                $module.Result.sql_profile = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $existing
                $module.Diff.after = $module.Result.sql_profile
            }
            else {
                $module.Result.sql_profile = $currentResult
                $module.Diff.after = Get-SCVMMCheckModeDiff -Before $currentResult `
                    -UpdateMap $updateMap -AnsibleParams $module.Params -CurrentObject $existing
            }
        }
        else {
            $module.Result.sql_profile = $currentResult
        }
    }
}
else {
    if ($existing) {
        $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $existing
        $module.Diff.after = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                Remove-SCSQLProfile -SQLProfile $existing -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove SQL profile '$name': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
