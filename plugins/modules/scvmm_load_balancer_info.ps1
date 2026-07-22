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

$getParams = @{
    VMMServer   = $vmmConnection
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
        @{
            id                     = $_.ID.ToString()
            address                = $_.Address
            port                   = $_.Port
            manufacturer           = $_.Manufacturer
            model                  = $_.Model
            configuration_provider = if ($_.ConfigurationProvider) { $_.ConfigurationProvider.Name } else { $null }
            host_groups            = @($_.HostGroups | ForEach-Object { $_.Name })
        }
    })

$module.ExitJson()
