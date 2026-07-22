#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        vm_name = @{ type = 'str'; required = $true }
        vmm_server = @{ type = 'str' }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

$vm = Get-SCVirtualMachine -VMMServer $vmmConnection -Name $module.Params.vm_name -ErrorAction SilentlyContinue
if (-not $vm) {
    $module.Result.network_adapters = @()
    $module.ExitJson()
}

$adapters = @(Get-SCVirtualNetworkAdapter -VM $vm -ErrorAction Stop)

$module.Result.network_adapters = @($adapters | ForEach-Object {
        @{
            id = $_.ID.ToString()
            name = $_.Name
            vm_name = if ($_.VM) { $_.VM.Name } else { $module.Params.vm_name }
            vm_network = if ($_.VMNetwork) { $_.VMNetwork.Name } else { $null }
            mac_address = $_.MACAddress
            mac_address_type = $_.MACAddressType.ToString()
            ipv4_addresses = @($_.IPv4Addresses)
            is_synthetic = -not $_.IsEmulated
        }
    })

$module.ExitJson()
