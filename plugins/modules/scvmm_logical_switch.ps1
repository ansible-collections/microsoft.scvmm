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

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "minimum_bandwidth_mode"; Property = "MinimumBandwidthMode"; Type = "enum" }
    @{ Param = "enable_sriov"; Property = "EnableSriov"; Type = "bool" }
    @{ Param = "enable_packet_direct"; Property = "EnablePacketDirect"; Type = "bool" }
)

$updateMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "minimum_bandwidth_mode"; Property = "MinimumBandwidthMode"; Type = "enum" }
    @{ Param = "enable_sriov"; Property = "EnableSriov"; Type = "bool" }
    @{ Param = "enable_packet_direct"; Property = "EnablePacketDirect"; Type = "bool" }
)

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
                    VMMServer = $vmmConnection
                    Name = $module.Params.name
                    ErrorAction = 'Stop'
                }
                $createParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap -AnsibleParams $module.Params
                foreach ($key in $createParams.Keys) {
                    $newParams[$key] = $createParams[$key]
                }
                $logicalSwitch = New-SCLogicalSwitch @newParams
                $module.Result.logical_switch = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $logicalSwitch
                $module.Diff.after = $module.Result.logical_switch
            }
            catch {
                $module.FailJson("Failed to create logical switch '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
        else {
            $module.Result.logical_switch = @{
                id = $null
                name = $module.Params.name
                description = $module.Params.description
                minimum_bandwidth_mode = $module.Params.minimum_bandwidth_mode
                enable_sriov = $module.Params.enable_sriov
                enable_packet_direct = $module.Params.enable_packet_direct
            }
            $module.Diff.after = $module.Result.logical_switch
        }
    }
    else {
        $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $logicalSwitch

        $needsUpdate = Test-SCVMMPropertiesChanged -PropertyMap $updateMap `
            -CurrentObject $logicalSwitch -AnsibleParams $module.Params

        if ($needsUpdate) {
            $setParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap `
                -AnsibleParams $module.Params -CurrentObject $logicalSwitch
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                $setParams['LogicalSwitch'] = $logicalSwitch
                $setParams['ErrorAction'] = 'Stop'
                try {
                    $logicalSwitch = Set-SCLogicalSwitch @setParams
                }
                catch {
                    $module.FailJson("Failed to update logical switch '$($module.Params.name)': $($_.Exception.Message)", $_)
                }
            }
        }

        $module.Result.logical_switch = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $logicalSwitch
        if ($needsUpdate -and $module.CheckMode) {
            $module.Diff.after = Get-SCVMMCheckModeDiff -Before $module.Diff.before `
                -UpdateMap $updateMap -AnsibleParams $module.Params `
                -CurrentObject $logicalSwitch
        }
        else {
            $module.Diff.after = $module.Result.logical_switch
        }
    }
}
else {
    if ($logicalSwitch) {
        $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $logicalSwitch
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
