#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        description = @{ type = 'str' }
        vm_network = @{ type = 'str' }
        subnet = @{ type = 'str' }
        vlan_id = @{ type = 'int'; default = 0 }
        logical_network_definition = @{ type = 'str' }
        state = @{
            type = 'str'
            default = 'present'
            choices = @('present', 'absent')
        }
        vmm_server = @{ type = 'str' }
    }
    required_if = @(
        , @('state', 'present', @('vm_network', 'subnet'))
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
    @{ Param = "vm_network"; Property = "VMNetwork"; Type = "nested_name" }
    @{ Param = "logical_network_definition"; Property = "LogicalNetworkDefinition"; Type = "nested_name" }
)

$updateMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string" }
)

function Get-SubnetResult {
    param($Subnet)
    $result = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $Subnet
    $result['subnet_vlans'] = @($Subnet.SubnetVLans | ForEach-Object {
            @{
                subnet = $_.Subnet
                vlan_id = $_.VLanID
            }
        })
    return $result
}

$vmSubnet = $null
$vmNet = $null
if ($module.Params.vm_network) {
    $vmNet = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCVMNetwork' -Name $module.Params.vm_network `
        -ObjectType 'VM network'
    if ($vmNet) {
        $subnets = @(Get-SCVMSubnet -VMMServer $vmmConnection -VMNetwork $vmNet -ErrorAction Stop)
        $vmSubnet = $subnets | Where-Object { $_.Name -eq $module.Params.name } | Select-Object -First 1
    }
}
else {
    $vmSubnet = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCVMSubnet' -Name $module.Params.name `
        -ObjectType 'VM subnet'
}

if ($module.Params.state -eq 'present') {
    if (-not $vmSubnet) {
        $module.Diff.before = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                if (-not $vmNet) {
                    $vmNet = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
                        -CmdletName 'Get-SCVMNetwork' -Name $module.Params.vm_network `
                        -ObjectType 'VM network' -FailIfNotFound $true
                }

                $subnetVlan = New-SCSubnetVLan -Subnet $module.Params.subnet -VLanID $module.Params.vlan_id

                $newParams = @{
                    VMMServer = $vmmConnection
                    Name = $module.Params.name
                    VMNetwork = $vmNet
                    SubnetVLan = $subnetVlan
                    ErrorAction = 'Stop'
                }
                if ($null -ne $module.Params.description) {
                    $newParams['Description'] = $module.Params.description
                }
                if ($module.Params.logical_network_definition) {
                    $lnd = Get-SCLogicalNetworkDefinition -VMMServer $vmmConnection `
                        -Name $module.Params.logical_network_definition -ErrorAction Stop
                    if (-not $lnd) {
                        $module.FailJson("Logical network definition '$($module.Params.logical_network_definition)' not found")
                    }
                    $newParams['LogicalNetworkDefinition'] = $lnd
                }

                $vmSubnet = New-SCVMSubnet @newParams
                $module.Result.vm_subnet = Get-SubnetResult -Subnet $vmSubnet
                $module.Diff.after = $module.Result.vm_subnet
            }
            catch {
                $module.FailJson("Failed to create VM subnet '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
        else {
            $module.Result.vm_subnet = @{
                id = $null
                name = $module.Params.name
                description = $module.Params.description
                vm_network = $module.Params.vm_network
                subnet_vlans = @(@{ subnet = $module.Params.subnet; vlan_id = $module.Params.vlan_id })
                logical_network_definition = $module.Params.logical_network_definition
            }
            $module.Diff.after = $module.Result.vm_subnet
        }
    }
    else {
        $module.Diff.before = Get-SubnetResult -Subnet $vmSubnet

        $currentSubnet = if ($vmSubnet.SubnetVLans) { $vmSubnet.SubnetVLans[0].Subnet } else { $null }
        if ($null -ne $module.Params.subnet -and $currentSubnet -ne $module.Params.subnet) {
            $cur = $currentSubnet
            $req = $module.Params.subnet
            $module.Warn("Cannot change 'subnet' after creation (current: '$cur', requested: '$req'). Delete and recreate.")
        }
        $currentVlan = if ($vmSubnet.SubnetVLans) { $vmSubnet.SubnetVLans[0].VLanID } else { 0 }
        if ($currentVlan -ne $module.Params.vlan_id) {
            $module.Warn("Cannot change 'vlan_id' after creation (current: $currentVlan, requested: $($module.Params.vlan_id)). Delete and recreate to change.")
        }
        if ($null -ne $module.Params.logical_network_definition) {
            $currentLnd = if ($vmSubnet.LogicalNetworkDefinition) { $vmSubnet.LogicalNetworkDefinition.Name } else { $null }
            if ($currentLnd -ne $module.Params.logical_network_definition) {
                $cur = $currentLnd
                $req = $module.Params.logical_network_definition
                $module.Warn("Cannot change 'logical_network_definition' after creation (current: '$cur', requested: '$req'). Delete and recreate.")
            }
        }

        $needsUpdate = Test-SCVMMPropertiesChanged -PropertyMap $updateMap `
            -CurrentObject $vmSubnet -AnsibleParams $module.Params

        if ($needsUpdate) {
            $setParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap `
                -AnsibleParams $module.Params -CurrentObject $vmSubnet
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                try {
                    $vmSubnet = Set-SCVMSubnet -VMSubnet $vmSubnet @setParams -ErrorAction Stop
                }
                catch {
                    $module.FailJson("Failed to update VM subnet '$($module.Params.name)': $($_.Exception.Message)", $_)
                }
            }
        }

        $module.Result.vm_subnet = Get-SubnetResult -Subnet $vmSubnet
        if ($needsUpdate -and $module.CheckMode) {
            $module.Diff.after = Get-SCVMMCheckModeDiff -Before $module.Diff.before `
                -UpdateMap $updateMap -AnsibleParams $module.Params `
                -CurrentObject $vmSubnet
        }
        else {
            $module.Diff.after = $module.Result.vm_subnet
        }
    }
}
else {
    if ($vmSubnet) {
        $module.Diff.before = Get-SubnetResult -Subnet $vmSubnet
        $module.Diff.after = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                Remove-SCVMSubnet -VMSubnet $vmSubnet -Force -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove VM subnet '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
