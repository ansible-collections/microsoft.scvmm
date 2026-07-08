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
    @{ Param = "network_address"; Property = "NetworkAddress"; Type = "string" }
    @{ Param = "provider_type"; Property = "ProviderType"; Type = "enum" }
    @{ Param = "status"; Property = "Status"; Type = "enum" }
    @{ Param = "enabled"; Property = "Enabled"; Type = "bool" }
    @{ Param = "storage_arrays"; Property = "StorageArrays"; Type = "name_list" }
)

$providers = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCStorageProvider' -Name $module.Params.name `
    -ObjectType 'storage provider'

if ($module.Params.name) {
    $providers = if ($providers) { @($providers) } else { @() }
}

$module.Result.storage_providers = @($providers | ForEach-Object {
        Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
    })

$module.ExitJson()
