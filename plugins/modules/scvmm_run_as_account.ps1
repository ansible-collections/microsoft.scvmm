#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        description = @{ type = 'str' }
        username = @{ type = 'str' }
        password = @{ type = 'str'; no_log = $true }
        update_password = @{ type = 'str'; default = 'always'; choices = @('always', 'on_create') }
        vmm_server = @{ type = 'str' }
        state = @{ type = 'str'; default = 'present'; choices = @('present', 'absent') }
    }
    required_together = @(, @('username', 'password'))
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
    @{ Param = "username"; Property = "UserName"; Type = "string" }
)

$updateMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string" }
)

$existing = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCRunAsAccount' -Name $name -ObjectType 'Run As account'

if ($state -eq 'present') {
    if (-not $existing) {
        if (-not $module.Params.username -or -not $module.Params.password) {
            $module.FailJson("Parameters 'username' and 'password' are required when creating a new Run As account.")
        }

        $module.Diff.before = @{}
        $module.Result.changed = $true

        if (-not $module.CheckMode) {
            $securePassword = ConvertTo-SecureString $module.Params.password -AsPlainText -Force
            $credential = New-Object System.Management.Automation.PSCredential($module.Params.username, $securePassword)

            $createParams = @{
                Name = $name
                Credential = $credential
                VMMServer = $vmmConnection
                ErrorAction = 'Stop'
            }
            $mapParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap -AnsibleParams $module.Params
            foreach ($key in $mapParams.Keys) { $createParams[$key] = $mapParams[$key] }

            try {
                $existing = New-SCRunAsAccount @createParams
                $module.Result.run_as_account = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $existing
                $module.Diff.after = $module.Result.run_as_account
            }
            catch {
                $module.FailJson("Failed to create Run As account '$name': $($_.Exception.Message)", $_)
            }
        }
        else {
            $module.Result.run_as_account = @{
                id = $null
                name = $name
                description = $module.Params.description
                username = $module.Params.username
            }
            $module.Diff.after = $module.Result.run_as_account
        }
    }
    else {
        $currentResult = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $existing
        $module.Diff.before = $currentResult

        $updateParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap `
            -AnsibleParams $module.Params -CurrentObject $existing

        $credentialChanged = $false
        if ($module.Params.username -and $module.Params.password -and $module.Params.update_password -eq 'always') {
            $credentialChanged = $true
        }

        if ($updateParams.Count -gt 0 -or $credentialChanged) {
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                if ($credentialChanged) {
                    $securePassword = ConvertTo-SecureString $module.Params.password -AsPlainText -Force
                    $credential = New-Object System.Management.Automation.PSCredential($module.Params.username, $securePassword)
                    $updateParams['Credential'] = $credential
                }
                $updateParams['RunAsAccount'] = $existing
                $updateParams['ErrorAction'] = 'Stop'
                try {
                    $existing = Set-SCRunAsAccount @updateParams
                }
                catch {
                    $module.FailJson("Failed to update Run As account '$name': $($_.Exception.Message)", $_)
                }
                $module.Result.run_as_account = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $existing
                $module.Diff.after = $module.Result.run_as_account
            }
            else {
                $module.Result.run_as_account = $currentResult
                $projected = Get-SCVMMCheckModeDiff -Before $currentResult `
                    -UpdateMap $updateMap -AnsibleParams $module.Params -CurrentObject $existing
                if ($module.Params.username) {
                    $projected['username'] = $module.Params.username
                }
                $module.Diff.after = $projected
            }
        }
        else {
            $module.Result.run_as_account = $currentResult
            $module.Diff.after = $currentResult
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
                Remove-SCRunAsAccount -RunAsAccount $existing -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove Run As account '$name': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
