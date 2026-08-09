#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        new_name = @{ type = 'str' }
        description = @{ type = 'str' }
        member_types = @{
            type = 'list'
            elements = 'str'
            choices = @(
                'VM', 'Template', 'VMHost', 'HostCluster', 'VMHostGroup',
                'ServiceTemplate', 'ServiceInstance', 'ComputerTier', 'Cloud',
                'ProtectionUnit'
            )
        }
        state = @{
            type = 'str'
            default = 'present'
            choices = @('present', 'absent')
        }
        vmm_server = @{ type = 'str' }
    }
    required_if = @(, @('state', 'present', @('member_types'), $true))
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{ Param = "description"; Property = "Description"; Type = "string" }
)

$updateMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string" }
)

function Get-MemberTypesList {
    param($CustomProperty)
    $members = @()
    foreach ($member in $CustomProperty.Members) {
        $members += $member.ToString()
    }
    return @($members | Sort-Object)
}

function Get-CustomPropertyResult {
    param($CustomProperty, $PropertyMap)
    $result = Get-SCVMMResultFromMap -PropertyMap $PropertyMap -CurrentObject $CustomProperty
    $result['member_types'] = @(Get-MemberTypesList -CustomProperty $CustomProperty)
    return $result
}

$cpName = $module.Params.name
$customProperty = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCCustomProperty' -Name $cpName -ObjectType 'custom property'

if ($module.Params.state -eq 'present') {
    if (-not $customProperty) {
        $module.Diff.before = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            $newParams = @{
                Name = $module.Params.name
                AddMember = [string[]]@($module.Params.member_types)
                VMMServer = $vmmConnection
                ErrorAction = 'Stop'
            }
            if ($null -ne $module.Params.description) {
                $newParams['Description'] = $module.Params.description
            }
            try {
                $customProperty = New-SCCustomProperty @newParams
                $module.Result.custom_property = Get-CustomPropertyResult -CustomProperty $customProperty -PropertyMap $propertyMap
                $module.Diff.after = $module.Result.custom_property
            }
            catch {
                $module.FailJson("Failed to create custom property '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
        else {
            $module.Result.custom_property = @{
                id = $null
                name = $module.Params.name
                description = $module.Params.description
                member_types = @($module.Params.member_types | Sort-Object)
            }
            $module.Diff.after = $module.Result.custom_property
        }
    }
    else {
        $module.Diff.before = Get-CustomPropertyResult -CustomProperty $customProperty -PropertyMap $propertyMap

        $needsUpdate = $false
        $setParams = @{
            CustomProperty = $customProperty
            ErrorAction = 'Stop'
        }

        $descUpdateParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap `
            -AnsibleParams $module.Params -CurrentObject $customProperty
        if ($descUpdateParams.Count -gt 0) {
            foreach ($key in $descUpdateParams.Keys) {
                $setParams[$key] = $descUpdateParams[$key]
            }
            $needsUpdate = $true
        }

        if ($null -ne $module.Params.new_name -and $module.Params.new_name -ne $customProperty.Name) {
            $setParams['Name'] = $module.Params.new_name
            $needsUpdate = $true
        }

        if ($null -ne $module.Params.member_types) {
            $currentMembers = @(Get-MemberTypesList -CustomProperty $customProperty)
            $desiredMembers = @($module.Params.member_types | Sort-Object)
            $toAdd = @($desiredMembers | Where-Object { $_ -notin $currentMembers })
            $toRemove = @($currentMembers | Where-Object { $_ -notin $desiredMembers })
            if ($toAdd.Count -gt 0) {
                $setParams['AddMember'] = [string[]]$toAdd
                $needsUpdate = $true
            }
            if ($toRemove.Count -gt 0) {
                $setParams['RemoveMember'] = [string[]]$toRemove
                $needsUpdate = $true
            }
        }

        if ($needsUpdate) {
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                try {
                    $customProperty = Set-SCCustomProperty @setParams
                }
                catch {
                    $module.FailJson("Failed to update custom property '$($module.Params.name)': $($_.Exception.Message)", $_)
                }
            }
        }

        if ($module.CheckMode -and $needsUpdate) {
            $checkResult = Get-SCVMMCheckModeDiff -Before $module.Diff.before `
                -UpdateMap $updateMap -AnsibleParams $module.Params -CurrentObject $customProperty
            if ($null -ne $module.Params.new_name) {
                $checkResult['name'] = $module.Params.new_name
            }
            if ($null -ne $module.Params.member_types) {
                $checkResult['member_types'] = @($module.Params.member_types | Sort-Object)
            }
            $module.Result.custom_property = $checkResult
            $module.Diff.after = $checkResult
        }
        else {
            $module.Result.custom_property = Get-CustomPropertyResult -CustomProperty $customProperty -PropertyMap $propertyMap
            $module.Diff.after = $module.Result.custom_property
        }
    }
}
else {
    if ($customProperty) {
        $module.Diff.before = Get-CustomPropertyResult -CustomProperty $customProperty -PropertyMap $propertyMap
        $module.Diff.after = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                Remove-SCCustomProperty -CustomProperty $customProperty -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove custom property '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
