#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        state = @{ type = 'str'; default = 'present'; choices = @('present', 'absent') }
        host_group = @{ type = 'str' }
        description = @{ type = 'str' }
        maintenance_mode = @{ type = 'bool' }
        available_for_placement = @{ type = 'bool' }
        credential_username = @{ type = 'str' }
        credential_password = @{ type = 'str'; no_log = $true }
        vmm_server = @{ type = 'str' }
    }
    required_together = @(, @('credential_username', 'credential_password'))
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

$name = $module.Params.name

# Get-SCVMHost uses -ComputerName (not -Name), so direct cmdlet call is appropriate
try {
    $existingHost = Get-SCVMHost -VMMServer $vmmConnection -ComputerName $name -ErrorAction Stop
}
catch {
    if ($module.Params.state -eq 'absent') {
        $existingHost = $null
    }
    else {
        $module.FailJson("Failed to query host '$name': $($_.Exception.Message)", $_)
    }
}

$resultMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "name"; Property = "FQDN"; Type = "string" }
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "host_group"; Property = "HostGroup"; Type = "nested_name" }
    @{ Param = "maintenance_mode"; Property = "MaintenanceHost"; Type = "bool" }
    @{ Param = "available_for_placement"; Property = "AvailableForPlacement"; Type = "bool" }
    @{ Param = "overall_state"; Property = "OverallState"; Type = "enum" }
)

$updateMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "maintenance_mode"; Property = "MaintenanceHost"; Type = "bool" }
    @{ Param = "available_for_placement"; Property = "AvailableForPlacement"; Type = "bool" }
)

if ($module.Params.state -eq 'present') {
    if ($null -eq $existingHost) {
        if ([string]::IsNullOrEmpty($module.Params.host_group)) {
            $module.FailJson("host_group is required when adding a new host")
        }
        if ([string]::IsNullOrEmpty($module.Params.credential_username) -or
            [string]::IsNullOrEmpty($module.Params.credential_password)) {
            $module.FailJson(
                "credential_username and credential_password are required when adding a new host"
            )
        }

        $module.Result.changed = $true
        $module.Diff.before = @{}
        if (-not $module.CheckMode) {
            try {
                $secPassword = ConvertTo-SecureString $module.Params.credential_password `
                    -AsPlainText -Force
                $credential = New-Object System.Management.Automation.PSCredential(
                    $module.Params.credential_username, $secPassword
                )

                $hostGroup = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
                    -CmdletName 'Get-SCVMHostGroup' `
                    -Name $module.Params.host_group `
                    -ObjectType 'host group' `
                    -FailIfNotFound $true

                $addParams = @{
                    ComputerName = $name
                    VMHostGroup = $hostGroup
                    Credential = $credential
                    VMMServer = $vmmConnection
                    ErrorAction = 'Stop'
                }

                if ($null -ne $module.Params.description) {
                    $addParams['Description'] = $module.Params.description
                }
                if ($null -ne $module.Params.maintenance_mode) {
                    $addParams['MaintenanceHost'] = $module.Params.maintenance_mode
                }
                if ($null -ne $module.Params.available_for_placement) {
                    $addParams['AvailableForPlacement'] = $module.Params.available_for_placement
                }

                $existingHost = Add-SCVMHost @addParams
            }
            catch {
                $module.FailJson("Failed to add host: $($_.Exception.Message)", $_)
            }
            $module.Result.host = Get-SCVMMResultFromMap -PropertyMap $resultMap `
                -CurrentObject $existingHost
            $module.Diff.after = $module.Result.host
        }
        else {
            $module.Result.host = @{
                name = $name
                description = $module.Params.description
                host_group = $module.Params.host_group
                maintenance_mode = $module.Params.maintenance_mode
                available_for_placement = $module.Params.available_for_placement
            }
            $module.Diff.after = $module.Result.host
        }
    }
    else {
        $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $resultMap `
            -CurrentObject $existingHost

        $needsUpdate = Test-SCVMMPropertiesChanged -PropertyMap $updateMap `
            -CurrentObject $existingHost -AnsibleParams $module.Params

        if ($needsUpdate) {
            $setParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap `
                -AnsibleParams $module.Params -CurrentObject $existingHost
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                try {
                    $existingHost = Set-SCVMHost -VMHost $existingHost `
                        @setParams -ErrorAction Stop
                }
                catch {
                    $module.FailJson("Failed to update host: $($_.Exception.Message)", $_)
                }
            }
        }

        $module.Result.host = Get-SCVMMResultFromMap -PropertyMap $resultMap `
            -CurrentObject $existingHost
        if ($needsUpdate -and $module.CheckMode) {
            $module.Diff.after = Get-SCVMMCheckModeDiff -Before $module.Diff.before `
                -UpdateMap $updateMap -AnsibleParams $module.Params `
                -CurrentObject $existingHost
        }
        else {
            $module.Diff.after = $module.Result.host
        }
    }
}
else {
    if ($null -ne $existingHost) {
        $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $resultMap `
            -CurrentObject $existingHost
        $module.Diff.after = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                $removeParams = @{
                    VMHost = $existingHost
                    ErrorAction = 'Stop'
                    Confirm = $false
                }
                if ($null -ne $module.Params.credential_username -and
                    $null -ne $module.Params.credential_password) {
                    $secPassword = ConvertTo-SecureString $module.Params.credential_password `
                        -AsPlainText -Force
                    $credential = New-Object System.Management.Automation.PSCredential(
                        $module.Params.credential_username, $secPassword
                    )
                    $removeParams['Credential'] = $credential
                }
                Remove-SCVMHost @removeParams
            }
            catch {
                $module.FailJson("Failed to remove host: $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
