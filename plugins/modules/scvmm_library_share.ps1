#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        share_path = @{ type = 'str' }
        description = @{ type = 'str' }
        add_default_resources = @{ type = 'bool' }
        use_alternate_data_stream = @{ type = 'bool' }
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
    @{ Param = "share_path"; Property = "Path"; Type = "string" }
    @{ Param = "library_server"; Property = "LibraryServer"; Type = "nested_name" }
    @{ Param = "use_alternate_data_stream"; Property = "UseAlternateDataStream"; Type = "bool" }
)

$updateMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "use_alternate_data_stream"; Property = "UseAlternateDataStream"; Type = "bool" }
)

$shareName = $module.Params.name
$share = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCLibraryShare' -Name $shareName `
    -ObjectType 'library share' `
    -FilterScript { $_.Name -eq $shareName }

if ($module.Params.state -eq 'present') {
    if (-not $share) {
        if (-not $module.Params.share_path) {
            $module.FailJson("'share_path' is required when adding a new library share")
        }

        $expectedName = $module.Params.share_path.TrimEnd('\').Split('\')[-1]
        if ($shareName -ne $expectedName) {
            $module.FailJson(
                "The 'name' parameter ('$shareName') must match the share name" +
                " derived from 'share_path' ('$expectedName')." +
                " SCVMM assigns the share name from the last component of the UNC path."
            )
        }

        $module.Result.changed = $true
        $module.Diff.before = @{}
        if (-not $module.CheckMode) {
            $addParams = @{
                SharePath = $module.Params.share_path
                VMMServer = $vmmConnection
                ErrorAction = 'Stop'
            }
            if ($null -ne $module.Params.description) {
                $addParams['Description'] = $module.Params.description
            }
            if ($module.Params.add_default_resources) {
                $addParams['AddDefaultResources'] = $true
            }
            if ($null -ne $module.Params.use_alternate_data_stream) {
                $addParams['UseAlternateDataStream'] = $module.Params.use_alternate_data_stream
            }
            try {
                $share = Add-SCLibraryShare @addParams
                $module.Diff.after = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $share
            }
            catch {
                $module.FailJson("Failed to add library share '$shareName': $($_.Exception.Message)", $_)
            }
        }
    }
    else {
        $needsUpdate = $false
        $setParams = @{
            LibraryShare = $share
            ErrorAction = 'Stop'
        }

        if (Test-SCVMMPropertiesChanged -PropertyMap $updateMap -CurrentObject $share -AnsibleParams $module.Params) {
            $changedParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap -AnsibleParams $module.Params -CurrentObject $share
            foreach ($key in $changedParams.Keys) {
                $setParams[$key] = $changedParams[$key]
            }
            $needsUpdate = $true
        }

        if ($needsUpdate) {
            $module.Result.changed = $true
            $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $share
            if (-not $module.CheckMode) {
                try {
                    $share = Set-SCLibraryShare @setParams
                }
                catch {
                    $module.FailJson("Failed to update library share '$shareName': $($_.Exception.Message)", $_)
                }
                $module.Diff.after = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $share
            }
            else {
                $module.Diff.after = Get-SCVMMCheckModeDiff -Before $module.Diff.before -UpdateMap $updateMap `
                    -AnsibleParams $module.Params -CurrentObject $share
            }
        }
    }

    if ($share) {
        $module.Result.library_share = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $share
    }
    elseif ($module.CheckMode) {
        $module.Result.library_share = @{
            id = $null
            name = $shareName
            description = $module.Params.description
            share_path = $module.Params.share_path
            library_server = $null
            use_alternate_data_stream = if ($null -ne $module.Params.use_alternate_data_stream) { $module.Params.use_alternate_data_stream } else { $false }
        }
        $module.Diff.after = $module.Result.library_share
    }
}
else {
    if ($share) {
        $module.Result.changed = $true
        $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $share
        $module.Diff.after = @{}
        if (-not $module.CheckMode) {
            try {
                Remove-SCLibraryShare -LibraryShare $share -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove library share '$shareName': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
