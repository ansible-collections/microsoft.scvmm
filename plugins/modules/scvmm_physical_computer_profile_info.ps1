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

$vmmConnection = Connect-SCVMMServerSession `
    -Module $module -VMMServer $module.Params.vmm_server

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{
        Param = "description"
        Property = "Description"
        Type = "string"
    }
    @{ Param = "owner"; Property = "Owner"; Type = "string" }
    @{
        Param = "full_name"
        Property = "FullName"
        Type = "string"
    }
    @{
        Param = "organization_name"
        Property = "OrgName"
        Type = "string"
    }
    @{
        Param = "join_domain"
        Property = "JoinDomain"
        Type = "string"
    }
    @{
        Param = "join_workgroup"
        Property = "JoinWorkgroup"
        Type = "string"
    }
    @{
        Param = "bypass_vhd_conversion"
        Property = "BypassVHDConversion"
        Type = "bool"
    }
    @{
        Param = "is_guarded"
        Property = "IsGuarded"
        Type = "bool"
    }
    @{
        Param = "time_zone"
        Property = "TimeZone"
        Type = "int"
    }
    @{
        Param = "vm_paths"
        Property = "VMPaths"
        Type = "string"
    }
    @{
        Param = "enabled"
        Property = "Enabled"
        Type = "bool"
    }
)

$profiles = Get-SCVMMObject -Module $module `
    -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCPhysicalComputerProfile' `
    -Name $module.Params.name `
    -ObjectType 'physical computer profile' `
    -AllowMultiple $true

if ($module.Params.name) {
    $profiles = if ($profiles) { @($profiles) } else { @() }
}

$module.Result.physical_computer_profiles = @(
    if ($profiles.Count -gt 0) {
        $profiles | ForEach-Object {
            $result = Get-SCVMMResultFromMap `
                -PropertyMap $propertyMap -CurrentObject $_
            $result['os_boot_vhd'] = if ($_.OSBootVHD) {
                $_.OSBootVHD.Name
            }
            else { $null }
            $result['driver_matching_tag'] = if (
                $_.DriverMatchingTag
            ) {
                @($_.DriverMatchingTag)
            }
            else { @() }
            $result
        }
    }
)

$module.ExitJson()
