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

function Get-SubnetResult {
    param($Subnet)
    $result = @{
        id          = $Subnet.ID.ToString()
        name        = $Subnet.Name
        description = $Subnet.Description
        vm_network  = $Subnet.VMNetwork.Name
        subnet_vlans = @($Subnet.SubnetVLans | ForEach-Object {
                @{
                    subnet  = $_.Subnet
                    vlan_id = $_.VLanID
                }
            })
    }
    if ($Subnet.LogicalNetworkDefinition) {
        $result['logical_network_definition'] = $Subnet.LogicalNetworkDefinition.Name
    }
    return $result
}

$vmSubnet = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCVMSubnet' -Name $module.Params.name `
    -ObjectType 'VM subnet'

if ($module.Params.state -eq 'present') {
    if (-not $vmSubnet) {
        $module.Diff.before = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                $vmNet = Get-SCVMNetwork -VMMServer $vmmConnection -Name $module.Params.vm_network -ErrorAction Stop
                if (-not $vmNet) {
                    $module.FailJson("VM network '$($module.Params.vm_network)' not found")
                }

                $subnetVlan = New-SCSubnetVLan -Subnet $module.Params.subnet -VLanID $module.Params.vlan_id

                $newParams = @{
                    VMMServer  = $vmmConnection
                    Name       = $module.Params.name
                    VMNetwork  = $vmNet
                    SubnetVLan = $subnetVlan
                    ErrorAction = 'Stop'
                }
                if ($null -ne $module.Params.description) {
                    $newParams['Description'] = $module.Params.description
                }
                if ($module.Params.logical_network_definition) {
                    $lnd = Get-SCLogicalNetworkDefinition -VMMServer $vmmConnection -Name $module.Params.logical_network_definition -ErrorAction Stop
                    if (-not $lnd) {
                        $module.FailJson("Logical network definition '$($module.Params.logical_network_definition)' not found")
                    }
                    $newParams['LogicalNetworkDefinition'] = $lnd
                }

                $vmSubnet = New-SCVMSubnet @newParams
            }
            catch {
                $module.FailJson("Failed to create VM subnet '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
    }
    else {
        $needsUpdate = $false
        $updateParams = @{}

        if ($null -ne $module.Params.description -and $module.Params.description -ne $vmSubnet.Description) {
            $needsUpdate = $true
            $updateParams['Description'] = $module.Params.description
        }

        if ($needsUpdate) {
            $module.Diff.before = Get-SubnetResult -Subnet $vmSubnet
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                $updateParams['VMSubnet'] = $vmSubnet
                $updateParams['ErrorAction'] = 'Stop'
                try {
                    $vmSubnet = Set-SCVMSubnet @updateParams
                }
                catch {
                    $module.FailJson("Failed to update VM subnet '$($module.Params.name)': $($_.Exception.Message)", $_)
                }
            }
        }
    }

    if ($vmSubnet) {
        $module.Result.vm_subnet = Get-SubnetResult -Subnet $vmSubnet
        if ($module.Result.changed -and $module.Diff.before) {
            $module.Diff.after = $module.Result.vm_subnet
        }
    }
    elseif ($module.CheckMode) {
        $module.Result.vm_subnet = @{
            name        = $module.Params.name
            description = $module.Params.description
            vm_network  = $module.Params.vm_network
        }
        $module.Diff.after = $module.Result.vm_subnet
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
