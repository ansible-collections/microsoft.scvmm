#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        service_template = @{ type = 'str' }
        cloud = @{ type = 'str' }
        description = @{ type = 'str' }
        service_priority = @{
            type = 'str'
            choices = @('Normal', 'Low', 'High')
        }
        cost_center = @{ type = 'str' }
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
    @{ Param = "service_priority"; Property = "ServicePriority"; Type = "enum" }
    @{ Param = "cost_center"; Property = "CostCenter"; Type = "string" }
    @{ Param = "owner"; Property = "Owner"; Type = "string" }
    @{ Param = "service_template_release"; Property = "ServiceTemplateRelease"; Type = "string" }
    @{ Param = "deployment_state"; Property = "DeploymentState"; Type = "enum" }
    @{ Param = "enabled"; Property = "Enabled"; Type = "bool" }
    @{ Param = "creation_time"; Property = "AddedTime"; Type = "datetime_iso" }
    @{ Param = "modified_time"; Property = "ModifiedTime"; Type = "datetime_iso" }
)

$updateMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string"; CmdletParam = "Description" }
    @{ Param = "service_priority"; Property = "ServicePriority"; Type = "enum"; CmdletParam = "ServicePriority" }
    @{ Param = "cost_center"; Property = "CostCenter"; Type = "string"; CmdletParam = "CostCenter" }
    @{ Param = "owner"; Property = "Owner"; Type = "string"; CmdletParam = "Owner" }
)

function Get-ServiceResult {
    param($ServiceObject, $PropertyMap)
    $result = Get-SCVMMResultFromMap -PropertyMap $PropertyMap -CurrentObject $ServiceObject
    $result['cloud_name'] = if ($ServiceObject.Cloud) { $ServiceObject.Cloud.ToString() } else { $null }
    $result['service_template_name'] = if ($ServiceObject.ServiceTemplate) { $ServiceObject.ServiceTemplate.ToString() } else { $null }
    return $result
}

$name = $module.Params.name

$allMatches = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCService' -Name $name -ObjectType 'service' `
    -AllowMultiple $true

if ($null -eq $allMatches) {
    $existing = $null
}
else {
    if ($module.Params.cloud) {
        $cloudFilter = $module.Params.cloud
        $existing = @($allMatches) | Where-Object { $_.Cloud -and $_.Cloud.ToString() -eq $cloudFilter } | Select-Object -First 1
    }
    elseif (@($allMatches).Count -eq 1) {
        $existing = @($allMatches)[0]
    }
    else {
        $cloudList = (@($allMatches) | ForEach-Object { if ($_.Cloud) { $_.Cloud.ToString() } else { '(none)' } }) -join "', '"
        $module.FailJson("Multiple services found with name '$name' (clouds: '$cloudList'). Specify 'cloud' to identify the target service.")
    }
}

if ($module.Params.state -eq 'present') {
    if (-not $existing) {
        $module.Diff.before = @{}
        if (-not $module.Params.service_template) {
            $module.FailJson("'service_template' is required when creating a new service")
        }
        if (-not $module.Params.cloud) {
            $module.FailJson("'cloud' is required when creating a new service")
        }
        $module.Result.changed = $true

        if (-not $module.CheckMode) {
            $templateObj = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
                -CmdletName 'Get-SCServiceTemplate' -Name $module.Params.service_template `
                -ObjectType 'service template' -FailIfNotFound $true

            $cloudObj = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
                -CmdletName 'Get-SCCloud' -Name $module.Params.cloud `
                -ObjectType 'cloud' -FailIfNotFound $true

            $configParams = @{
                Name = $name
                ServiceTemplate = $templateObj
                Cloud = $cloudObj
                VMMServer = $vmmConnection
                ErrorAction = 'Stop'
            }
            if ($null -ne $module.Params.description) { $configParams['Description'] = $module.Params.description }
            if ($null -ne $module.Params.service_priority) { $configParams['ServicePriority'] = $module.Params.service_priority }
            if ($null -ne $module.Params.cost_center) { $configParams['CostCenter'] = $module.Params.cost_center }

            try {
                $serviceConfig = New-SCServiceConfiguration @configParams
            }
            catch {
                $module.FailJson("Failed to create service configuration '$name': $($_.Exception.Message)", $_)
            }

            $serviceParams = @{
                ServiceConfiguration = $serviceConfig
                VMMServer = $vmmConnection
                ErrorAction = 'Stop'
            }
            if ($null -ne $module.Params.owner) { $serviceParams['Owner'] = $module.Params.owner }

            try {
                $existing = New-SCService @serviceParams
                $module.Result.service = Get-ServiceResult -ServiceObject $existing -PropertyMap $propertyMap
                $module.Diff.after = $module.Result.service
            }
            catch {
                try { Remove-SCServiceConfiguration -ServiceConfiguration $serviceConfig -ErrorAction Stop | Out-Null } catch { $null = $_ }
                $module.FailJson("Failed to create service '$name': $($_.Exception.Message)", $_)
            }
        }
        else {
            $module.Result.service = @{
                id = $null
                name = $name
                description = $module.Params.description
                service_priority = $module.Params.service_priority
                cost_center = $module.Params.cost_center
                owner = $module.Params.owner
                cloud_name = $module.Params.cloud
                service_template_name = $module.Params.service_template
                service_template_release = $null
                deployment_state = $null
                enabled = $null
                creation_time = $null
                modified_time = $null
            }
            $module.Diff.after = $module.Result.service
        }
    }
    else {
        $currentResult = Get-ServiceResult -ServiceObject $existing -PropertyMap $propertyMap

        $updateParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap `
            -AnsibleParams $module.Params -CurrentObject $existing
        $needsUpdate = $updateParams.Count -gt 0

        if ($needsUpdate) {
            $module.Diff.before = $currentResult
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                $updateParams['Service'] = $existing
                $updateParams['ErrorAction'] = 'Stop'
                try {
                    $existing = Set-SCService @updateParams
                }
                catch {
                    $module.FailJson("Failed to update service '$name': $($_.Exception.Message)", $_)
                }
                $module.Result.service = Get-ServiceResult -ServiceObject $existing -PropertyMap $propertyMap
                $module.Diff.after = $module.Result.service
            }
            else {
                $module.Result.service = $currentResult
                $module.Diff.after = Get-SCVMMCheckModeDiff -Before $currentResult `
                    -UpdateMap $updateMap -AnsibleParams $module.Params -CurrentObject $existing
            }
        }
        else {
            $module.Result.service = $currentResult
        }
    }
}
else {
    if ($existing) {
        $module.Diff.before = Get-ServiceResult -ServiceObject $existing -PropertyMap $propertyMap
        $module.Diff.after = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                if ($existing.DeploymentState -ne 'Undeployed') {
                    Stop-SCService -Service $existing -ErrorAction Stop | Out-Null
                }
                Remove-SCService -Service $existing -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove service '$name': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
