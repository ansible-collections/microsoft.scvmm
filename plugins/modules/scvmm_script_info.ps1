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

$scriptName = $module.Params.name
if ($scriptName) {
    $scripts = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCScript' -ObjectType 'script' `
        -FilterScript { $_.Name -eq $scriptName } -AllowMultiple $true
    $scripts = if ($scripts) { @($scripts) } else { @() }
}
else {
    $scripts = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCScript' -ObjectType 'script' -AllowMultiple $true
    $scripts = if ($scripts) { @($scripts) } else { @() }
}

$module.Result.scripts = @($scripts | ForEach-Object {
        Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
    })

$module.ExitJson()
