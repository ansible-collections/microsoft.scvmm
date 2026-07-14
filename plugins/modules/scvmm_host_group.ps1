#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        parent_host_group = @{ type = 'str'; default = 'All Hosts' }
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
    @{ Param = "path"; Property = "Path"; Type = "string" }
    @{ Param = "parent_host_group"; Property = "ParentHostGroup"; Type = "nested_name" }
)

$updateMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string" }
)

$parentGroup = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCVMHostGroup' -Name $module.Params.parent_host_group `
    -ObjectType 'host group' -FailIfNotFound $true

$hostGroup = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCVMHostGroup' -ObjectType 'host group' `
    -FilterScript { $_.Name -eq $module.Params.name -and $_.ParentHostGroup.ID -eq $parentGroup.ID }

if ($module.Params.state -eq 'present') {
    if (-not $hostGroup) {
        $module.Diff.before = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            $newParams = @{
                Name = $module.Params.name
                ParentHostGroup = $parentGroup
                ErrorAction = 'Stop'
            }
            if ($null -ne $module.Params.description) {
                $newParams['Description'] = $module.Params.description
            }
            try {
                $hostGroup = New-SCVMHostGroup @newParams
            }
            catch {
                $module.FailJson("Failed to create host group '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
    }
    else {
        $updateParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap `
            -AnsibleParams $module.Params -CurrentObject $hostGroup
        $needsUpdate = $updateParams.Count -gt 0

        if ($needsUpdate) {
            $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $hostGroup
            if (-not $module.CheckMode) {
                try {
                    $hostGroup = Set-SCVMHostGroup -VMHostGroup $hostGroup @updateParams -ErrorAction Stop
                }
                catch {
                    $module.FailJson("Failed to update host group '$($module.Params.name)': $($_.Exception.Message)", $_)
                }
            }
            $module.Result.changed = $true
        }
    }

    if ($hostGroup) {
        $module.Result.host_group = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $hostGroup
        if ($module.Result.changed -and $module.Diff.before) {
            if ($module.CheckMode) {
                $module.Diff.after = Get-SCVMMCheckModeDiff -Before $module.Diff.before `
                    -UpdateMap $updateMap -AnsibleParams $module.Params -CurrentObject $hostGroup
            }
            else {
                $module.Diff.after = $module.Result.host_group
            }
        }
    }
    elseif ($module.CheckMode) {
        $module.Result.host_group = @{
            name = $module.Params.name
            description = $module.Params.description
            parent_host_group = $module.Params.parent_host_group
        }
        $module.Diff.after = $module.Result.host_group
    }
}
else {
    if ($hostGroup) {
        $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $hostGroup
        $module.Diff.after = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                Remove-SCVMHostGroup -VMHostGroup $hostGroup -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove host group '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
