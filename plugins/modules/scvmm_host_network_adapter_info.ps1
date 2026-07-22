#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        vm_host = @{ type = 'str' }
        vmm_server = @{ type = 'str' }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

try {
    if ($module.Params.vm_host) {
        $vmHost = Get-SCVMHost -VMMServer $vmmConnection -ComputerName $module.Params.vm_host -ErrorAction Stop
        if (-not $vmHost) {
            $module.FailJson("Host '$($module.Params.vm_host)' not found")
        }
        $adapters = @(Get-SCVMHostNetworkAdapter -VMHost $vmHost -ErrorAction Stop)
    }
    else {
        $adapters = @(Get-SCVMHostNetworkAdapter -VMMServer $vmmConnection -ErrorAction Stop)
    }
}
catch {
    $module.FailJson("Failed to query network adapters: $($_.Exception.Message)", $_)
}

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{ Param = "connection_name"; Property = "ConnectionName"; Type = "string" }
    @{ Param = "mac_address"; Property = "MacAddress"; Type = "string" }
    @{ Param = "max_bandwidth_mbps"; Property = "MaxBandwidth"; Type = "int" }
    @{ Param = "logical_networks"; Property = "LogicalNetworks"; Type = "name_list" }
)

$module.Result.network_adapters = @($adapters | ForEach-Object {
        $result = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
        $result['ip_addresses'] = if ($_.IPAddresses) {
            @($_.IPAddresses | ForEach-Object { $_.ToString() })
        }
        else { @() }
        $result['vm_host'] = if ($null -ne $_.VMHost) { $_.VMHost.FQDN } else { $null }
        $result
    })

$module.ExitJson()
