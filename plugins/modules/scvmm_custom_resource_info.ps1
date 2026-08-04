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
    @{ Param = "share_path"; Property = "SharePath"; Type = "string" }
    @{ Param = "library_server"; Property = "LibraryServer"; Type = "nested_name" }
    @{ Param = "family_name"; Property = "FamilyName"; Type = "string" }
    @{ Param = "release"; Property = "Release"; Type = "string" }
    @{ Param = "owner"; Property = "Owner"; Type = "string" }
    @{ Param = "enabled"; Property = "Enabled"; Type = "bool" }
    @{ Param = "is_orphaned"; Property = "IsOrphaned"; Type = "bool" }
)

$crName = $module.Params.name
if ($crName) {
    $resources = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCCustomResource' -ObjectType 'custom resource' `
        -FilterScript { $_.Name -eq $crName } -AllowMultiple $true
    $resources = if ($resources) { @($resources) } else { @() }
}
else {
    $resources = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCCustomResource' -ObjectType 'custom resource' -AllowMultiple $true
    $resources = if ($resources) { @($resources) } else { @() }
}

$module.Result.custom_resources = @($resources | ForEach-Object {
        Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
    })

$module.ExitJson()
