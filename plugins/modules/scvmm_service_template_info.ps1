#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str' }
        release = @{ type = 'str' }
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
    @{ Param = "release"; Property = "Release"; Type = "string" }
    @{ Param = "service_priority"; Property = "ServicePriority"; Type = "enum" }
    @{ Param = "use_as_default_release"; Property = "UseAsDefaultRelease"; Type = "bool" }
    @{ Param = "is_published"; Property = "IsPublished"; Type = "bool" }
    @{ Param = "owner"; Property = "Owner"; Type = "string" }
    @{ Param = "enabled"; Property = "Enabled"; Type = "bool" }
    @{ Param = "creation_time"; Property = "AddedTime"; Type = "datetime_iso" }
    @{ Param = "modified_time"; Property = "ModifiedTime"; Type = "datetime_iso" }
)

$templates = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCServiceTemplate' -Name $module.Params.name -ObjectType 'service template' `
    -AllowMultiple $true

if ($module.Params.name) {
    $templates = if ($templates) { @($templates) } else { @() }
}

if ($module.Params.release) {
    $templates = @($templates | Where-Object { $_.Release -eq $module.Params.release })
}

$module.Result.service_templates = @($templates | ForEach-Object {
        Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
    })

$module.ExitJson()
