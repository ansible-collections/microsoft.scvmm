#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str' }
        logical_network_definition = @{ type = 'str' }
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
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "subnet"; Property = "Subnet"; Type = "string" }
    @{ Param = "ip_address_range_start"; Property = "IPAddressRangeStart"; Type = "string" }
    @{ Param = "ip_address_range_end"; Property = "IPAddressRangeEnd"; Type = "string" }
    @{ Param = "dns_suffix"; Property = "DNSSuffix"; Type = "string" }
    @{ Param = "logical_network_definition"; Property = "LogicalNetworkDefinition"; Type = "nested_name" }
)

if ($module.Params.logical_network_definition) {
    $lnd = Get-SCLogicalNetworkDefinition -VMMServer $vmmConnection -Name $module.Params.logical_network_definition -ErrorAction Stop
    if (-not $lnd) {
        $module.Result.ip_pools = @()
        $module.ExitJson()
    }
    $pools = Get-SCStaticIPAddressPool -VMMServer $vmmConnection -LogicalNetworkDefinition $lnd -ErrorAction Stop
    if ($module.Params.name) {
        $pools = @($pools | Where-Object { $_.Name -eq $module.Params.name })
    }
}
else {
    $pools = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCStaticIPAddressPool' -Name $module.Params.name `
        -ObjectType 'IP address pool'
    if ($module.Params.name) {
        $pools = if ($pools) { @($pools) } else { @() }
    }
}

$module.Result.ip_pools = @($pools | ForEach-Object {
        $result = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
        $result['default_gateways'] = @($_.DefaultGateways | ForEach-Object { $_.IPAddress })
        $result['dns_servers'] = @($_.DNSServers)
        $result['dns_search_suffixes'] = @($_.DNSSearchSuffixes)
        $result
    })

$module.ExitJson()
