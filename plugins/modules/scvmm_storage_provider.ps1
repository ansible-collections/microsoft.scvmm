#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        computer_name = @{ type = 'str' }
        run_as_account = @{ type = 'str' }
        description = @{ type = 'str' }
        state = @{
            type = 'str'
            default = 'present'
            choices = @('present', 'absent')
        }
        vmm_server = @{ type = 'str' }
    }
    required_if = @(
        , @('state', 'present', @('computer_name', 'run_as_account'))
    )
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

$updateMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string" }
)

$provider = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCStorageProvider' -Name $module.Params.name `
    -ObjectType 'storage provider'

if ($module.Params.state -eq 'present') {
    if (-not $provider) {
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            $runAs = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
                -CmdletName 'Get-SCRunAsAccount' -Name $module.Params.run_as_account `
                -ObjectType 'RunAs account' -FailIfNotFound $true
            $addParams = @{
                Name = $module.Params.name
                ComputerName = $module.Params.computer_name
                RunAsAccount = $runAs
                AddWindowsNativeWmiProvider = $true
                ErrorAction = 'Stop'
            }
            if ($null -ne $module.Params.description) {
                $addParams['Description'] = $module.Params.description
            }
            try {
                $provider = Add-SCStorageProvider @addParams
            }
            catch {
                $module.FailJson("Failed to add storage provider '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
    }
    else {
        if (Test-SCVMMPropertiesChanged -PropertyMap $updateMap -CurrentObject $provider -AnsibleParams $module.Params) {
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                $setParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap -AnsibleParams $module.Params
                $setParams['StorageProvider'] = $provider
                $setParams['ErrorAction'] = 'Stop'
                try {
                    $provider = Set-SCStorageProvider @setParams
                }
                catch {
                    $module.FailJson("Failed to update storage provider '$($module.Params.name)': $($_.Exception.Message)", $_)
                }
            }
        }
    }

    if ($provider) {
        $module.Result.storage_provider = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $provider
    }
    elseif ($module.CheckMode) {
        $module.Result.storage_provider = @{
            name = $module.Params.name
            description = $module.Params.description
        }
    }
}
else {
    if ($provider) {
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                Remove-SCStorageProvider -StorageProvider $provider -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove storage provider '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
