#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        logical_network = @{ type = 'str' }
        subnet_vlans = @{
            type = 'list'
            elements = 'dict'
            options = @{
                subnet = @{ type = 'str'; required = $true }
                vlan_id = @{ type = 'int'; default = 0 }
            }
        }
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
    required_if = @(
        , @('state', 'present', @('logical_network'))
    )
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

function Get-DefinitionResult {
    param($Definition)
    $result = @{
        id = $Definition.ID.ToString()
        name = $Definition.Name
        logical_network = $Definition.LogicalNetwork.Name
    }
    $result.subnet_vlans = @($Definition.SubnetVLans | ForEach-Object {
            @{
                subnet = $_.Subnet
                vlan_id = [int]$_.VLanID
            }
        })
    $result.host_groups = @($Definition.HostGroups | ForEach-Object { $_.Name })
    return $result
}

$definition = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCLogicalNetworkDefinition' -Name $module.Params.name `
    -ObjectType 'logical network definition'

if ($module.Params.state -eq 'present') {
    if (-not $definition) {
        if (-not $module.Params.subnet_vlans) {
            $module.FailJson("subnet_vlans is required when creating a new logical network definition")
        }
        if (-not $module.Params.host_groups) {
            $module.FailJson("host_groups is required when creating a new logical network definition")
        }

        $module.Diff.before = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                $logicalNetwork = Get-SCLogicalNetwork -VMMServer $vmmConnection -Name $module.Params.logical_network -ErrorAction Stop
                if (-not $logicalNetwork) {
                    $module.FailJson("Logical network '$($module.Params.logical_network)' not found")
                }

                $subnetVLans = @($module.Params.subnet_vlans | ForEach-Object {
                        New-SCSubnetVLan -Subnet $_.subnet -VLanID $_.vlan_id
                    })

                $hostGroups = @($module.Params.host_groups | ForEach-Object {
                        $hg = Get-SCVMHostGroup -VMMServer $vmmConnection -Name $_ -ErrorAction Stop
                        if (-not $hg) {
                            $module.FailJson("Host group '$_' not found")
                        }
                        $hg
                    })

                $newParams = @{
                    Name           = $module.Params.name
                    LogicalNetwork = $logicalNetwork
                    SubnetVLan     = $subnetVLans
                    VMHostGroup    = $hostGroups
                    ErrorAction    = 'Stop'
                }
                $definition = New-SCLogicalNetworkDefinition @newParams
            }
            catch {
                $module.FailJson("Failed to create logical network definition '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
    }
    else {
        $needsUpdate = $false
        $updateParams = @{}

        if ($null -ne $module.Params.subnet_vlans) {
            $currentSubnets = @($definition.SubnetVLans | ForEach-Object { "$($_.Subnet):$($_.VLanID)" }) | Sort-Object
            $desiredSubnets = @($module.Params.subnet_vlans | ForEach-Object { "$($_.subnet):$($_.vlan_id)" }) | Sort-Object
            $diff = Compare-Object -ReferenceObject $currentSubnets -DifferenceObject $desiredSubnets -ErrorAction SilentlyContinue
            if ($diff) {
                $needsUpdate = $true
                $updateParams['SubnetVLan'] = @($module.Params.subnet_vlans | ForEach-Object {
                        New-SCSubnetVLan -Subnet $_.subnet -VLanID $_.vlan_id
                    })
            }
        }

        if ($null -ne $module.Params.host_groups) {
            $currentGroups = @($definition.HostGroups | ForEach-Object { $_.Name }) | Sort-Object
            $desiredGroups = @($module.Params.host_groups) | Sort-Object
            $diff = Compare-Object -ReferenceObject $currentGroups -DifferenceObject $desiredGroups -ErrorAction SilentlyContinue
            if ($diff) {
                $needsUpdate = $true
                $toAdd = @($desiredGroups | Where-Object { $_ -notin $currentGroups })
                $toRemove = @($currentGroups | Where-Object { $_ -notin $desiredGroups })
                if ($toAdd.Count -gt 0) {
                    $updateParams['AddVMHostGroup'] = @($toAdd | ForEach-Object {
                            Get-SCVMHostGroup -VMMServer $vmmConnection -Name $_ -ErrorAction Stop
                        })
                }
                if ($toRemove.Count -gt 0) {
                    $updateParams['RemoveVMHostGroup'] = @($toRemove | ForEach-Object {
                            Get-SCVMHostGroup -VMMServer $vmmConnection -Name $_ -ErrorAction Stop
                        })
                }
            }
        }

        if ($needsUpdate) {
            $module.Diff.before = Get-DefinitionResult -Definition $definition
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                $updateParams['LogicalNetworkDefinition'] = $definition
                $updateParams['ErrorAction'] = 'Stop'
                try {
                    $definition = Set-SCLogicalNetworkDefinition @updateParams
                }
                catch {
                    $module.FailJson("Failed to update logical network definition '$($module.Params.name)': $($_.Exception.Message)", $_)
                }
            }
        }
    }

    if ($definition) {
        $module.Result.logical_network_definition = Get-DefinitionResult -Definition $definition
        if ($module.Result.changed -and $module.Diff.before) {
            $module.Diff.after = $module.Result.logical_network_definition
        }
    }
    elseif ($module.CheckMode) {
        $module.Result.logical_network_definition = @{
            name            = $module.Params.name
            logical_network = $module.Params.logical_network
        }
        $module.Diff.after = $module.Result.logical_network_definition
    }
}
else {
    if ($definition) {
        $module.Diff.before = Get-DefinitionResult -Definition $definition
        $module.Diff.after = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                Remove-SCLogicalNetworkDefinition -LogicalNetworkDefinition $definition -Force -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove logical network definition '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
