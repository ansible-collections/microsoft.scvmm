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

$macRegex = '^([0-9A-Fa-f]{2}-){5}[0-9A-Fa-f]{2}$'
if ($null -ne $module.Params.mac_address_range_start -and
    $module.Params.mac_address_range_start -notmatch $macRegex) {
    $module.FailJson("mac_address_range_start must be in format XX-XX-XX-XX-XX-XX (e.g. 00-1D-D8-B7-1C-00)")
}
if ($null -ne $module.Params.mac_address_range_end -and
    $module.Params.mac_address_range_end -notmatch $macRegex) {
    $module.FailJson("mac_address_range_end must be in format XX-XX-XX-XX-XX-XX (e.g. 00-1D-D8-F4-1F-FF)")
}

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "mac_address_range_start"; Property = "MACAddressRangeStart"; Type = "string" }
    @{ Param = "mac_address_range_end"; Property = "MACAddressRangeEnd"; Type = "string" }
    @{ Param = "host_groups"; Property = "HostGroups"; Type = "name_list" }
)

$updateMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string" }
)

function Get-PoolResult {
    param($Pool)
    return Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $Pool
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
                        Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
                            -CmdletName 'Get-SCVMHostGroup' -Name $_ `
                            -ObjectType 'Host group' -FailIfNotFound $true
                    })

                $newParams = @{
                    Name = $module.Params.name
                    MACAddressRangeStart = $module.Params.mac_address_range_start
                    MACAddressRangeEnd = $module.Params.mac_address_range_end
                    VMHostGroup = $hostGroups
                    VMMServer = $vmmConnection
                    ErrorAction = 'Stop'
                }
                if ($null -ne $module.Params.description) {
                    $newParams['Description'] = $module.Params.description
                }
                $pool = New-SCMACAddressPool @newParams
                $module.Result.mac_address_pool = Get-PoolResult -Pool $pool
                $module.Diff.after = $module.Result.mac_address_pool
            }
            catch {
                $module.FailJson("Failed to create MAC address pool '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
        else {
            $module.Result.mac_address_pool = @{
                id = $null
                name = $module.Params.name
                description = $module.Params.description
                mac_address_range_start = $module.Params.mac_address_range_start
                mac_address_range_end = $module.Params.mac_address_range_end
                host_groups = if ($module.Params.host_groups) { @($module.Params.host_groups) } else { @() }
            }
            $module.Diff.after = $module.Result.mac_address_pool
        }
    }
    else {
        $module.Diff.before = Get-PoolResult -Pool $pool

        if ($null -ne $module.Params.mac_address_range_start -and
            $pool.MACAddressRangeStart -ne $module.Params.mac_address_range_start) {
            $cur = $pool.MACAddressRangeStart
            $req = $module.Params.mac_address_range_start
            $module.Warn("Cannot change 'mac_address_range_start' after creation (current: '$cur', requested: '$req'). Delete and recreate.")
        }
        if ($null -ne $module.Params.mac_address_range_end -and
            $pool.MACAddressRangeEnd -ne $module.Params.mac_address_range_end) {
            $cur = $pool.MACAddressRangeEnd
            $req = $module.Params.mac_address_range_end
            $module.Warn("Cannot change 'mac_address_range_end' after creation (current: '$cur', requested: '$req'). Delete and recreate.")
        }
        if ($null -ne $module.Params.host_groups) {
            $currentHGs = @($pool.HostGroups | ForEach-Object { $_.Name }) | Sort-Object
            $desiredHGs = @($module.Params.host_groups) | Sort-Object
            $hgChanged = $false
            if ($currentHGs.Count -ne $desiredHGs.Count) {
                $hgChanged = $true
            }
            elseif ($currentHGs.Count -gt 0) {
                $diff = Compare-Object -ReferenceObject $currentHGs -DifferenceObject $desiredHGs
                if ($diff) { $hgChanged = $true }
            }
            if ($hgChanged) {
                $cur = $currentHGs -join ", "
                $req = $desiredHGs -join ", "
                $module.Warn("Cannot change 'host_groups' after creation (current: '$cur', requested: '$req'). Delete and recreate.")
            }
        }

        $needsUpdate = Test-SCVMMPropertiesChanged -PropertyMap $updateMap `
            -CurrentObject $pool -AnsibleParams $module.Params

        if ($needsUpdate) {
            $setParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap `
                -AnsibleParams $module.Params -CurrentObject $pool
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                $setParams['MACAddressPool'] = $pool
                $setParams['ErrorAction'] = 'Stop'
                try {
                    $pool = Set-SCMACAddressPool @setParams
                }
                catch {
                    $module.FailJson("Failed to update MAC address pool '$($module.Params.name)': $($_.Exception.Message)", $_)
                }
            }
        }

        $module.Result.mac_address_pool = Get-PoolResult -Pool $pool
        if ($needsUpdate -and $module.CheckMode) {
            $module.Diff.after = Get-SCVMMCheckModeDiff -Before $module.Diff.before `
                -UpdateMap $updateMap -AnsibleParams $module.Params `
                -CurrentObject $pool
        }
        else {
            $module.Diff.after = $module.Result.mac_address_pool
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
                Remove-SCMACAddressPool -MACAddressPool $pool -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove MAC address pool '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
