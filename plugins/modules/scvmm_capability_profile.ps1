#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        description = @{ type = 'str' }
        fabric_capability_type = @{ type = 'str'; choices = @('HyperV', 'ESX') }
        cpu_count_initial = @{ type = 'int' }
        cpu_count_minimum = @{ type = 'int' }
        cpu_count_maximum = @{ type = 'int' }
        memory_mb_initial = @{ type = 'int' }
        memory_mb_minimum = @{ type = 'int' }
        memory_mb_maximum = @{ type = 'int' }
        dynamic_memory_value = @{ type = 'bool' }
        dynamic_memory_value_can_change = @{ type = 'bool' }
        startup_memory_mb_initial = @{ type = 'int' }
        startup_memory_mb_minimum = @{ type = 'int' }
        startup_memory_mb_maximum = @{ type = 'int' }
        maximum_memory_mb_initial = @{ type = 'int' }
        maximum_memory_mb_minimum = @{ type = 'int' }
        maximum_memory_mb_maximum = @{ type = 'int' }
        virtual_hard_disk_count_initial = @{ type = 'int' }
        virtual_hard_disk_count_minimum = @{ type = 'int' }
        virtual_hard_disk_count_maximum = @{ type = 'int' }
        virtual_hard_disk_size_mb_initial = @{ type = 'int' }
        virtual_hard_disk_size_mb_minimum = @{ type = 'int' }
        virtual_hard_disk_size_mb_maximum = @{ type = 'int' }
        virtual_dvd_drive_count_initial = @{ type = 'int' }
        virtual_dvd_drive_count_minimum = @{ type = 'int' }
        virtual_dvd_drive_count_maximum = @{ type = 'int' }
        virtual_network_adapter_count_initial = @{ type = 'int' }
        virtual_network_adapter_count_minimum = @{ type = 'int' }
        virtual_network_adapter_count_maximum = @{ type = 'int' }
        vm_highly_available_value = @{ type = 'bool' }
        vm_highly_available_value_can_change = @{ type = 'bool' }
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
    @{ Param = "fabric_capability_type"; Property = "FabricCapabilityType"; Type = "enum" }
    @{ Param = "cpu_count_initial"; Property = "CPUCountInitial"; Type = "int" }
    @{ Param = "cpu_count_minimum"; Property = "CPUCountMinimum"; Type = "int" }
    @{ Param = "cpu_count_maximum"; Property = "CPUCountMaximum"; Type = "int" }
    @{ Param = "memory_mb_initial"; Property = "MemoryMBInitial"; Type = "int" }
    @{ Param = "memory_mb_minimum"; Property = "MemoryMBMinimum"; Type = "int" }
    @{ Param = "memory_mb_maximum"; Property = "MemoryMBMaximum"; Type = "int" }
    @{ Param = "dynamic_memory_value"; Property = "DynamicMemoryValue"; Type = "bool" }
    @{ Param = "dynamic_memory_value_can_change"; Property = "DynamicMemoryValueCanChange"; Type = "bool" }
    @{ Param = "startup_memory_mb_initial"; Property = "StartupMemoryMBInitial"; Type = "int" }
    @{ Param = "startup_memory_mb_minimum"; Property = "StartupMemoryMBMinimum"; Type = "int" }
    @{ Param = "startup_memory_mb_maximum"; Property = "StartupMemoryMBMaximum"; Type = "int" }
    @{ Param = "maximum_memory_mb_initial"; Property = "MaximumMemoryMBInitial"; Type = "int" }
    @{ Param = "maximum_memory_mb_minimum"; Property = "MaximumMemoryMBMinimum"; Type = "int" }
    @{ Param = "maximum_memory_mb_maximum"; Property = "MaximumMemoryMBMaximum"; Type = "int" }
    @{ Param = "virtual_hard_disk_count_initial"; Property = "VirtualHardDiskCountInitial"; Type = "int" }
    @{ Param = "virtual_hard_disk_count_minimum"; Property = "VirtualHardDiskCountMinimum"; Type = "int" }
    @{ Param = "virtual_hard_disk_count_maximum"; Property = "VirtualHardDiskCountMaximum"; Type = "int" }
    @{ Param = "virtual_hard_disk_size_mb_initial"; Property = "VirtualHardDiskSizeMBInitial"; Type = "int" }
    @{ Param = "virtual_hard_disk_size_mb_minimum"; Property = "VirtualHardDiskSizeMBMinimum"; Type = "int" }
    @{ Param = "virtual_hard_disk_size_mb_maximum"; Property = "VirtualHardDiskSizeMBMaximum"; Type = "int" }
    @{ Param = "virtual_dvd_drive_count_initial"; Property = "VirtualDVDDriveCountInitial"; Type = "int" }
    @{ Param = "virtual_dvd_drive_count_minimum"; Property = "VirtualDVDDriveCountMinimum"; Type = "int" }
    @{ Param = "virtual_dvd_drive_count_maximum"; Property = "VirtualDVDDriveCountMaximum"; Type = "int" }
    @{ Param = "virtual_network_adapter_count_initial"; Property = "VirtualNetworkAdapterCountInitial"; Type = "int" }
    @{ Param = "virtual_network_adapter_count_minimum"; Property = "VirtualNetworkAdapterCountMinimum"; Type = "int" }
    @{ Param = "virtual_network_adapter_count_maximum"; Property = "VirtualNetworkAdapterCountMaximum"; Type = "int" }
    @{ Param = "vm_highly_available_value"; Property = "VMHighlyAvailableValue"; Type = "bool" }
    @{ Param = "vm_highly_available_value_can_change"; Property = "VMHighlyAvailableValueCanChange"; Type = "bool" }
)

$updateMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "cpu_count_initial"; Property = "CPUCountInitial"; Type = "int" }
    @{ Param = "cpu_count_minimum"; Property = "CPUCountMinimum"; Type = "int" }
    @{ Param = "cpu_count_maximum"; Property = "CPUCountMaximum"; Type = "int" }
    @{ Param = "memory_mb_initial"; Property = "MemoryMBInitial"; Type = "int" }
    @{ Param = "memory_mb_minimum"; Property = "MemoryMBMinimum"; Type = "int" }
    @{ Param = "memory_mb_maximum"; Property = "MemoryMBMaximum"; Type = "int" }
    @{ Param = "dynamic_memory_value"; Property = "DynamicMemoryValue"; Type = "bool" }
    @{ Param = "dynamic_memory_value_can_change"; Property = "DynamicMemoryValueCanChange"; Type = "bool" }
    @{ Param = "startup_memory_mb_initial"; Property = "StartupMemoryMBInitial"; Type = "int" }
    @{ Param = "startup_memory_mb_minimum"; Property = "StartupMemoryMBMinimum"; Type = "int" }
    @{ Param = "startup_memory_mb_maximum"; Property = "StartupMemoryMBMaximum"; Type = "int" }
    @{ Param = "maximum_memory_mb_initial"; Property = "MaximumMemoryMBInitial"; Type = "int" }
    @{ Param = "maximum_memory_mb_minimum"; Property = "MaximumMemoryMBMinimum"; Type = "int" }
    @{ Param = "maximum_memory_mb_maximum"; Property = "MaximumMemoryMBMaximum"; Type = "int" }
    @{ Param = "virtual_hard_disk_count_initial"; Property = "VirtualHardDiskCountInitial"; Type = "int" }
    @{ Param = "virtual_hard_disk_count_minimum"; Property = "VirtualHardDiskCountMinimum"; Type = "int" }
    @{ Param = "virtual_hard_disk_count_maximum"; Property = "VirtualHardDiskCountMaximum"; Type = "int" }
    @{ Param = "virtual_hard_disk_size_mb_initial"; Property = "VirtualHardDiskSizeMBInitial"; Type = "int" }
    @{ Param = "virtual_hard_disk_size_mb_minimum"; Property = "VirtualHardDiskSizeMBMinimum"; Type = "int" }
    @{ Param = "virtual_hard_disk_size_mb_maximum"; Property = "VirtualHardDiskSizeMBMaximum"; Type = "int" }
    @{ Param = "virtual_dvd_drive_count_initial"; Property = "VirtualDVDDriveCountInitial"; Type = "int" }
    @{ Param = "virtual_dvd_drive_count_minimum"; Property = "VirtualDVDDriveCountMinimum"; Type = "int" }
    @{ Param = "virtual_dvd_drive_count_maximum"; Property = "VirtualDVDDriveCountMaximum"; Type = "int" }
    @{ Param = "virtual_network_adapter_count_initial"; Property = "VirtualNetworkAdapterCountInitial"; Type = "int" }
    @{ Param = "virtual_network_adapter_count_minimum"; Property = "VirtualNetworkAdapterCountMinimum"; Type = "int" }
    @{ Param = "virtual_network_adapter_count_maximum"; Property = "VirtualNetworkAdapterCountMaximum"; Type = "int" }
    @{ Param = "vm_highly_available_value"; Property = "VMHighlyAvailableValue"; Type = "bool" }
    @{ Param = "vm_highly_available_value_can_change"; Property = "VMHighlyAvailableValueCanChange"; Type = "bool" }
)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

