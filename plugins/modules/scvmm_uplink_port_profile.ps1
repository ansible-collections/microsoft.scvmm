#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        description = @{ type = 'str' }
        enable_network_virtualization = @{ type = 'bool' }
        logical_network_definitions = @{
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

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "enable_network_virtualization"; Property = "EnableNetworkVirtualization"; Type = "bool" }
)

$updateMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "enable_network_virtualization"; Property = "EnableNetworkVirtualization"; Type = "bool" }
)

function Get-ProfileResult {
    param($UplinkProfile)
    $result = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $UplinkProfile
    $result['logical_network_definitions'] = @($UplinkProfile.LogicalNetworkDefinitions | ForEach-Object { $_.Name })
    return $result
}

$uplinkProfile = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCNativeUplinkPortProfile' -Name $module.Params.name `
    -ObjectType 'uplink port profile'

if ($module.Params.state -eq 'present') {
    if (-not $uplinkProfile) {
        $module.Diff.before = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                $newParams = @{
                    Name = $module.Params.name
                    VMMServer = $vmmConnection
                    ErrorAction = 'Stop'
                }
                if ($null -ne $module.Params.description) {
                    $newParams['Description'] = $module.Params.description
                }
                if ($null -ne $module.Params.enable_network_virtualization) {
                    $newParams['EnableNetworkVirtualization'] = $module.Params.enable_network_virtualization
                }
                if ($null -ne $module.Params.logical_network_definitions -and $module.Params.logical_network_definitions.Count -gt 0) {
                    $lnDefs = @($module.Params.logical_network_definitions | ForEach-Object {
                            $def = Get-SCLogicalNetworkDefinition -VMMServer $vmmConnection -Name $_ -ErrorAction Stop
                            if (-not $def) {
                                $module.FailJson("Logical network definition '$_' not found")
                            }
                            $def
                        })
                    $newParams['LogicalNetworkDefinition'] = $lnDefs
                }
                $uplinkProfile = New-SCNativeUplinkPortProfile @newParams
                $module.Result.uplink_port_profile = Get-ProfileResult -UplinkProfile $uplinkProfile
                $module.Diff.after = $module.Result.uplink_port_profile
            }
            catch {
                $module.FailJson("Failed to create uplink port profile '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
        else {
            $module.Result.uplink_port_profile = @{
                id = $null
                name = $module.Params.name
                description = $module.Params.description
                enable_network_virtualization = $module.Params.enable_network_virtualization
                logical_network_definitions = if ($module.Params.logical_network_definitions) { @($module.Params.logical_network_definitions) } else { @() }
            }
            $module.Diff.after = $module.Result.uplink_port_profile
        }
    }
    else {
        $module.Diff.before = Get-ProfileResult -UplinkProfile $uplinkProfile

        $needsUpdate = Test-SCVMMPropertiesChanged -PropertyMap $updateMap `
            -CurrentObject $uplinkProfile -AnsibleParams $module.Params
        $setParams = @{}

        if ($needsUpdate) {
            $setParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap `
                -AnsibleParams $module.Params -CurrentObject $uplinkProfile
        }

        $toAdd = @()
        $toRemove = @()
        if ($null -ne $module.Params.logical_network_definitions) {
            $currentDefs = @($uplinkProfile.LogicalNetworkDefinitions | ForEach-Object { $_.Name }) | Sort-Object
            $desiredDefs = @($module.Params.logical_network_definitions) | Sort-Object
            if ($currentDefs.Count -eq 0 -and $desiredDefs.Count -gt 0) {
                $toAdd = $desiredDefs
            }
            elseif ($currentDefs.Count -gt 0 -and $desiredDefs.Count -eq 0) {
                $toRemove = $currentDefs
            }
            elseif ($currentDefs.Count -gt 0 -and $desiredDefs.Count -gt 0) {
                $diff = Compare-Object -ReferenceObject $currentDefs -DifferenceObject $desiredDefs -ErrorAction SilentlyContinue
                if ($diff) {
                    $toAdd = @($desiredDefs | Where-Object { $_ -notin $currentDefs })
                    $toRemove = @($currentDefs | Where-Object { $_ -notin $desiredDefs })
                }
            }
            if ($toAdd.Count -gt 0 -or $toRemove.Count -gt 0) {
                $needsUpdate = $true
                if ($toAdd.Count -gt 0) {
                    $setParams['AddLogicalNetworkDefinition'] = @($toAdd | ForEach-Object {
                            $def = Get-SCLogicalNetworkDefinition -VMMServer $vmmConnection -Name $_ -ErrorAction Stop
                            if (-not $def) {
                                $module.FailJson("Logical network definition '$_' not found")
                            }
                            $def
                        })
                }
                if ($toRemove.Count -gt 0) {
                    $setParams['RemoveLogicalNetworkDefinition'] = @($toRemove | ForEach-Object {
                            $def = Get-SCLogicalNetworkDefinition -VMMServer $vmmConnection -Name $_ -ErrorAction Stop
                            if (-not $def) {
                                $module.FailJson("Logical network definition '$_' not found")
                            }
                            $def
                        })
                }
            }
        }

        if ($needsUpdate) {
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                $setParams['NativeUplinkPortProfile'] = $uplinkProfile
                $setParams['ErrorAction'] = 'Stop'
                try {
                    $uplinkProfile = Set-SCNativeUplinkPortProfile @setParams
                }
                catch {
                    $module.FailJson("Failed to update uplink port profile '$($module.Params.name)': $($_.Exception.Message)", $_)
                }
            }
        }

        $module.Result.uplink_port_profile = Get-ProfileResult -UplinkProfile $uplinkProfile
        if ($needsUpdate -and $module.CheckMode) {
            $projected = Get-SCVMMCheckModeDiff -Before $module.Diff.before `
                -UpdateMap $updateMap -AnsibleParams $module.Params `
                -CurrentObject $uplinkProfile
            if ($null -ne $module.Params.logical_network_definitions) {
                $projected['logical_network_definitions'] = @($module.Params.logical_network_definitions)
            }
            $module.Diff.after = $projected
        }
        else {
            $module.Diff.after = $module.Result.uplink_port_profile
        }
    }
}
else {
    if ($uplinkProfile) {
        $module.Diff.before = Get-ProfileResult -UplinkProfile $uplinkProfile
        $module.Diff.after = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                Remove-SCNativeUplinkPortProfile -NativeUplinkPortProfile $uplinkProfile -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove uplink port profile '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
