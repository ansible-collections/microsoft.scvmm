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

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "owner"; Property = "Owner"; Type = "string" }
    @{ Param = "computer_name"; Property = "ComputerName"; Type = "string" }
    @{ Param = "full_name"; Property = "FullName"; Type = "string" }
    @{ Param = "organization_name"; Property = "OrgName"; Type = "string" }
    @{ Param = "time_zone"; Property = "TimeZone"; Type = "int" }
    @{ Param = "domain"; Property = "JoinDomain"; Type = "string" }
    @{ Param = "domain_join_organizational_unit"; Property = "DomainJoinOrganizationalUnit"; Type = "string" }
    @{ Param = "workgroup"; Property = "JoinWorkgroup"; Type = "string" }
    @{ Param = "operating_system"; Property = "OperatingSystem"; Type = "nested_name" }
    @{ Param = "auto_logon_count"; Property = "AutoLogonCount"; Type = "int" }
    @{ Param = "shielded"; Property = "Shielded"; Type = "bool" }
    @{ Param = "linux_domain_name"; Property = "DNSDomainName"; Type = "string" }
    @{ Param = "creation_time"; Property = "AddedTime"; Type = "datetime_iso" }
)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

$profiles = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCGuestOSProfile' -Name $module.Params.name `
    -ObjectType 'guest OS profile'

if ($module.Params.name) {
    $profiles = if ($profiles) { @($profiles) } else { @() }
}

$module.Result.guest_os_profiles = @($profiles | ForEach-Object {
        $result = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
        $result.gui_run_once_commands = @()
        if ($_.GuiRunOnceCommands) {
            $result.gui_run_once_commands = @($_.GuiRunOnceCommands)
        }
        $result
    })

$module.ExitJson()
