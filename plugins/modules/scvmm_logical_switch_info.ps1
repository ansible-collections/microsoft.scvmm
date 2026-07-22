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
    @{ Param = "minimum_bandwidth_mode"; Property = "MinimumBandwidthMode"; Type = "enum" }
    @{ Param = "enable_sriov"; Property = "EnableSriov"; Type = "bool" }
    @{ Param = "enable_packet_direct"; Property = "EnablePacketDirect"; Type = "bool" }
)

$switches = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCLogicalSwitch' -Name $module.Params.name `
    -ObjectType 'logical switch'

if ($module.Params.name) {
    $switches = if ($switches) { @($switches) } else { @() }
}

$module.Result.logical_switches = @($switches | ForEach-Object {
        Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
    })

$module.ExitJson()
