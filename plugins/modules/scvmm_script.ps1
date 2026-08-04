#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        description = @{ type = 'str' }
        family_name = @{ type = 'str' }
        release = @{ type = 'str' }
        enabled = @{ type = 'bool' }
        owner = @{ type = 'str' }
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
    @{ Param = "share_path"; Property = "SharePath"; Type = "string" }
    @{ Param = "library_server"; Property = "LibraryServer"; Type = "nested_name" }
    @{ Param = "family_name"; Property = "FamilyName"; Type = "string" }
    @{ Param = "release"; Property = "Release"; Type = "string" }
    @{ Param = "owner"; Property = "Owner"; Type = "string" }
    @{ Param = "enabled"; Property = "Enabled"; Type = "bool" }
    @{ Param = "is_orphaned"; Property = "IsOrphaned"; Type = "bool" }
)

$updateMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "family_name"; Property = "FamilyName"; Type = "string" }
    @{ Param = "release"; Property = "Release"; Type = "string" }
    @{ Param = "enabled"; Property = "Enabled"; Type = "bool" }
    @{ Param = "owner"; Property = "Owner"; Type = "string" }
)

$scriptName = $module.Params.name
$scriptObj = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCScript' -Name $scriptName -ObjectType 'script' `
    -FilterScript { $_.Name -eq $scriptName }

if ($module.Params.state -eq 'present') {
    if (-not $scriptObj) {
        $module.FailJson("Script '$($module.Params.name)' not found in the VMM library. Scripts are discovered automatically when placed on a library share.")
    }

    $setParams = @{
        Script = $scriptObj
        ErrorAction = 'Stop'
    }

    $changedParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap -AnsibleParams $module.Params -CurrentObject $scriptObj
    foreach ($key in $changedParams.Keys) {
        $setParams[$key] = $changedParams[$key]
    }

    if ($changedParams.Count -gt 0) {
        $module.Result.changed = $true
        $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $scriptObj
        if (-not $module.CheckMode) {
            try {
                $scriptObj = Set-SCScript @setParams
            }
            catch {
                $module.FailJson("Failed to update script '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
            $module.Diff.after = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $scriptObj
        }
        else {
            $module.Diff.after = Get-SCVMMCheckModeDiff -Before $module.Diff.before -UpdateMap $updateMap `
                -AnsibleParams $module.Params -CurrentObject $scriptObj
        }
    }

    $module.Result.script = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $scriptObj
}
else {
    if ($scriptObj) {
        $module.Result.changed = $true
        $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $scriptObj
        $module.Diff.after = @{}
        if (-not $module.CheckMode) {
            try {
                Remove-SCScript -Script $scriptObj -Force -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove script '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
