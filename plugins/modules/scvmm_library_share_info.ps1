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
    @{ Param = "share_path"; Property = "Path"; Type = "string" }
    @{ Param = "library_server"; Property = "LibraryServer"; Type = "nested_name" }
    @{ Param = "use_alternate_data_stream"; Property = "UseAlternateDataStream"; Type = "bool" }
)

$filterName = $module.Params.name
if ($filterName) {
    $shares = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCLibraryShare' -Name $filterName `
        -ObjectType 'library share' `
        -FilterScript { $_.Name -eq $filterName } `
        -AllowMultiple $true
    $shares = if ($shares) { @($shares) } else { @() }
}
else {
    $shares = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCLibraryShare' `
        -ObjectType 'library share'
    $shares = if ($shares) { @($shares) } else { @() }
}

$module.Result.library_shares = @($shares | ForEach-Object {
        Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
    })

$module.ExitJson()
