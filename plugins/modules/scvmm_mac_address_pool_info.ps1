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

$pools = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCMACAddressPool' -Name $module.Params.name `
    -ObjectType 'MAC address pool'

if ($module.Params.name) {
    $pools = if ($pools) { @($pools) } else { @() }
}

$module.Result.mac_address_pools = @($pools | ForEach-Object {
        @{
            id = $_.ID.ToString()
            name = $_.Name
            description = $_.Description
            mac_address_range_start = $_.MACAddressRangeStart
            mac_address_range_end = $_.MACAddressRangeEnd
            host_groups = @($_.HostGroups | ForEach-Object { $_.Name })
        }
    })

$module.ExitJson()
