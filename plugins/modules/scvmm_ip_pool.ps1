#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        description = @{ type = 'str' }
        logical_network_definition = @{ type = 'str' }
        subnet = @{ type = 'str' }
        ip_address_range_start = @{ type = 'str' }
        ip_address_range_end = @{ type = 'str' }
        default_gateways = @{
            type = 'list'
            elements = 'str'
        }
        dns_servers = @{
            type = 'list'
            elements = 'str'
        }
        dns_suffix = @{ type = 'str' }
        dns_search_suffixes = @{
            type = 'list'
            elements = 'str'
        }
        state = @{
            type = 'str'
            default = 'present'
            choices = @('present', 'absent')
        }
        vmm_server = @{ type = 'str' }
    }
    required_if = @(
        , @('state', 'present', @('logical_network_definition', 'subnet'))
    )
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

function Get-PoolResult {
    param($Pool)
    return @{
        id = $Pool.ID.ToString()
        name = $Pool.Name
        description = $Pool.Description
        subnet = $Pool.Subnet
        ip_address_range_start = $Pool.IPAddressRangeStart
        ip_address_range_end = $Pool.IPAddressRangeEnd
        default_gateways = @($Pool.DefaultGateways | ForEach-Object { $_.IPAddress })
        dns_servers = @($Pool.DNSServers)
        dns_suffix = $Pool.DNSSuffix
        dns_search_suffixes = @($Pool.DNSSearchSuffixes)
        logical_network_definition = if ($Pool.LogicalNetworkDefinition) { $Pool.LogicalNetworkDefinition.Name } else { $null }
    }
}

$pool = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCStaticIPAddressPool' -Name $module.Params.name `
    -ObjectType 'IP address pool'

if ($module.Params.state -eq 'present') {
    if (-not $pool) {
        $module.Diff.before = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                $lnd = Get-SCLogicalNetworkDefinition -VMMServer $vmmConnection -Name $module.Params.logical_network_definition -ErrorAction Stop
                if (-not $lnd) {
                    $module.FailJson("Logical network definition '$($module.Params.logical_network_definition)' not found")
                }

                $newParams = @{
                    VMMServer = $vmmConnection
                    Name = $module.Params.name
                    LogicalNetworkDefinition = $lnd
                    Subnet = $module.Params.subnet
                    ErrorAction = 'Stop'
                }
                if ($null -ne $module.Params.description) {
                    $newParams['Description'] = $module.Params.description
                }
                if ($null -ne $module.Params.ip_address_range_start) {
                    $newParams['IPAddressRangeStart'] = $module.Params.ip_address_range_start
                }
                if ($null -ne $module.Params.ip_address_range_end) {
                    $newParams['IPAddressRangeEnd'] = $module.Params.ip_address_range_end
                }
                if ($null -ne $module.Params.default_gateways) {
                    $newParams['DefaultGateway'] = @($module.Params.default_gateways | ForEach-Object {
                            New-SCDefaultGateway -IPAddress $_ -ErrorAction Stop
                        })
                }
                if ($null -ne $module.Params.dns_servers) {
                    $newParams['DNSServer'] = $module.Params.dns_servers
                }
                if ($null -ne $module.Params.dns_suffix) {
                    $newParams['DNSSuffix'] = $module.Params.dns_suffix
                }
                if ($null -ne $module.Params.dns_search_suffixes) {
                    $newParams['DNSSearchSuffix'] = $module.Params.dns_search_suffixes
                }

                $pool = New-SCStaticIPAddressPool @newParams
            }
            catch {
                $module.FailJson("Failed to create IP address pool '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
    }
    else {
        $needsUpdate = $false
        $updateParams = @{}

        if ($null -ne $module.Params.description -and $module.Params.description -ne $pool.Description) {
            $needsUpdate = $true
            $updateParams['Description'] = $module.Params.description
        }
        if ($null -ne $module.Params.dns_servers) {
            $current = @($pool.DNSServers) -join ','
            $desired = @($module.Params.dns_servers) -join ','
            if ($current -ne $desired) {
                $needsUpdate = $true
                $updateParams['DNSServer'] = $module.Params.dns_servers
            }
        }
        if ($null -ne $module.Params.dns_suffix -and $module.Params.dns_suffix -ne $pool.DNSSuffix) {
            $needsUpdate = $true
            $updateParams['DNSSuffix'] = $module.Params.dns_suffix
        }
        if ($null -ne $module.Params.default_gateways) {
            $current = @($pool.DefaultGateways | ForEach-Object { $_.IPAddress }) -join ','
            $desired = @($module.Params.default_gateways) -join ','
            if ($current -ne $desired) {
                $needsUpdate = $true
                $updateParams['DefaultGateway'] = @($module.Params.default_gateways | ForEach-Object {
                        New-SCDefaultGateway -IPAddress $_ -ErrorAction Stop
                    })
            }
        }

        if ($needsUpdate) {
            $module.Diff.before = Get-PoolResult -Pool $pool
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                $updateParams['StaticIPAddressPool'] = $pool
                $updateParams['ErrorAction'] = 'Stop'
                try {
                    $pool = Set-SCStaticIPAddressPool @updateParams
                }
                catch {
                    $module.FailJson("Failed to update IP address pool '$($module.Params.name)': $($_.Exception.Message)", $_)
                }
            }
        }
    }

    if ($pool) {
        $module.Result.ip_pool = Get-PoolResult -Pool $pool
        if ($module.Result.changed -and $module.Diff.before) {
            $module.Diff.after = $module.Result.ip_pool
        }
    }
    elseif ($module.CheckMode) {
        $module.Result.ip_pool = @{
            id = $null
            name = $module.Params.name
            description = $module.Params.description
            subnet = $module.Params.subnet
            logical_network_definition = $module.Params.logical_network_definition
        }
        $module.Diff.after = $module.Result.ip_pool
    }
}
else {
    if ($pool) {
        $module.Diff.before = Get-PoolResult -Pool $pool
        $module.Diff.after = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                Remove-SCStaticIPAddressPool -StaticIPAddressPool $pool -Force -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove IP address pool '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
