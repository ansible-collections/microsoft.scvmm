#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str' }
        vmm_server = @{ type = 'str' }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

$profiles = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCNativeUplinkPortProfile' -Name $module.Params.name `
    -ObjectType 'uplink port profile'

if ($module.Params.name) {
    $profiles = if ($profiles) { @($profiles) } else { @() }
}

$module.Result.uplink_port_profiles = @($profiles | ForEach-Object {
        $result = @{
            id                            = $_.ID.ToString()
            name                          = $_.Name
            description                   = $_.Description
            enable_network_virtualization = [bool]$_.EnableNetworkVirtualization
        }
        $result.logical_network_definitions = @($_.LogicalNetworkDefinitions | ForEach-Object { $_.Name })
        $result
    })

$module.ExitJson()
