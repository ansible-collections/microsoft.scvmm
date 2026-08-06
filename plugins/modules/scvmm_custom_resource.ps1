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

$crName = $module.Params.name
$customResource = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCCustomResource' -Name $crName -ObjectType 'custom resource' `
    -FilterScript { $_.Name -eq $crName }

if ($module.Params.state -eq 'present') {
    if (-not $customResource) {
        $module.FailJson(
            "Custom resource '$($module.Params.name)' not found in the VMM library." +
            " Custom resources are discovered automatically when placed on a library share as .cr folders."
        )
    }

    $needsUpdate = $false
    $setParams = @{
        CustomResource = $customResource
        ErrorAction = 'Stop'
    }

    if (Test-SCVMMPropertiesChanged -PropertyMap $updateMap -CurrentObject $customResource -AnsibleParams $module.Params) {
        $changedParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap -AnsibleParams $module.Params -CurrentObject $customResource
        foreach ($key in $changedParams.Keys) {
            $setParams[$key] = $changedParams[$key]
        }
        $needsUpdate = $true
    }

    if ($needsUpdate) {
        $module.Result.changed = $true
        $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $customResource
        if (-not $module.CheckMode) {
            try {
                $customResource = Set-SCCustomResource @setParams
            }
            catch {
                $module.FailJson("Failed to update custom resource '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
            $module.Diff.after = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $customResource
        }
        else {
            $module.Diff.after = Get-SCVMMCheckModeDiff -Before $module.Diff.before -UpdateMap $updateMap `
                -AnsibleParams $module.Params -CurrentObject $customResource
        }
    }

    $module.Result.custom_resource = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $customResource
}
else {
    if ($customResource) {
        $module.Result.changed = $true
        $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $customResource
        $module.Diff.after = @{}
        if (-not $module.CheckMode) {
            try {
                Remove-SCCustomResource -CustomResource $customResource -Force -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove custom resource '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
