#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        user_role_name = @{ type = 'str'; required = $true }
        quota_per_user = @{ type = 'bool' }
        vmm_server = @{ type = 'str' }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

$userRoleName = $module.Params.user_role_name

$userRole = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCUserRole' -Name $userRoleName -ObjectType 'user role' -FailIfNotFound $true

try {
    $getParams = @{
        UserRole = $userRole
        ErrorAction = 'Stop'
    }
    if ($null -ne $module.Params.quota_per_user) {
        $getParams['QuotaPerUser'] = $module.Params.quota_per_user
    }
    $quotas = @(Get-SCUserRoleQuota @getParams)
}
catch {
    $module.FailJson("Failed to query user role quotas: $($_.Exception.Message)", $_)
}

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "vm_count"; Property = "VMCount"; Type = "int" }
    @{ Param = "cpu_count"; Property = "CPUCount"; Type = "int" }
    @{ Param = "memory_mb"; Property = "MemoryMB"; Type = "int" }
    @{ Param = "storage_gb"; Property = "StorageGB"; Type = "int" }
    @{ Param = "custom_quota_count"; Property = "CustomQuotaCount"; Type = "int" }
    @{ Param = "quota_per_user"; Property = "QuotaPerUser"; Type = "bool" }
)

$module.Result.user_role_quotas = @($quotas | ForEach-Object {
        $entry = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
        $entry['user_role_name'] = $userRoleName
        $entry
    })

$module.ExitJson()
