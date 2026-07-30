#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        description = @{ type = 'str' }
        release = @{ type = 'str' }
        service_priority = @{
            type = 'str'
            choices = @('Normal', 'Low', 'High')
        }
        use_as_default_release = @{ type = 'bool' }
        owner = @{ type = 'str' }
        published = @{ type = 'bool' }
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
    @{ Param = "release"; Property = "Release"; Type = "string" }
    @{ Param = "service_priority"; Property = "ServicePriority"; Type = "enum" }
    @{ Param = "use_as_default_release"; Property = "UseAsDefaultRelease"; Type = "bool" }
    @{ Param = "is_published"; Property = "IsPublished"; Type = "bool" }
    @{ Param = "owner"; Property = "Owner"; Type = "string" }
    @{ Param = "enabled"; Property = "Enabled"; Type = "bool" }
    @{ Param = "creation_time"; Property = "AddedTime"; Type = "datetime_iso" }
    @{ Param = "modified_time"; Property = "ModifiedTime"; Type = "datetime_iso" }
)

$updateMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string"; CmdletParam = "Description" }
    @{ Param = "release"; Property = "Release"; Type = "string"; CmdletParam = "Release" }
    @{ Param = "service_priority"; Property = "ServicePriority"; Type = "enum"; CmdletParam = "ServicePriority" }
    @{ Param = "use_as_default_release"; Property = "UseAsDefaultRelease"; Type = "bool"; CmdletParam = "UseAsDefaultRelease" }
    @{ Param = "owner"; Property = "Owner"; Type = "string"; CmdletParam = "Owner" }
    @{ Param = "published"; Property = "IsPublished"; Type = "bool"; CmdletParam = "Published" }
)

$name = $module.Params.name

$allMatches = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCServiceTemplate' -Name $name -ObjectType 'service template' `
    -AllowMultiple $true

if ($null -eq $allMatches) {
    $existing = $null
}
else {
    if ($module.Params.release) {
        $existing = @($allMatches) | Where-Object { $_.Release -eq $module.Params.release } | Select-Object -First 1
    }
    elseif (@($allMatches).Count -eq 1) {
        $existing = @($allMatches)[0]
    }
    else {
        $releaseList = (@($allMatches) | ForEach-Object { $_.Release }) -join "', '"
        $module.FailJson("Multiple service templates found with name '$name' (releases: '$releaseList'). Specify 'release' to identify the target template.")
    }
}

if ($module.Params.state -eq 'present') {
    if (-not $existing) {
        $module.Diff.before = @{}
        if (-not $module.Params.release) {
            $module.FailJson("'release' is required when creating a new service template")
        }
        if ($null -ne $module.Params.published) {
            $module.Warn("'published' can only be set when updating an existing service template and is ignored during creation.")
        }
        $module.Result.changed = $true

        $createParams = @{
            Name = $name
            Release = $module.Params.release
            VMMServer = $vmmConnection
            ErrorAction = 'Stop'
        }
        if ($null -ne $module.Params.description) { $createParams['Description'] = $module.Params.description }
        if ($null -ne $module.Params.service_priority) { $createParams['ServicePriority'] = $module.Params.service_priority }
        if ($null -ne $module.Params.use_as_default_release) { $createParams['UseAsDefaultRelease'] = $module.Params.use_as_default_release }
        if ($null -ne $module.Params.owner) { $createParams['Owner'] = $module.Params.owner }

        if (-not $module.CheckMode) {
            try {
                $existing = New-SCServiceTemplate @createParams
                $module.Result.service_template = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $existing
                $module.Diff.after = $module.Result.service_template
            }
            catch {
                $module.FailJson("Failed to create service template '$name': $($_.Exception.Message)", $_)
            }
        }
        else {
            $module.Result.service_template = @{
                id = $null
                name = $name
                description = $module.Params.description
                release = $module.Params.release
                service_priority = $module.Params.service_priority
                use_as_default_release = $module.Params.use_as_default_release
                is_published = $false
                owner = $module.Params.owner
                enabled = $null
                creation_time = $null
                modified_time = $null
            }
            $module.Diff.after = $module.Result.service_template
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
                $updateParams['ServiceTemplate'] = $existing
                $updateParams['ErrorAction'] = 'Stop'
                try {
                    $existing = Set-SCServiceTemplate @updateParams
                }
                catch {
                    $module.FailJson("Failed to update service template '$name': $($_.Exception.Message)", $_)
                }
                $module.Result.service_template = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $existing
                $module.Diff.after = $module.Result.service_template
            }
            else {
                $module.Result.service_template = $currentResult
                $module.Diff.after = Get-SCVMMCheckModeDiff -Before $currentResult `
                    -UpdateMap $updateMap -AnsibleParams $module.Params -CurrentObject $existing
            }
        }
        else {
            $module.Result.service_template = $currentResult
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
                Remove-SCServiceTemplate -ServiceTemplate $existing -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove service template '$name': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
