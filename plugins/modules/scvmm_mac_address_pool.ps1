#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        description = @{ type = 'str' }
        mac_address_range_start = @{ type = 'str' }
        mac_address_range_end = @{ type = 'str' }
        host_groups = @{
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
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

function Get-PoolResult {
    param($Pool)
    return @{
        id                      = $Pool.ID.ToString()
        name                    = $Pool.Name
        description             = $Pool.Description
        mac_address_range_start = $Pool.MACAddressRangeStart
        mac_address_range_end   = $Pool.MACAddressRangeEnd
        host_groups             = @($Pool.HostGroups | ForEach-Object { $_.Name })
    }
}

$pool = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCMACAddressPool' -Name $module.Params.name `
    -ObjectType 'MAC address pool'

if ($module.Params.state -eq 'present') {
    if (-not $pool) {
        if (-not $module.Params.mac_address_range_start) {
            $module.FailJson("mac_address_range_start is required when creating a new MAC address pool")
        }
        if (-not $module.Params.mac_address_range_end) {
            $module.FailJson("mac_address_range_end is required when creating a new MAC address pool")
        }
        if (-not $module.Params.host_groups) {
            $module.FailJson("host_groups is required when creating a new MAC address pool")
        }

        $module.Diff.before = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                $hostGroups = @($module.Params.host_groups | ForEach-Object {
                        $hg = Get-SCVMHostGroup -VMMServer $vmmConnection -Name $_ -ErrorAction Stop
                        if (-not $hg) { $module.FailJson("Host group '$_' not found") }
                        $hg
                    })

                $newParams = @{
                    Name                 = $module.Params.name
                    MACAddressRangeStart = $module.Params.mac_address_range_start
                    MACAddressRangeEnd   = $module.Params.mac_address_range_end
                    VMHostGroup          = $hostGroups
                    VMMServer            = $vmmConnection
                    ErrorAction          = 'Stop'
                }
                if ($null -ne $module.Params.description) {
                    $newParams['Description'] = $module.Params.description
                }
                $pool = New-SCMACAddressPool @newParams
            }
            catch {
                $module.FailJson("Failed to create MAC address pool '$($module.Params.name)': $($_.Exception.Message)", $_)
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

        if ($needsUpdate) {
            $module.Diff.before = Get-PoolResult -Pool $pool
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                $updateParams['MACAddressPool'] = $pool
                $updateParams['ErrorAction'] = 'Stop'
                try {
                    $pool = Set-SCMACAddressPool @updateParams
                }
                catch {
                    $module.FailJson("Failed to update MAC address pool '$($module.Params.name)': $($_.Exception.Message)", $_)
                }
            }
        }
    }

    if ($pool) {
        $module.Result.mac_address_pool = Get-PoolResult -Pool $pool
        if ($module.Result.changed -and $module.Diff.before) {
            $module.Diff.after = $module.Result.mac_address_pool
        }
    }
    elseif ($module.CheckMode) {
        $module.Result.mac_address_pool = @{
            name                    = $module.Params.name
            description             = $module.Params.description
            mac_address_range_start = $module.Params.mac_address_range_start
            mac_address_range_end   = $module.Params.mac_address_range_end
        }
        $module.Diff.after = $module.Result.mac_address_pool
    }
}
else {
    if ($pool) {
        $module.Diff.before = Get-PoolResult -Pool $pool
        $module.Diff.after = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                Remove-SCMACAddressPool -MACAddressPool $pool -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove MAC address pool '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
