#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str' }
        vmm_server = @{ type = 'str' }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

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

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

if ($module.Params.name) {
    $name = $module.Params.name
    $hwProfile = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCHardwareProfile' -ObjectType 'hardware profile' `
        -FilterScript { $_.Name -eq $name }
    $profiles = if ($hwProfile) { @($hwProfile) } else { @() }
}
else {
    $hwProfiles = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCHardwareProfile' -ObjectType 'hardware profile'
    $profiles = @($hwProfiles)
}

$module.Result.hardware_profiles = @($profiles | ForEach-Object {
        Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
    })

$module.ExitJson()
