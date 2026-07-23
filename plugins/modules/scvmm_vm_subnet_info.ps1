#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str' }
        vm_network = @{ type = 'str' }
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
    @{ Param = "vm_network"; Property = "VMNetwork"; Type = "nested_name" }
    @{ Param = "logical_network_definition"; Property = "LogicalNetworkDefinition"; Type = "nested_name" }
)

if ($module.Params.vm_network) {
    $vmNet = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCVMNetwork' -Name $module.Params.vm_network `
        -ObjectType 'VM network'
    if (-not $vmNet) {
        $module.Result.vm_subnets = @()
        $module.ExitJson()
    }
    $subnets = Get-SCVMSubnet -VMMServer $vmmConnection -VMNetwork $vmNet -ErrorAction Stop
    if ($module.Params.name) {
        $subnets = @($subnets | Where-Object { $_.Name -eq $module.Params.name })
    }
}
else {
    $subnets = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCVMSubnet' -Name $module.Params.name `
        -ObjectType 'VM subnet'
    if ($module.Params.name) {
        $subnets = if ($subnets) { @($subnets) } else { @() }
    }
}

$module.Result.vm_subnets = @($subnets | ForEach-Object {
        $result = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
        $result['subnet_vlans'] = @($_.SubnetVLans | ForEach-Object {
                @{
                    subnet = $_.Subnet
                    vlan_id = $_.VLanID
                }
            })
        $result
    })

$module.ExitJson()
