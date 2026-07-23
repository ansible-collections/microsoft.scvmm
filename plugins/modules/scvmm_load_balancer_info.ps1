#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        address = @{ type = 'str' }
        manufacturer = @{ type = 'str' }
        vmm_server = @{ type = 'str' }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "address"; Property = "Address"; Type = "string" }
    @{ Param = "port"; Property = "Port"; Type = "int" }
    @{ Param = "manufacturer"; Property = "Manufacturer"; Type = "string" }
    @{ Param = "model"; Property = "Model"; Type = "string" }
    @{ Param = "configuration_provider"; Property = "ConfigurationProvider"; Type = "nested_name" }
    @{ Param = "host_groups"; Property = "HostGroups"; Type = "name_list" }
)

$getParams = @{
    VMMServer = $vmmConnection
    ErrorAction = 'SilentlyContinue'
}

if ($module.Params.address) {
    $getParams['LoadBalancerAddress'] = $module.Params.address
}
if ($module.Params.manufacturer) {
    $getParams['Manufacturer'] = $module.Params.manufacturer
}

$lbs = @(Get-SCLoadBalancer @getParams)

$module.Result.load_balancers = @($lbs | ForEach-Object {
        Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
    })

$module.ExitJson()
