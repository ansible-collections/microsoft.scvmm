#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        description = @{ type = 'str' }
        network_virtualization_enabled = @{ type = 'bool' }
        use_gre = @{ type = 'bool' }
        is_pvlan = @{ type = 'bool' }
        definition_isolation = @{ type = 'bool' }
        allow_dynamic_vlan_on_vnic = @{ type = 'bool' }
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
    @{ Param = "network_virtualization_enabled"; Property = "NetworkVirtualizationEnabled"; Type = "bool" }
    @{ Param = "use_gre"; Property = "UseGRE"; Type = "bool" }
    @{ Param = "is_pvlan"; Property = "IsPVLAN"; Type = "bool" }
    @{ Param = "definition_isolation"; Property = "LogicalNetworkDefinitionIsolation"; Type = "bool" }
    @{ Param = "allow_dynamic_vlan_on_vnic"; Property = "AllowDynamicVlanOnVnic"; Type = "bool" }
)

$createMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "network_virtualization_enabled"; Property = "NetworkVirtualizationEnabled"; Type = "bool"; CmdletParam = "EnableNetworkVirtualization" }
    @{ Param = "use_gre"; Property = "UseGRE"; Type = "bool" }
    @{ Param = "is_pvlan"; Property = "IsPVLAN"; Type = "bool" }
    @{ Param = "definition_isolation"; Property = "LogicalNetworkDefinitionIsolation"; Type = "bool" }
    @{ Param = "allow_dynamic_vlan_on_vnic"; Property = "AllowDynamicVlanOnVnic"; Type = "bool" }
)

$updateMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "network_virtualization_enabled"; Property = "NetworkVirtualizationEnabled"; Type = "bool"; CmdletParam = "EnableNetworkVirtualization" }
    @{ Param = "definition_isolation"; Property = "LogicalNetworkDefinitionIsolation"; Type = "bool" }
    @{ Param = "allow_dynamic_vlan_on_vnic"; Property = "AllowDynamicVlanOnVnic"; Type = "bool" }
)

$logicalNetwork = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCLogicalNetwork' -Name $module.Params.name `
    -ObjectType 'logical network'

if ($module.Params.state -eq 'present') {
    if (-not $logicalNetwork) {
        $module.Diff.before = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            $newParams = @{
                Name = $module.Params.name
                VMMServer = $vmmConnection
                ErrorAction = 'Stop'
            }
            $createParams = Get-SCVMMParametersFromMap -PropertyMap $createMap -AnsibleParams $module.Params
            foreach ($key in $createParams.Keys) {
                $newParams[$key] = $createParams[$key]
            }
            try {
                $logicalNetwork = New-SCLogicalNetwork @newParams
                $module.Result.logical_network = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $logicalNetwork
                $module.Diff.after = $module.Result.logical_network
            }
            catch {
                $module.FailJson("Failed to create logical network '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
        else {
            $module.Result.logical_network = @{
                id = $null
                name = $module.Params.name
                description = $module.Params.description
                network_virtualization_enabled = $module.Params.network_virtualization_enabled
                use_gre = $module.Params.use_gre
                is_pvlan = $module.Params.is_pvlan
                definition_isolation = $module.Params.definition_isolation
                allow_dynamic_vlan_on_vnic = $module.Params.allow_dynamic_vlan_on_vnic
            }
            $module.Diff.after = $module.Result.logical_network
        }
    }
    else {
        $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $logicalNetwork

        $updateParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap `
            -AnsibleParams $module.Params -CurrentObject $logicalNetwork
        $needsUpdate = $updateParams.Count -gt 0

        if ($needsUpdate) {
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                $updateParams['LogicalNetwork'] = $logicalNetwork
                $updateParams['ErrorAction'] = 'Stop'
                try {
                    $logicalNetwork = Set-SCLogicalNetwork @updateParams
                }
                catch {
                    $module.FailJson("Failed to update logical network '$($module.Params.name)': $($_.Exception.Message)", $_)
                }
            }
        }

        $module.Result.logical_network = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $logicalNetwork
        if ($needsUpdate -and $module.CheckMode) {
            $module.Diff.after = Get-SCVMMCheckModeDiff -Before $module.Diff.before `
                -UpdateMap $updateMap -AnsibleParams $module.Params -CurrentObject $logicalNetwork
        }
        else {
            $module.Diff.after = $module.Result.logical_network
        }
    }
}
else {
    if ($logicalNetwork) {
        $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $logicalNetwork
        $module.Diff.after = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                Remove-SCLogicalNetwork -LogicalNetwork $logicalNetwork -Force -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove logical network '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
