#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        host_group = @{ type = 'str' }
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
    @{ Param = "host_groups"; Property = "HostGroup"; Type = "name_list" }
)

$updateMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string" }
)

$cloud = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCCloud' -Name $module.Params.name -ObjectType 'cloud'

if ($module.Params.state -eq 'present') {
    if (-not $cloud) {
        if (-not $module.Params.host_group) {
            $module.FailJson("'host_group' is required when creating a new cloud")
        }
        $hostGroupObj = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
            -CmdletName 'Get-SCVMHostGroup' -Name $module.Params.host_group `
            -ObjectType 'host group' -FailIfNotFound $true

        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            $newParams = @{
                Name = $module.Params.name
                VMHostGroup = @($hostGroupObj)
                ErrorAction = 'Stop'
            }
            if ($null -ne $module.Params.description) {
                $newParams['Description'] = $module.Params.description
            }
            try {
                $cloud = New-SCCloud @newParams
            }
            catch {
                $module.FailJson("Failed to create cloud '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
    }
    else {
        $updateParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap `
            -AnsibleParams $module.Params -CurrentObject $cloud
        $needsUpdate = $updateParams.Count -gt 0

        if ($needsUpdate) {
            $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $cloud
            if (-not $module.CheckMode) {
                try {
                    $cloud = Set-SCCloud -Cloud $cloud @updateParams -ErrorAction Stop
                }
                catch {
                    $module.FailJson("Failed to update cloud '$($module.Params.name)': $($_.Exception.Message)", $_)
                }
            }
            $module.Result.changed = $true
        }
    }

    if ($cloud) {
        $module.Result.cloud = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $cloud
        if ($module.Result.changed -and $module.Diff.before) {
            if ($module.CheckMode) {
                $module.Diff.after = Get-SCVMMCheckModeDiff -Before $module.Diff.before `
                    -UpdateMap $updateMap -AnsibleParams $module.Params -CurrentObject $cloud
            }
            else {
                $module.Diff.after = $module.Result.cloud
            }
        }
    }
    elseif ($module.CheckMode) {
        $module.Result.cloud = @{
            name = $module.Params.name
            description = $module.Params.description
            host_groups = @($module.Params.host_group)
        }
    }
}
else {
    if ($cloud) {
        $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $cloud
        $module.Diff.after = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                Remove-SCCloud -Cloud $cloud -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove cloud '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
