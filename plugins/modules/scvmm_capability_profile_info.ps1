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

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

$profiles = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCCapabilityProfile' -Name $module.Params.name `
    -ObjectType 'capability profile'

if ($module.Params.name) {
    $profiles = if ($profiles) { @($profiles) } else { @() }
}

$module.Result.capability_profiles = @($profiles | ForEach-Object {
        Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
    })

$module.ExitJson()
