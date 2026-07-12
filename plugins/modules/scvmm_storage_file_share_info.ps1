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
    @{ Param = "share_path"; Property = "SharePath"; Type = "string" }
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "total_capacity_gb"; Property = "TotalCapacity"; Type = "bytes_to_gb" }
    @{ Param = "free_capacity_gb"; Property = "FreeCapacity"; Type = "bytes_to_gb" }
    @{ Param = "host_access"; Property = "VMHostsWithAccess"; Type = "name_list" }
    @{ Param = "enabled"; Property = "Enabled"; Type = "bool" }
)

$shares = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCStorageFileShare' -Name $module.Params.name `
    -ObjectType 'storage file share'

if ($module.Params.name) {
    $shares = if ($shares) { @($shares) } else { @() }
}

$module.Result.storage_file_shares = @($shares | ForEach-Object {
        Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
    })

$module.ExitJson()
