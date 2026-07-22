#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        description = @{ type = 'str' }
        minimum_bandwidth_mode = @{
            type = 'str'
            choices = @('Weight', 'Absolute', 'Default', 'None')
        }
        enable_sriov = @{ type = 'bool' }
        enable_packet_direct = @{ type = 'bool' }
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

function Get-SwitchResult {
    param($Switch)
    return @{
        id                      = $Switch.ID.ToString()
        name                    = $Switch.Name
        description             = $Switch.Description
        minimum_bandwidth_mode  = $Switch.MinimumBandwidthMode.ToString()
        enable_sriov            = $Switch.EnableSriov
        enable_packet_direct    = $Switch.EnablePacketDirect
    }
}

$logicalSwitch = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCLogicalSwitch' -Name $module.Params.name `
    -ObjectType 'logical switch'

if ($module.Params.state -eq 'present') {
    if (-not $logicalSwitch) {
        $module.Diff.before = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                $newParams = @{
                    VMMServer   = $vmmConnection
                    Name        = $module.Params.name
                    ErrorAction = 'Stop'
                }
                if ($null -ne $module.Params.description) {
                    $newParams['Description'] = $module.Params.description
                }
                if ($null -ne $module.Params.minimum_bandwidth_mode) {
                    $newParams['MinimumBandwidthMode'] = $module.Params.minimum_bandwidth_mode
                }
                if ($null -ne $module.Params.enable_sriov) {
                    $newParams['EnableSriov'] = $module.Params.enable_sriov
                }
                if ($null -ne $module.Params.enable_packet_direct) {
                    $newParams['EnablePacketDirect'] = $module.Params.enable_packet_direct
                }
                $logicalSwitch = New-SCLogicalSwitch @newParams
            }
            catch {
                $module.FailJson("Failed to create logical switch '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
    }
    else {
        $needsUpdate = $false
        $updateParams = @{}

        if ($null -ne $module.Params.description -and $module.Params.description -ne $logicalSwitch.Description) {
            $needsUpdate = $true
            $updateParams['Description'] = $module.Params.description
        }
        if ($null -ne $module.Params.minimum_bandwidth_mode -and $module.Params.minimum_bandwidth_mode -ne $logicalSwitch.MinimumBandwidthMode.ToString()) {
            $needsUpdate = $true
            $updateParams['MinimumBandwidthMode'] = $module.Params.minimum_bandwidth_mode
        }
        if ($null -ne $module.Params.enable_sriov -and $module.Params.enable_sriov -ne $logicalSwitch.EnableSriov) {
            $needsUpdate = $true
            $updateParams['EnableSriov'] = $module.Params.enable_sriov
        }
        if ($null -ne $module.Params.enable_packet_direct -and $module.Params.enable_packet_direct -ne $logicalSwitch.EnablePacketDirect) {
            $needsUpdate = $true
            $updateParams['EnablePacketDirect'] = $module.Params.enable_packet_direct
        }

        if ($needsUpdate) {
            $module.Diff.before = Get-SwitchResult -Switch $logicalSwitch
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                $updateParams['LogicalSwitch'] = $logicalSwitch
                $updateParams['ErrorAction'] = 'Stop'
                try {
                    $logicalSwitch = Set-SCLogicalSwitch @updateParams
                }
                catch {
                    $module.FailJson("Failed to update logical switch '$($module.Params.name)': $($_.Exception.Message)", $_)
                }
            }
        }
    }

    if ($logicalSwitch) {
        $module.Result.logical_switch = Get-SwitchResult -Switch $logicalSwitch
        if ($module.Result.changed -and $module.Diff.before) {
            $module.Diff.after = $module.Result.logical_switch
        }
    }
    elseif ($module.CheckMode) {
        $module.Result.logical_switch = @{
            name                    = $module.Params.name
            description             = $module.Params.description
            minimum_bandwidth_mode  = $module.Params.minimum_bandwidth_mode
            enable_sriov            = $module.Params.enable_sriov
            enable_packet_direct    = $module.Params.enable_packet_direct
        }
        $module.Diff.after = $module.Result.logical_switch
    }
}
else {
    if ($logicalSwitch) {
        $module.Diff.before = Get-SwitchResult -Switch $logicalSwitch
        $module.Diff.after = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                Remove-SCLogicalSwitch -LogicalSwitch $logicalSwitch -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove logical switch '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
