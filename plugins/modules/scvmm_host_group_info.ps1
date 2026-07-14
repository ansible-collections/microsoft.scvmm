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

try {
    if ($module.Params.name) {
        $hostGroups = @(Get-SCVMHostGroup -VMMServer $vmmConnection -Name $module.Params.name -ErrorAction Stop)
    }
    else {
        $hostGroups = @(Get-SCVMHostGroup -VMMServer $vmmConnection -ErrorAction Stop)
    }
}
catch {
    $module.FailJson("Failed to query host groups: $($_.Exception.Message)", $_)
}

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "path"; Property = "Path"; Type = "string" }
    @{ Param = "parent_host_group"; Property = "ParentHostGroup"; Type = "nested_name" }
)

$module.Result.host_groups = @($hostGroups | ForEach-Object {
        $result = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
        $result['child_host_groups'] = @(
            $_.ChildHostGroups | Where-Object { $null -ne $_ } | ForEach-Object { [string]$_.Name }
        )
        $result['hosts'] = @(
            $_.Hosts | Where-Object { $null -ne $_ } | ForEach-Object { [string]$_.FQDN }
        )
        $result['clouds'] = @(
            $_.Clouds | Where-Object { $null -ne $_ } | ForEach-Object { [string]$_.Name }
        )
        $result
    })

$module.ExitJson()
