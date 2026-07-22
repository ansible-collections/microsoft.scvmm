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

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "mac_address_range_start"; Property = "MACAddressRangeStart"; Type = "string" }
    @{ Param = "mac_address_range_end"; Property = "MACAddressRangeEnd"; Type = "string" }
    @{ Param = "host_groups"; Property = "HostGroups"; Type = "name_list" }
)

$pools = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCMACAddressPool' -Name $module.Params.name `
    -ObjectType 'MAC address pool'

if ($module.Params.name) {
    $pools = if ($pools) { @($pools) } else { @() }
}

$module.Result.mac_address_pools = @($pools | ForEach-Object {
        Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
    })

$module.ExitJson()
