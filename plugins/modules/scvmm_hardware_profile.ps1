#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        description = @{ type = 'str' }
        owner = @{ type = 'str' }
        cpu_count = @{ type = 'int' }
        memory_mb = @{ type = 'int' }
        dynamic_memory = @{ type = 'bool' }
        dynamic_memory_minimum_mb = @{ type = 'int' }
        dynamic_memory_maximum_mb = @{ type = 'int' }
        cpu_expected_utilization_percent = @{ type = 'int' }
        cpu_maximum_percent = @{ type = 'int' }
        cpu_relative_weight = @{ type = 'int' }
        cpu_reserve = @{ type = 'int' }
        highly_available = @{ type = 'bool' }
        generation = @{ type = 'int'; choices = @(1, 2) }
        secure_boot_enabled = @{ type = 'bool' }
        checkpoint_type = @{ type = 'str'; choices = @('Disabled', 'Production', 'ProductionOnly', 'Standard') }
        network_utilization_mbps = @{ type = 'int' }
        disk_iops = @{ type = 'int' }
        vmm_server = @{ type = 'str' }
        state = @{ type = 'str'; default = 'present'; choices = @('present', 'absent') }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name
$state = $module.Params.state

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "owner"; Property = "Owner"; Type = "string" }
    @{ Param = "cpu_count"; Property = "CPUCount"; Type = "int" }
    @{ Param = "memory_mb"; Property = "Memory"; Type = "int" }
    @{ Param = "dynamic_memory"; Property = "DynamicMemoryEnabled"; Type = "bool" }
    @{ Param = "dynamic_memory_minimum_mb"; Property = "DynamicMemoryMinimumMB"; Type = "int" }
    @{ Param = "dynamic_memory_maximum_mb"; Property = "DynamicMemoryMaximumMB"; Type = "int" }
    @{ Param = "generation"; Property = "Generation"; Type = "int" }
    @{ Param = "highly_available"; Property = "HighlyAvailable"; Type = "bool" }
    @{ Param = "secure_boot_enabled"; Property = "SecureBootEnabled"; Type = "bool" }
    @{ Param = "checkpoint_type"; Property = "CheckpointType"; Type = "enum" }
    @{ Param = "cpu_expected_utilization_percent"; Property = "ExpectedCPUUtilization"; Type = "int" }
    @{ Param = "cpu_maximum_percent"; Property = "CPUMaximumPercent"; Type = "int" }
    @{ Param = "cpu_relative_weight"; Property = "CPURelativeWeight"; Type = "int" }
    @{ Param = "cpu_reserve"; Property = "CPUReserve"; Type = "int" }
    @{ Param = "network_utilization_mbps"; Property = "NetworkUtilization"; Type = "int" }
    @{ Param = "disk_iops"; Property = "DiskIops"; Type = "int" }
    @{ Param = "creation_time"; Property = "AddedTime"; Type = "datetime_iso" }
)

$updateMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "owner"; Property = "Owner"; Type = "string" }
    @{ Param = "cpu_count"; Property = "CPUCount"; Type = "int" }
    @{ Param = "memory_mb"; Property = "Memory"; Type = "int"; CmdletParam = "MemoryMB" }
    @{ Param = "dynamic_memory"; Property = "DynamicMemoryEnabled"; Type = "bool" }
    @{ Param = "dynamic_memory_minimum_mb"; Property = "DynamicMemoryMinimumMB"; Type = "int" }
    @{ Param = "dynamic_memory_maximum_mb"; Property = "DynamicMemoryMaximumMB"; Type = "int" }
    @{ Param = "highly_available"; Property = "HighlyAvailable"; Type = "bool" }
    @{ Param = "secure_boot_enabled"; Property = "SecureBootEnabled"; Type = "bool" }
    @{ Param = "checkpoint_type"; Property = "CheckpointType"; Type = "enum" }
    @{ Param = "cpu_expected_utilization_percent"; Property = "ExpectedCPUUtilization"; Type = "int"; CmdletParam = "CPUExpectedUtilizationPercent" }
    @{ Param = "cpu_maximum_percent"; Property = "CPUMaximumPercent"; Type = "int" }
    @{ Param = "cpu_relative_weight"; Property = "CPURelativeWeight"; Type = "int" }
    @{ Param = "cpu_reserve"; Property = "CPUReserve"; Type = "int" }
    @{ Param = "network_utilization_mbps"; Property = "NetworkUtilization"; Type = "int"; CmdletParam = "NetworkUtilizationMbps" }
    @{ Param = "disk_iops"; Property = "DiskIops"; Type = "int" }
)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

if ($state -eq 'present') {
    $existing = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCHardwareProfile' -ObjectType 'hardware profile' `
        -FilterScript { $_.Name -eq $name }

    if ($existing) {
        if ($null -ne $module.Params.generation -and
            $existing.Generation -ne $module.Params.generation) {
            $cur = $existing.Generation
            $req = $module.Params.generation
            $module.Warn("Cannot change 'generation' after creation (current: '$cur', requested: '$req'). Delete and recreate.")
        }

        $updateParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap `
            -AnsibleParams $module.Params -CurrentObject $existing
        $needsUpdate = $updateParams.Count -gt 0

        if ($needsUpdate) {
            $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $existing
            if (-not $module.CheckMode) {
                try {
                    $existing = Set-SCHardwareProfile -HardwareProfile $existing @updateParams -ErrorAction Stop
                }
                catch {
                    $module.FailJson("Failed to update hardware profile '$name': $($_.Exception.Message)", $_)
                }
            }
            $module.Result.changed = $true
        }

        $module.Result.hardware_profile = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $existing

        if ($needsUpdate) {
            if ($module.CheckMode) {
                $module.Diff.after = Get-SCVMMCheckModeDiff -Before $module.Diff.before `
                    -UpdateMap $updateMap -AnsibleParams $module.Params -CurrentObject $existing
            }
            else {
                $module.Diff.after = $module.Result.hardware_profile
            }
        }
    }
    else {
        $createParams = @{ Name = $name }
        $mapParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap -AnsibleParams $module.Params
        foreach ($key in $mapParams.Keys) { $createParams[$key] = $mapParams[$key] }
        if ($null -ne $module.Params.generation) { $createParams['Generation'] = $module.Params.generation }

        $module.Diff.before = @{}
        if (-not $module.CheckMode) {
            try {
                $newProfile = New-SCHardwareProfile @createParams -VMMServer $vmmConnection -ErrorAction Stop
            }
            catch {
                $module.FailJson("Failed to create hardware profile '$name': $($_.Exception.Message)", $_)
            }
            $module.Result.hardware_profile = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $newProfile
            $module.Diff.after = $module.Result.hardware_profile
        }
        else {
            $module.Result.hardware_profile = @{
                id = $null
                name = $name
                description = $module.Params.description
                generation = $module.Params.generation
            }
            $module.Diff.after = $module.Result.hardware_profile
        }
        $module.Result.changed = $true
    }
}
elseif ($state -eq 'absent') {
    $existing = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCHardwareProfile' -ObjectType 'hardware profile' `
        -FilterScript { $_.Name -eq $name }

    if ($existing) {
        $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $existing
        $module.Diff.after = @{}
        if (-not $module.CheckMode) {
            try {
                Remove-SCHardwareProfile -HardwareProfile $existing -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove hardware profile '$name': $($_.Exception.Message)", $_)
            }
        }
        $module.Result.changed = $true
    }
}

$module.ExitJson()