if ($state -eq 'present') {
    $existing = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCCapabilityProfile' -Name $name -ObjectType 'capability profile'

    if ($existing) {
        if ($null -ne $module.Params.fabric_capability_type -and
            $existing.FabricCapabilityType.ToString() -ne $module.Params.fabric_capability_type) {
            $cur = $existing.FabricCapabilityType
            $req = $module.Params.fabric_capability_type
            $module.Warn("Cannot change 'fabric_capability_type' after creation (current: '$cur', requested: '$req'). Delete and recreate.")
        }

        $updateParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap `
            -AnsibleParams $module.Params -CurrentObject $existing
        $needsUpdate = $updateParams.Count -gt 0

        if ($needsUpdate) {
            $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $existing
            if (-not $module.CheckMode) {
                try {
                    $existing = Set-SCCapabilityProfile -CapabilityProfile $existing @updateParams -ErrorAction Stop
                }
                catch {
                    $module.FailJson("Failed to update capability profile '$name': $($_.Exception.Message)", $_)
                }
            }
            $module.Result.changed = $true
        }

        $module.Result.capability_profile = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $existing

        if ($needsUpdate) {
            if ($module.CheckMode) {
                $module.Diff.after = Get-SCVMMCheckModeDiff -Before $module.Diff.before `
                    -UpdateMap $updateMap -AnsibleParams $module.Params -CurrentObject $existing
            }
            else {
                $module.Diff.after = $module.Result.capability_profile
            }
        }
    }
    else {
        if (-not $module.Params.fabric_capability_type) {
            $module.FailJson("fabric_capability_type is required when creating a new capability profile")
        }

        $createParams = @{
            Name = $name
            FabricCapabilityType = $module.Params.fabric_capability_type
        }
        $mapParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap -AnsibleParams $module.Params
        foreach ($key in $mapParams.Keys) { $createParams[$key] = $mapParams[$key] }

        $module.Diff.before = @{}
        if (-not $module.CheckMode) {
            try {
                $newProfile = New-SCCapabilityProfile @createParams -VMMServer $vmmConnection -ErrorAction Stop
            }
            catch {
                $module.FailJson("Failed to create capability profile '$name': $($_.Exception.Message)", $_)
            }
            $module.Result.capability_profile = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $newProfile
            $module.Diff.after = $module.Result.capability_profile
        }
        else {
            $module.Result.capability_profile = @{
                id = $null
                name = $name
                fabric_capability_type = $module.Params.fabric_capability_type
                description = $module.Params.description
            }
            $module.Diff.after = $module.Result.capability_profile
        }
        $module.Result.changed = $true
    }
}
elseif ($state -eq 'absent') {
    $existing = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCCapabilityProfile' -Name $name -ObjectType 'capability profile'

    if ($existing) {
        $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $existing
        $module.Diff.after = @{}
        if (-not $module.CheckMode) {
            try {
                Remove-SCCapabilityProfile -CapabilityProfile $existing -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove capability profile '$name': $($_.Exception.Message)", $_)
            }
        }
        $module.Result.changed = $true
    }
}

$module.ExitJson()
