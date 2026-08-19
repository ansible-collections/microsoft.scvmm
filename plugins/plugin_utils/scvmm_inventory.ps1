# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)
#
# Self-contained SCVMM inventory query script executed on the SCVMM server via
# PSRP by the microsoft.scvmm.scvmm_inventory plugin. It must NOT depend on
# Ansible.Basic (it runs standalone, not under the module framework).
#
# The per-VM data shape below intentionally mirrors the RETURN of the
# microsoft.scvmm.scvmm_inventory_info module so the plugin and the info module
# expose the same facts. Keep the two in sync until they are unified.
#
# Output contract: a single JSON object printed to stdout:
#   { "virtual_machines": [ { ...vm... }, ... ], "hosts": [ { ...host... }, ... ] }
# On failure: { "error": "<message>" } with a non-empty error key.

$ErrorActionPreference = 'Stop'

function Get-NestedName {
    param($Value)
    if ($null -ne $Value) { return $Value.Name }
    return $null
}

try {
    if (-not (Get-Module -Name VirtualMachineManager -ListAvailable)) {
        Write-Output (@{ error = 'The VirtualMachineManager PowerShell module is not installed on the SCVMM server.' } | ConvertTo-Json -Compress)
        return
    }
    Import-Module -Name VirtualMachineManager -ErrorAction Stop | Out-Null

    $connection = Get-SCVMMServer -ComputerName 'localhost' -ErrorAction Stop

    $vms = @(Get-SCVirtualMachine -VMMServer $connection -ErrorAction Stop)

    $result = @(
        foreach ($vm in $vms) {
            $adapters = @()
            try {
                $adapters = @(Get-SCVirtualNetworkAdapter -VM $vm -ErrorAction Stop)
            }
            catch {
                $adapters = @()
            }

            $allIps = @()
            $allMacs = @()
            $adapterList = @(
                foreach ($a in $adapters) {
                    $adapterIps = @($a.IPv4Addresses | Where-Object { $_ })
                    $allIps += $adapterIps
                    $mac = if ($a.MACAddress) { [string]$a.MACAddress } else { $null }
                    if ($mac) { $allMacs += $mac }
                    @{
                        name = if ($a.Name) { [string]$a.Name } else { $null }
                        vm_network = Get-NestedName -Value $a.VMNetwork
                        mac_address = $mac
                        ipv4_addresses = $adapterIps
                    }
                }
            )

            @{
                id = if ($null -ne $vm.ID) { $vm.ID.ToString() } else { $null }
                name = if ($null -ne $vm.Name) { [string]$vm.Name } else { $null }
                status = if ($null -ne $vm.Status) { $vm.Status.ToString() } else { $null }
                owner = if ($null -ne $vm.Owner) { [string]$vm.Owner } else { $null }
                host_name = Get-NestedName -Value $vm.VMHost
                host_group = if ($vm.VMHost -and $vm.VMHost.VMHostGroup) { $vm.VMHost.VMHostGroup.Name } else { $null }
                cloud = Get-NestedName -Value $vm.Cloud
                cpu_count = $vm.CPUCount
                memory_mb = $vm.Memory
                operating_system = Get-NestedName -Value $vm.OperatingSystem
                description = if ($null -ne $vm.Description) { [string]$vm.Description } else { $null }
                creation_time = if ($null -ne $vm.CreationTime) { $vm.CreationTime.ToString('o') } else { $null }
                ipv4_addresses = @($allIps | Where-Object { $_ })
                mac_addresses = @($allMacs | Where-Object { $_ })
                network_adapters = $adapterList
            }
        }
    )

    $vmHosts = @(Get-SCVMHost -VMMServer $connection -ErrorAction Stop)

    $hostResult = @(
        foreach ($h in $vmHosts) {
            @{
                id = if ($null -ne $h.ID) { $h.ID.ToString() } else { $null }
                name = if ($null -ne $h.Name) { [string]$h.Name } else { $null }
                computer_name = if ($null -ne $h.ComputerName) { [string]$h.ComputerName } else { $null }
                state = if ($null -ne $h.OverallState) { $h.OverallState.ToString() } else { $null }
                host_group = Get-NestedName -Value $h.VMHostGroup
                cluster = Get-NestedName -Value $h.HostCluster
                virtualization_platform = if ($null -ne $h.VirtualizationPlatform) { $h.VirtualizationPlatform.ToString() } else { $null }
                virtual_machine_count = if ($null -ne $h.VMs) { @($h.VMs).Count } else { 0 }
            }
        }
    )

    $payload = @{
        virtual_machines = $result
        hosts = $hostResult
    }
    Write-Output ($payload | ConvertTo-Json -Depth 6 -Compress)
}
catch {
    Write-Output (@{ error = "SCVMM inventory query failed: $($_.Exception.Message)" } | ConvertTo-Json -Compress)
}
