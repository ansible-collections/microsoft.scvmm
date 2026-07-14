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
    @{ Param = "host_group"; Property = "VMHostGroup"; Type = "nested_name" }
    @{ Param = "status"; Property = "OverallState"; Type = "enum" }
    @{ Param = "shared_volumes"; Property = "SharedVolumes"; Type = "name_list" }
)

if ($module.Params.name) {
    $filterName = $module.Params.name
    $clusters = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCVMHostCluster' -ObjectType 'host cluster' `
        -FilterScript { $_.Name -eq $filterName }
    $clusters = if ($clusters) { @($clusters) } else { @() }
}
else {
    $clusters = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCVMHostCluster' -ObjectType 'host cluster'
}

$module.Result.host_clusters = @($clusters | ForEach-Object {
        $result = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
        $result['node_count'] = if ($_.Nodes) { @($_.Nodes).Count } else { 0 }
        $result
    })

$module.ExitJson()
