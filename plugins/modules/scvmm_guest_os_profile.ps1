#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        description = @{ type = 'str' }
        owner = @{ type = 'str' }
        computer_name = @{ type = 'str' }
        full_name = @{ type = 'str' }
        organization_name = @{ type = 'str' }
        time_zone = @{ type = 'int' }
        domain = @{ type = 'str' }
        domain_join_organizational_unit = @{ type = 'str' }
        workgroup = @{ type = 'str' }
        operating_system = @{ type = 'str' }
        auto_logon_count = @{ type = 'int' }
        shielded = @{ type = 'bool' }
        linux_domain_name = @{ type = 'str' }
        gui_run_once_commands = @{ type = 'list'; elements = 'str' }
        vmm_server = @{ type = 'str' }
        state = @{ type = 'str'; default = 'present'; choices = @('present', 'absent') }
    }
    mutually_exclusive = @(
        , @('domain', 'workgroup')
    )
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name
$state = $module.Params.state

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

$updateMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "owner"; Property = "Owner"; Type = "string" }
    @{ Param = "computer_name"; Property = "ComputerName"; Type = "string" }
    @{ Param = "full_name"; Property = "FullName"; Type = "string" }
    @{ Param = "organization_name"; Property = "OrgName"; Type = "string"; CmdletParam = "OrganizationName" }
    @{ Param = "time_zone"; Property = "TimeZone"; Type = "int" }
    @{ Param = "domain"; Property = "JoinDomain"; Type = "string"; CmdletParam = "Domain" }
    @{ Param = "domain_join_organizational_unit"; Property = "DomainJoinOrganizationalUnit"; Type = "string" }
    @{ Param = "workgroup"; Property = "JoinWorkgroup"; Type = "string"; CmdletParam = "Workgroup" }
    @{ Param = "auto_logon_count"; Property = "AutoLogonCount"; Type = "int" }
    @{ Param = "shielded"; Property = "Shielded"; Type = "bool" }
    @{ Param = "linux_domain_name"; Property = "DNSDomainName"; Type = "string"; CmdletParam = "LinuxDomainName" }
)

function Get-GuestOSProfileResult {
    param ($ProfileObj)
    $result = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $ProfileObj
    $result.gui_run_once_commands = @()
    if ($ProfileObj.GuiRunOnceCommands) {
        $result.gui_run_once_commands = @($ProfileObj.GuiRunOnceCommands)
    }
    return $result
}

function Resolve-OperatingSystem {
    param ($VMMConnection, $OSName)
    $os = Get-SCOperatingSystem -VMMServer $VMMConnection | Where-Object { $_.Name -eq $OSName }
    if (-not $os) {
        $module.FailJson("Operating system '$OSName' not found in SCVMM")
    }
    return $os
}

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

if ($state -eq 'present') {
    $existing = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCGuestOSProfile' -Name $name -ObjectType 'guest OS profile'

    if ($existing) {
        $updateParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap `
            -AnsibleParams $module.Params -CurrentObject $existing

        $osChanged = $false
        if ($module.Params.operating_system) {
            $currentOS = if ($existing.OperatingSystem) { $existing.OperatingSystem.Name } else { $null }
            if ($currentOS -ne $module.Params.operating_system) {
                $osChanged = $true
            }
        }

        $guiChanged = $false
        if ($null -ne $module.Params.gui_run_once_commands) {
            $currentCmds = if ($existing.GuiRunOnceCommands) { @($existing.GuiRunOnceCommands) } else { @() }
            $desiredCmds = @($module.Params.gui_run_once_commands)
            if ($null -eq (Compare-Object -ReferenceObject $currentCmds -DifferenceObject $desiredCmds -SyncWindow 0) -eq $false) {
                $guiChanged = $true
            }
        }

        $needsUpdate = $updateParams.Count -gt 0 -or $osChanged -or $guiChanged

        if ($needsUpdate) {
            $module.Diff.before = Get-GuestOSProfileResult -ProfileObj $existing
            if (-not $module.CheckMode) {
                if ($osChanged) {
                    $osObj = Resolve-OperatingSystem -VMMConnection $vmmConnection -OSName $module.Params.operating_system
                    $updateParams['OperatingSystem'] = $osObj
                }
                if ($guiChanged) {
                    $updateParams['GuiRunOnceCommands'] = $module.Params.gui_run_once_commands
                }
                try {
                    $existing = Set-SCGuestOSProfile -GuestOSProfile $existing @updateParams -ErrorAction Stop
                }
                catch {
                    $module.FailJson("Failed to update guest OS profile '$name': $($_.Exception.Message)", $_)
                }
            }
            $module.Result.changed = $true
        }

        $module.Result.guest_os_profile = Get-GuestOSProfileResult -ProfileObj $existing

        if ($needsUpdate) {
            if ($module.CheckMode) {
                $module.Diff.after = Get-SCVMMCheckModeDiff -Before $module.Diff.before `
                    -UpdateMap $updateMap -AnsibleParams $module.Params -CurrentObject $existing
                if ($osChanged) { $module.Diff.after['operating_system'] = $module.Params.operating_system }
                if ($guiChanged) { $module.Diff.after['gui_run_once_commands'] = @($module.Params.gui_run_once_commands) }
            }
            else {
                $module.Diff.after = $module.Result.guest_os_profile
            }
        }
    }
    else {
        if (-not $module.Params.operating_system) {
            $module.FailJson("operating_system is required when creating a new guest OS profile")
        }

        $osObj = Resolve-OperatingSystem -VMMConnection $vmmConnection -OSName $module.Params.operating_system

        $createParams = @{
            Name = $name
            OperatingSystem = $osObj
        }
        $mapParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap -AnsibleParams $module.Params
        foreach ($key in $mapParams.Keys) { $createParams[$key] = $mapParams[$key] }
        if ($module.Params.gui_run_once_commands) {
            $createParams['GuiRunOnceCommands'] = $module.Params.gui_run_once_commands
        }

        $module.Diff.before = @{}
        if (-not $module.CheckMode) {
            try {
                $newProfile = New-SCGuestOSProfile @createParams -VMMServer $vmmConnection -ErrorAction Stop
            }
            catch {
                $module.FailJson("Failed to create guest OS profile '$name': $($_.Exception.Message)", $_)
            }
            $module.Result.guest_os_profile = Get-GuestOSProfileResult -ProfileObj $newProfile
            $module.Diff.after = $module.Result.guest_os_profile
        }
        else {
            $module.Result.guest_os_profile = @{
                id = $null
                name = $name
                operating_system = $module.Params.operating_system
                description = $module.Params.description
            }
            $module.Diff.after = $module.Result.guest_os_profile
        }
        $module.Result.changed = $true
    }
}
elseif ($state -eq 'absent') {
    $existing = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCGuestOSProfile' -Name $name -ObjectType 'guest OS profile'

    if ($existing) {
        $module.Diff.before = Get-GuestOSProfileResult -ProfileObj $existing
        $module.Diff.after = @{}
        if (-not $module.CheckMode) {
            try {
                Remove-SCGuestOSProfile -GuestOSProfile $existing -Force -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove guest OS profile '$name': $($_.Exception.Message)", $_)
            }
        }
        $module.Result.changed = $true
    }
}

$module.ExitJson()
