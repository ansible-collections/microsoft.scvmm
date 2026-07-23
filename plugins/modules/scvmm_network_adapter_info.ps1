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

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{ Param = "vm_network"; Property = "VMNetwork"; Type = "nested_name" }
    @{ Param = "mac_address"; Property = "MACAddress"; Type = "string" }
    @{ Param = "mac_address_type"; Property = "MACAddressType"; Type = "enum" }
)

$vm = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCVirtualMachine' -Name $module.Params.vm_name `
    -ObjectType 'Virtual machine'
if (-not $vm) {
    $module.Result.network_adapters = @()
    $module.ExitJson()
}

$adapters = @(Get-SCVirtualNetworkAdapter -VM $vm -ErrorAction Stop)

$module.Result.network_adapters = @($adapters | ForEach-Object {
        $result = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
        $result['vm_name'] = if ($_.VM) { $_.VM.Name } else { $module.Params.vm_name }
        $result['ipv4_addresses'] = @($_.IPv4Addresses)
        $result['is_synthetic'] = -not $_.IsEmulated
        $result
    })

$module.ExitJson()
