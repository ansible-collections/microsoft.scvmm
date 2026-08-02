#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str' }
        cloud = @{ type = 'str' }
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
    @{ Param = "service_priority"; Property = "ServicePriority"; Type = "enum" }
    @{ Param = "cost_center"; Property = "CostCenter"; Type = "string" }
    @{ Param = "owner"; Property = "Owner"; Type = "string" }
    @{ Param = "service_template_release"; Property = "ServiceTemplateRelease"; Type = "string" }
    @{ Param = "deployment_state"; Property = "DeploymentState"; Type = "enum" }
    @{ Param = "enabled"; Property = "Enabled"; Type = "bool" }
    @{ Param = "creation_time"; Property = "AddedTime"; Type = "datetime_iso" }
    @{ Param = "modified_time"; Property = "ModifiedTime"; Type = "datetime_iso" }
)

$services = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCService' -Name $module.Params.name -ObjectType 'service' `
    -AllowMultiple $true

if ($module.Params.name) {
    $services = if ($services) { @($services) } else { @() }
}

if ($module.Params.cloud) {
    $services = @($services | Where-Object { $_.Cloud -and $_.Cloud.ToString() -eq $module.Params.cloud })
}

$module.Result.services = @($services | ForEach-Object {
        $result = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
        $result['cloud_name'] = if ($_.Cloud) { $_.Cloud.ToString() } else { $null }
        $result['service_template_name'] = if ($_.ServiceTemplate) { $_.ServiceTemplate.ToString() } else { $null }
        $result
    })

$module.ExitJson()
