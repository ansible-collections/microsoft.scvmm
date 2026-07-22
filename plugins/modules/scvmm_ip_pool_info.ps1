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
        @{
            id = $_.ID.ToString()
            name = $_.Name
            description = $_.Description
            subnet = $_.Subnet
            ip_address_range_start = $_.IPAddressRangeStart
            ip_address_range_end = $_.IPAddressRangeEnd
            default_gateways = @($_.DefaultGateways | ForEach-Object { $_.IPAddress })
            dns_servers = @($_.DNSServers)
            dns_suffix = $_.DNSSuffix
            dns_search_suffixes = @($_.DNSSearchSuffixes)
            logical_network_definition = if ($_.LogicalNetworkDefinition) { $_.LogicalNetworkDefinition.Name } else { $null }
        }
    })

$module.ExitJson()
