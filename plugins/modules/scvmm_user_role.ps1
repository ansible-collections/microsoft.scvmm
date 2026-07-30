#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        description = @{ type = 'str' }
        user_role_profile = @{
            type = 'str'
            choices = @('DelegatedAdmin', 'ReadOnlyAdmin', 'SelfServiceUser', 'TenantAdmin')
        }
        vmm_server = @{ type = 'str' }
        state = @{ type = 'str'; default = 'present'; choices = @('present', 'absent') }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

$name = $module.Params.name
$state = $module.Params.state

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "user_role_profile"; Property = "Profile"; Type = "enum" }
)

$updateMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string" }
)

$existing = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCUserRole' -Name $name -ObjectType 'user role'

if ($state -eq 'present') {
    if (-not $existing) {
        if (-not $module.Params.user_role_profile) {
            $module.FailJson("Parameter 'user_role_profile' is required when creating a new user role.")
        }

        $module.Diff.before = @{}
        $module.Result.changed = $true

        if (-not $module.CheckMode) {
            $createParams = @{
                Name = $name
                UserRoleProfile = $module.Params.user_role_profile
                VMMServer = $vmmConnection
                ErrorAction = 'Stop'
            }
            $mapParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap -AnsibleParams $module.Params
            foreach ($key in $mapParams.Keys) { $createParams[$key] = $mapParams[$key] }

            try {
                $existing = New-SCUserRole @createParams
                $module.Result.user_role = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $existing
                $module.Diff.after = $module.Result.user_role
            }
            catch {
                $module.FailJson("Failed to create user role '$name': $($_.Exception.Message)", $_)
            }
        }
        else {
            $module.Result.user_role = @{
                id = $null
                name = $name
                description = $module.Params.description
                user_role_profile = $module.Params.user_role_profile
            }
            $module.Diff.after = $module.Result.user_role
        }
    }
    else {
        if ($null -ne $module.Params.user_role_profile -and
            $existing.Profile.ToString() -ne $module.Params.user_role_profile) {
            $cur = $existing.Profile
            $req = $module.Params.user_role_profile
            $module.Warn("Cannot change 'user_role_profile' after creation (current: '$cur', requested: '$req'). Delete and recreate.")
        }

        $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $existing

        $updateParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap `
            -AnsibleParams $module.Params -CurrentObject $existing
        $needsUpdate = $updateParams.Count -gt 0

        if ($needsUpdate) {
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                $updateParams['UserRole'] = $existing
                $updateParams['ErrorAction'] = 'Stop'
                try {
                    $existing = Set-SCUserRole @updateParams
                }
                catch {
                    $module.FailJson("Failed to update user role '$name': $($_.Exception.Message)", $_)
                }
            }
        }

        $module.Result.user_role = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $existing
        if ($needsUpdate -and $module.CheckMode) {
            $module.Diff.after = Get-SCVMMCheckModeDiff -Before $module.Diff.before `
                -UpdateMap $updateMap -AnsibleParams $module.Params -CurrentObject $existing
        }
        else {
            $module.Diff.after = $module.Result.user_role
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
                Remove-SCUserRole -UserRole $existing -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove user role '$name': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
