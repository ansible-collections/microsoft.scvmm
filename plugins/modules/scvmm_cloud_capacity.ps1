#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        cloud = @{ type = 'str'; required = $true }
        cpu_count = @{ type = 'int' }
        memory_gb = @{ type = 'int' }
        storage_gb = @{ type = 'int' }
        vm_count = @{ type = 'int' }
        vmm_server = @{ type = 'str' }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

$cloudObj = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCCloud' -Name $module.Params.cloud `
    -ObjectType 'cloud' -FailIfNotFound $true

try {
    $capacity = Get-SCCloudCapacity -Cloud $cloudObj -ErrorAction Stop
}
catch {
    $module.FailJson("Failed to get cloud capacity for '$($module.Params.cloud)': $($_.Exception.Message)", $_)
}

$resultMap = @(
    @{ Param = "cpu_count"; Property = "CPUCount"; Type = "int" }
    @{ Param = "memory_gb"; Property = "MemoryMB"; Type = "mb_to_gb" }
    @{ Param = "storage_gb"; Property = "StorageGB"; Type = "int" }
    @{ Param = "vm_count"; Property = "VMCount"; Type = "int" }
)

$updateMap = @(
    @{ Param = "cpu_count"; Property = "CPUCount"; Type = "int"; CmdletParam = "CPUCount" }
    @{ Param = "memory_gb"; Property = "MemoryMB"; Type = "mb_to_gb"; CmdletParam = "MemoryMB" }
    @{ Param = "storage_gb"; Property = "StorageGB"; Type = "int"; CmdletParam = "StorageGB" }
    @{ Param = "vm_count"; Property = "VMCount"; Type = "int"; CmdletParam = "VMCount" }
)

$needsUpdate = Test-SCVMMPropertiesChanged -PropertyMap $updateMap -CurrentObject $capacity -AnsibleParams $module.Params

if ($needsUpdate) {
    $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $resultMap -CurrentObject $capacity
    $module.Diff.before['cloud'] = $cloudObj.Name

    $setParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap -AnsibleParams $module.Params -CurrentObject $capacity

    if (-not $module.CheckMode) {
        try {
            $capacity = Set-SCCloudCapacity -CloudCapacity $capacity @setParams -ErrorAction Stop
        }
        catch {
            $module.FailJson("Failed to update cloud capacity: $($_.Exception.Message)", $_)
        }
    }
    $module.Result.changed = $true
}

$module.Result.cloud_capacity = Get-SCVMMResultFromMap -PropertyMap $resultMap -CurrentObject $capacity
$module.Result.cloud_capacity['cloud'] = $cloudObj.Name

if ($needsUpdate) {
    if ($module.CheckMode) {
        $projected = Get-SCVMMCheckModeDiff -Before $module.Diff.before -UpdateMap $updateMap -AnsibleParams $module.Params -CurrentObject $capacity
        $projected['cloud'] = $cloudObj.Name
        $module.Diff.after = $projected
    }
    else {
        $module.Diff.after = $module.Result.cloud_capacity
    }
}

$module.ExitJson()
