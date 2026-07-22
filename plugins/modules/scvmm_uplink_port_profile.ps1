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

function Get-ProfileResult {
    param($Profile)
    $result = @{
        id                           = $Profile.ID.ToString()
        name                         = $Profile.Name
        description                  = $Profile.Description
        enable_network_virtualization = [bool]$Profile.EnableNetworkVirtualization
    }
    $result.logical_network_definitions = @($Profile.LogicalNetworkDefinitions | ForEach-Object { $_.Name })
    return $result
}

$profile = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCNativeUplinkPortProfile' -Name $module.Params.name `
    -ObjectType 'uplink port profile'

if ($module.Params.state -eq 'present') {
    if (-not $profile) {
        $module.Diff.before = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                $newParams = @{
                    Name        = $module.Params.name
                    VMMServer   = $vmmConnection
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
                $profile = New-SCNativeUplinkPortProfile @newParams
            }
            catch {
                $module.FailJson("Failed to create uplink port profile '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
    }
    else {
        $needsUpdate = $false
        $updateParams = @{}

        if ($null -ne $module.Params.description -and $module.Params.description -ne $profile.Description) {
            $needsUpdate = $true
            $updateParams['Description'] = $module.Params.description
        }

        if ($null -ne $module.Params.enable_network_virtualization -and
            [bool]$module.Params.enable_network_virtualization -ne [bool]$profile.EnableNetworkVirtualization) {
            $needsUpdate = $true
            $updateParams['EnableNetworkVirtualization'] = $module.Params.enable_network_virtualization
        }

        if ($null -ne $module.Params.logical_network_definitions) {
            $currentDefs = @($profile.LogicalNetworkDefinitions | ForEach-Object { $_.Name }) | Sort-Object
            $desiredDefs = @($module.Params.logical_network_definitions) | Sort-Object
            $diff = Compare-Object -ReferenceObject $currentDefs -DifferenceObject $desiredDefs -ErrorAction SilentlyContinue
            if ($diff) {
                $needsUpdate = $true
                $toAdd = @($desiredDefs | Where-Object { $_ -notin $currentDefs })
                $toRemove = @($currentDefs | Where-Object { $_ -notin $desiredDefs })
                if ($toAdd.Count -gt 0) {
                    $updateParams['AddLogicalNetworkDefinition'] = @($toAdd | ForEach-Object {
                            Get-SCLogicalNetworkDefinition -VMMServer $vmmConnection -Name $_ -ErrorAction Stop
                        })
                }
                if ($toRemove.Count -gt 0) {
                    $updateParams['RemoveLogicalNetworkDefinition'] = @($toRemove | ForEach-Object {
                            Get-SCLogicalNetworkDefinition -VMMServer $vmmConnection -Name $_ -ErrorAction Stop
                        })
                }
            }
        }

        if ($needsUpdate) {
            $module.Diff.before = Get-ProfileResult -Profile $profile
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                $updateParams['NativeUplinkPortProfile'] = $profile
                $updateParams['ErrorAction'] = 'Stop'
                try {
                    $profile = Set-SCNativeUplinkPortProfile @updateParams
                }
                catch {
                    $module.FailJson("Failed to update uplink port profile '$($module.Params.name)': $($_.Exception.Message)", $_)
                }
            }
        }
    }

    if ($profile) {
        $module.Result.uplink_port_profile = Get-ProfileResult -Profile $profile
        if ($module.Result.changed -and $module.Diff.before) {
            $module.Diff.after = $module.Result.uplink_port_profile
        }
    }
    elseif ($module.CheckMode) {
        $module.Result.uplink_port_profile = @{
            name        = $module.Params.name
            description = $module.Params.description
        }
        $module.Diff.after = $module.Result.uplink_port_profile
    }
}
else {
    if ($profile) {
        $module.Diff.before = Get-ProfileResult -Profile $profile
        $module.Diff.after = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                Remove-SCNativeUplinkPortProfile -NativeUplinkPortProfile $profile -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove uplink port profile '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
