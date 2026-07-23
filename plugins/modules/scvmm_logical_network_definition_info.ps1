#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str' }
        logical_network = @{ type = 'str' }
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
    @{ Param = "logical_network"; Property = "LogicalNetwork"; Type = "nested_name" }
)

$getParams = @{
    VMMServer = $vmmConnection
    ErrorAction = 'Stop'
}

if ($module.Params.name) {
    $getParams['Name'] = $module.Params.name
}

if ($module.Params.logical_network) {
    $ln = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCLogicalNetwork' -Name $module.Params.logical_network `
        -ObjectType 'Logical network' -FailIfNotFound $true
    $getParams['LogicalNetwork'] = $ln
}

try {
    $definitions = @(Get-SCLogicalNetworkDefinition @getParams)
}
catch {
    $module.FailJson("Failed to query logical network definitions: $($_.Exception.Message)", $_)
}

$module.Result.logical_network_definitions = @($definitions | ForEach-Object {
        $result = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
        $result['subnet_vlans'] = @($_.SubnetVLans | ForEach-Object {
                @{
                    subnet = $_.Subnet
                    vlan_id = [int]$_.VLanID
                }
            })
        $result['host_groups'] = @($_.HostGroups | ForEach-Object { $_.Name })
        $result
    })

$module.ExitJson()
