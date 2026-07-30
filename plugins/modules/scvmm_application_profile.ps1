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
        compatibility_type = @{ type = 'str'; choices = @('General', 'SQLApplicationHost', 'WebApplicationHost') }
        vmm_server = @{ type = 'str' }
        state = @{ type = 'str'; default = 'present'; choices = @('present', 'absent') }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name
$state = $module.Params.state

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "owner"; Property = "Owner"; Type = "string" }
    @{ Param = "tag"; Property = "Tag"; Type = "string" }
    @{ Param = "compatibility_type"; Property = "CompatibilityType"; Type = "enum" }
    @{ Param = "creation_time"; Property = "AddedTime"; Type = "datetime_iso" }
)

$updateMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "owner"; Property = "Owner"; Type = "string" }
    @{ Param = "tag"; Property = "Tag"; Type = "string" }
    @{ Param = "compatibility_type"; Property = "CompatibilityType"; Type = "enum" }
)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

if ($state -eq 'present') {
    $existing = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCApplicationProfile' -Name $name -ObjectType 'application profile'

    if ($existing) {
        $updateParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap `
            -AnsibleParams $module.Params -CurrentObject $existing
        $needsUpdate = $updateParams.Count -gt 0

        if ($needsUpdate) {
            $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $existing
            if (-not $module.CheckMode) {
                try {
                    $existing = Set-SCApplicationProfile -ApplicationProfile $existing @updateParams -ErrorAction Stop
                }
                catch {
                    $module.FailJson("Failed to update application profile '$name': $($_.Exception.Message)", $_)
                }
            }
            $module.Result.changed = $true
        }

        $module.Result.application_profile = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $existing

        if ($needsUpdate) {
            if ($module.CheckMode) {
                $module.Diff.after = Get-SCVMMCheckModeDiff -Before $module.Diff.before `
                    -UpdateMap $updateMap -AnsibleParams $module.Params -CurrentObject $existing
            }
            else {
                $module.Diff.after = $module.Result.application_profile
            }
        }
    }
    else {
        $createParams = @{ Name = $name }
        $mapParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap -AnsibleParams $module.Params
        foreach ($key in $mapParams.Keys) { $createParams[$key] = $mapParams[$key] }

        $module.Diff.before = @{}
        if (-not $module.CheckMode) {
            try {
                $newProfile = New-SCApplicationProfile @createParams -VMMServer $vmmConnection -ErrorAction Stop
            }
            catch {
                $module.FailJson("Failed to create application profile '$name': $($_.Exception.Message)", $_)
            }
            $module.Result.application_profile = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $newProfile
            $module.Diff.after = $module.Result.application_profile
        }
        else {
            $module.Result.application_profile = @{
                id = $null
                name = $name
                description = $module.Params.description
                owner = $module.Params.owner
                tag = $module.Params.tag
                compatibility_type = $module.Params.compatibility_type
            }
            $module.Diff.after = $module.Result.application_profile
        }
        $module.Result.changed = $true
    }
}
elseif ($state -eq 'absent') {
    $existing = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCApplicationProfile' -Name $name -ObjectType 'application profile'

    if ($existing) {
        $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $existing
        $module.Diff.after = @{}
        if (-not $module.CheckMode) {
            try {
                Remove-SCApplicationProfile -ApplicationProfile $existing -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove application profile '$name': $($_.Exception.Message)", $_)
            }
        }
        $module.Result.changed = $true
    }
}

$module.ExitJson()
