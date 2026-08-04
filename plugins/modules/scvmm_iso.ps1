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
)

$isoName = $module.Params.name
$iso = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCISO' -Name $isoName -ObjectType 'ISO' `
    -FilterScript { $_.Name -eq $isoName }

if ($module.Params.state -eq 'present') {
    if (-not $iso) {
        $module.FailJson("ISO '$($module.Params.name)' not found in the VMM library. ISOs are discovered automatically when placed on a library share.")
    }

    $needsUpdate = $false
    $setParams = @{
        ISO = $iso
        ErrorAction = 'Stop'
    }

    if (Test-SCVMMPropertiesChanged -PropertyMap $updateMap -CurrentObject $iso -AnsibleParams $module.Params) {
        $changedParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap -AnsibleParams $module.Params -CurrentObject $iso
        foreach ($key in $changedParams.Keys) {
            $setParams[$key] = $changedParams[$key]
        }
        $needsUpdate = $true
    }

    if ($needsUpdate) {
        $module.Result.changed = $true
        $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $iso
        if (-not $module.CheckMode) {
            try {
                $iso = Set-SCISO @setParams
            }
            catch {
                $module.FailJson("Failed to update ISO '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
            $module.Diff.after = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $iso
        }
        else {
            $module.Diff.after = Get-SCVMMCheckModeDiff -Before $module.Diff.before -UpdateMap $updateMap `
                -AnsibleParams $module.Params -CurrentObject $iso
        }
    }

    $module.Result.iso = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $iso
}
else {
    if ($iso) {
        $module.Result.changed = $true
        $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $iso
        $module.Diff.after = @{}
        if (-not $module.CheckMode) {
            try {
                Remove-SCISO -ISO $iso -Force -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove ISO '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
