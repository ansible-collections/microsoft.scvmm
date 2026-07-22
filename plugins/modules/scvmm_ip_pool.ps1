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

$updateMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "dns_suffix"; Property = "DNSSuffix"; Type = "string" }
)

function Get-PoolResult {
    param($Pool)
    $result = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $Pool
    $result['default_gateways'] = @($Pool.DefaultGateways | ForEach-Object { $_.IPAddress })
    $result['dns_servers'] = @($Pool.DNSServers)
    $result['dns_search_suffixes'] = @($Pool.DNSSearchSuffixes)
    return $result
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
                $module.Result.ip_pool = Get-PoolResult -Pool $pool
                $module.Diff.after = $module.Result.ip_pool
            }
            catch {
                $module.FailJson("Failed to create IP address pool '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
        else {
            $module.Result.ip_pool = @{
                id = $null
                name = $module.Params.name
                description = $module.Params.description
                subnet = $module.Params.subnet
                ip_address_range_start = $module.Params.ip_address_range_start
                ip_address_range_end = $module.Params.ip_address_range_end
                default_gateways = if ($module.Params.default_gateways) { @($module.Params.default_gateways) } else { @() }
                dns_servers = if ($module.Params.dns_servers) { @($module.Params.dns_servers) } else { @() }
                dns_suffix = $module.Params.dns_suffix
                dns_search_suffixes = if ($module.Params.dns_search_suffixes) { @($module.Params.dns_search_suffixes) } else { @() }
                logical_network_definition = $module.Params.logical_network_definition
            }
            $module.Diff.after = $module.Result.ip_pool
        }
    }
    else {
        $module.Diff.before = Get-PoolResult -Pool $pool

        $needsUpdate = Test-SCVMMPropertiesChanged -PropertyMap $updateMap `
            -CurrentObject $pool -AnsibleParams $module.Params
        $setParams = @{}

        if ($needsUpdate) {
            $setParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap `
                -AnsibleParams $module.Params -CurrentObject $pool
        }

        if ($null -ne $module.Params.dns_servers) {
            $current = @($pool.DNSServers) -join ','
            $desired = @($module.Params.dns_servers) -join ','
            if ($current -ne $desired) {
                $needsUpdate = $true
                $setParams['DNSServer'] = $module.Params.dns_servers
            }
        }
        if ($null -ne $module.Params.default_gateways) {
            $current = @($pool.DefaultGateways | ForEach-Object { $_.IPAddress }) -join ','
            $desired = @($module.Params.default_gateways) -join ','
            if ($current -ne $desired) {
                $needsUpdate = $true
                $setParams['DefaultGateway'] = @($module.Params.default_gateways | ForEach-Object {
                        New-SCDefaultGateway -IPAddress $_ -ErrorAction Stop
                    })
            }
        }

        if ($needsUpdate) {
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                $setParams['StaticIPAddressPool'] = $pool
                $setParams['ErrorAction'] = 'Stop'
                try {
                    $pool = Set-SCStaticIPAddressPool @setParams
                }
                catch {
                    $module.FailJson("Failed to update IP address pool '$($module.Params.name)': $($_.Exception.Message)", $_)
                }
            }
        }

        $module.Result.ip_pool = Get-PoolResult -Pool $pool
        if ($needsUpdate -and $module.CheckMode) {
            $projected = Get-SCVMMCheckModeDiff -Before $module.Diff.before `
                -UpdateMap $updateMap -AnsibleParams $module.Params `
                -CurrentObject $pool
            if ($null -ne $module.Params.dns_servers) {
                $projected['dns_servers'] = @($module.Params.dns_servers)
            }
            if ($null -ne $module.Params.default_gateways) {
                $projected['default_gateways'] = @($module.Params.default_gateways)
            }
            $module.Diff.after = $projected
        }
        else {
            $module.Diff.after = $module.Result.ip_pool
        }
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
