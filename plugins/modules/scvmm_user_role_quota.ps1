#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        user_role_name = @{ type = 'str'; required = $true }
        quota_per_user = @{ type = 'bool'; default = $false }
        vm_count = @{ type = 'int' }
        cpu_count = @{ type = 'int' }
        memory_mb = @{ type = 'int' }
        storage_gb = @{ type = 'int' }
        custom_quota_count = @{ type = 'int' }
        use_cpu_count_maximum = @{ type = 'bool' }
        use_memory_mb_maximum = @{ type = 'bool' }
        use_storage_gb_maximum = @{ type = 'bool' }
        use_custom_quota_count_maximum = @{ type = 'bool' }
        use_vm_count_maximum = @{ type = 'bool' }
        vmm_server = @{ type = 'str' }
    }
    mutually_exclusive = @(
        , @('vm_count', 'use_vm_count_maximum')
        , @('cpu_count', 'use_cpu_count_maximum')
        , @('memory_mb', 'use_memory_mb_maximum')
        , @('storage_gb', 'use_storage_gb_maximum')
        , @('custom_quota_count', 'use_custom_quota_count_maximum')
    )
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

$userRoleName = $module.Params.user_role_name
$quotaPerUser = $module.Params.quota_per_user

$userRole = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCUserRole' -Name $userRoleName -ObjectType 'user role' -FailIfNotFound $true

try {
    $quotas = @(Get-SCUserRoleQuota -UserRole $userRole -QuotaPerUser $quotaPerUser -ErrorAction Stop)
}
catch {
    $module.FailJson("Failed to query user role quotas: $($_.Exception.Message)", $_)
}

if ($quotas.Count -eq 0) {
    $module.FailJson("No quota found for user role '$userRoleName' with quota_per_user=$quotaPerUser.")
}

$existing = $quotas[0]

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "vm_count"; Property = "VMCount"; Type = "int" }
    @{ Param = "cpu_count"; Property = "CPUCount"; Type = "int" }
    @{ Param = "memory_mb"; Property = "MemoryMB"; Type = "int" }
    @{ Param = "storage_gb"; Property = "StorageGB"; Type = "int" }
    @{ Param = "custom_quota_count"; Property = "CustomQuotaCount"; Type = "int" }
    @{ Param = "quota_per_user"; Property = "QuotaPerUser"; Type = "bool" }
)

$updateMap = @(
    @{ Param = "vm_count"; Property = "VMCount"; Type = "int"; CmdletParam = "VMCount" }
    @{ Param = "cpu_count"; Property = "CPUCount"; Type = "int"; CmdletParam = "CPUCount" }
    @{ Param = "memory_mb"; Property = "MemoryMB"; Type = "int"; CmdletParam = "MemoryMB" }
    @{ Param = "storage_gb"; Property = "StorageGB"; Type = "int"; CmdletParam = "StorageGB" }
    @{ Param = "custom_quota_count"; Property = "CustomQuotaCount"; Type = "int"; CmdletParam = "CustomQuotaCount" }
)

$currentResult = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $existing
$currentResult['user_role_name'] = $userRoleName
$module.Diff.before = $currentResult

$updateParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap `
    -AnsibleParams $module.Params -CurrentObject $existing

$useMaxParams = @(
    @{ Param = "use_vm_count_maximum"; CmdletParam = "UseVMCountMaximum"; CountProperty = "VMCount" }
    @{ Param = "use_cpu_count_maximum"; CmdletParam = "UseCPUCountMaximum"; CountProperty = "CPUCount" }
    @{ Param = "use_memory_mb_maximum"; CmdletParam = "UseMemoryMBMaximum"; CountProperty = "MemoryMB" }
    @{ Param = "use_storage_gb_maximum"; CmdletParam = "UseStorageGBMaximum"; CountProperty = "StorageGB" }
    @{ Param = "use_custom_quota_count_maximum"; CmdletParam = "UseCustomQuotaCountMaximum"; CountProperty = "CustomQuotaCount" }
)
foreach ($p in $useMaxParams) {
    if ($module.Params.$($p.Param) -eq $true) {
        if ($null -eq $existing.$($p.CountProperty)) {
            continue
        }
        $updateParams[$p.CmdletParam] = $true
    }
}

if ($updateParams.Count -gt 0) {
    $module.Result.changed = $true
    if (-not $module.CheckMode) {
        $updateParams['UserRoleQuota'] = $existing
        $updateParams['ErrorAction'] = 'Stop'
        try {
            $existing = Set-SCUserRoleQuota @updateParams
        }
        catch {
            $module.FailJson("Failed to update user role quota: $($_.Exception.Message)", $_)
        }
        $module.Result.user_role_quota = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $existing
        $module.Result.user_role_quota['user_role_name'] = $userRoleName
        $module.Diff.after = $module.Result.user_role_quota
    }
    else {
        $module.Result.user_role_quota = $currentResult
        $projected = Get-SCVMMCheckModeDiff -Before $currentResult `
            -UpdateMap $updateMap -AnsibleParams $module.Params -CurrentObject $existing
        foreach ($p in $useMaxParams) {
            if ($module.Params.$($p.Param) -eq $true) {
                $countParam = ($updateMap | Where-Object { $_.Property -eq $p.CountProperty }).Param
                if ($countParam) {
                    $projected[$countParam] = $null
                }
            }
        }
        $module.Diff.after = $projected
    }
}
else {
    $module.Result.user_role_quota = $currentResult
    $module.Diff.after = $currentResult
}

$module.ExitJson()
