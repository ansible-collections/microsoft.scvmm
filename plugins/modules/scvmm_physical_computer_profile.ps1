#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        new_name = @{ type = 'str' }
        description = @{ type = 'str' }
        owner = @{ type = 'str' }
        virtual_hard_disk = @{ type = 'str' }
        local_admin_password = @{ type = 'str'; no_log = $true }
        domain = @{ type = 'str' }
        domain_join_run_as_account = @{ type = 'str' }
        join_workgroup = @{ type = 'bool'; default = $false }
        use_as_vm_host = @{ type = 'bool'; default = $true }
        use_as_file_server = @{ type = 'bool'; default = $false }
        full_name = @{ type = 'str' }
        organization_name = @{ type = 'str' }
        time_zone = @{ type = 'int' }
        bypass_vhd_conversion = @{ type = 'bool' }
        is_guarded = @{ type = 'bool' }
        vm_paths = @{ type = 'str' }
        driver_matching_tag = @{ type = 'list'; elements = 'str' }
        state = @{
            type = 'str'
            default = 'present'
            choices = @('present', 'absent')
        }
        vmm_server = @{ type = 'str' }
    }
    mutually_exclusive = @(
        , @('domain', 'join_workgroup')
        , @('use_as_vm_host', 'use_as_file_server')
    )
    required_together = @(
        , @('domain', 'domain_join_run_as_account')
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
    @{ Param = "owner"; Property = "Owner"; Type = "string" }
    @{ Param = "full_name"; Property = "FullName"; Type = "string" }
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
    @{ Param = "time_zone"; Property = "TimeZone"; Type = "int" }
    @{ Param = "vm_paths"; Property = "VMPaths"; Type = "string" }
    @{ Param = "enabled"; Property = "Enabled"; Type = "bool" }
)

$updateMap = @(
    @{
        Param = "description"
        Property = "Description"
        Type = "string"
    }
    @{
        Param = "full_name"
        Property = "FullName"
        CmdletParam = "FullName"
        Type = "string"
    }
    @{
        Param = "organization_name"
        Property = "OrgName"
        CmdletParam = "OrganizationName"
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
        Param = "vm_paths"
        Property = "VMPaths"
        CmdletParam = "VMPaths"
        Type = "string"
    }
)

function Get-ProfileResult {
    param($InputObject, $PropertyMap)
    $result = Get-SCVMMResultFromMap `
        -PropertyMap $PropertyMap -CurrentObject $InputObject
    $result['os_boot_vhd'] = if ($InputObject.OSBootVHD) {
        $InputObject.OSBootVHD.Name
    }
    else { $null }
    $result['driver_matching_tag'] = if (
        $InputObject.DriverMatchingTag
    ) {
        @($InputObject.DriverMatchingTag)
    }
    else { @() }
    return $result
}

$computerProfileName = $module.Params.name
$computerProfile = Get-SCVMMObject -Module $module `
    -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCPhysicalComputerProfile' `
    -Name $computerProfileName -ObjectType 'physical computer profile'

if ($module.Params.state -eq 'present') {
    if (-not $computerProfile) {
        if (-not $module.Params.virtual_hard_disk) {
            $module.FailJson(
                "virtual_hard_disk is required when creating" +
                " a new physical computer profile"
            )
        }
        if (-not $module.Params.local_admin_password) {
            $module.FailJson(
                "local_admin_password is required when" +
                " creating a new physical computer profile"
            )
        }
        if (-not $module.Params.domain -and
            -not $module.Params.join_workgroup) {
            $module.FailJson(
                "Either domain or join_workgroup must be" +
                " specified when creating a new profile"
            )
        }

        $module.Diff.before = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            $vhd = Get-SCVirtualHardDisk `
                -VMMServer $vmmConnection `
                -Name $module.Params.virtual_hard_disk |
                Select-Object -First 1
            if (-not $vhd) {
                $module.FailJson(
                    "Virtual hard disk" +
                    " '$($module.Params.virtual_hard_disk)'" +
                    " not found"
                )
            }

            $secPass = ConvertTo-SecureString `
                $module.Params.local_admin_password `
                -AsPlainText -Force
            $cred = New-Object `
                System.Management.Automation.PSCredential(
                'Administrator', $secPass
            )

            $nic = New-SCPhysicalComputerNetworkAdapterProfile `
                -SetAsPhysicalNetworkAdapter `
                -SetAsManagementNIC `
                -UseDhcpForIPConfiguration `
                -VMMServer $vmmConnection

            $newParams = @{
                Name = $module.Params.name
                VirtualHardDisk = $vhd
                LocalAdministratorCredential = $cred
                PhysicalComputerNetworkAdapterProfile = $nic
                VMMServer = $vmmConnection
                ErrorAction = 'Stop'
            }

            if ($module.Params.domain) {
                $runAs = Get-SCRunAsAccount `
                    -VMMServer $vmmConnection `
                    -Name $module.Params.domain_join_run_as_account
                if (-not $runAs) {
                    $module.FailJson(
                        "RunAs account" +
                        " '$($module.Params.domain_join_run_as_account)'" +
                        " not found"
                    )
                }
                $newParams['Domain'] = $module.Params.domain
                $newParams['DomainJoinRunAsAccount'] = $runAs
            }
            else {
                $newParams['JoinWorkgroup'] = $true
            }

            if ($module.Params.use_as_file_server) {
                $newParams['UseAsFileServer'] = $true
            }
            elseif ($module.Params.use_as_vm_host) {
                $newParams['UseAsVMHost'] = $true
            }

            if ($null -ne $module.Params.description) {
                $newParams['Description'] = `
                    $module.Params.description
            }
            if ($null -ne $module.Params.owner) {
                $newParams['Owner'] = $module.Params.owner
            }
            if ($null -ne $module.Params.full_name) {
                $newParams['FullName'] = `
                    $module.Params.full_name
            }
            if ($null -ne $module.Params.organization_name) {
                $newParams['OrganizationName'] = `
                    $module.Params.organization_name
            }
            if ($null -ne $module.Params.time_zone) {
                $newParams['TimeZone'] = `
                    $module.Params.time_zone
            }
            if ($null -ne $module.Params.bypass_vhd_conversion) {
                $newParams['BypassVHDConversion'] = `
                    $module.Params.bypass_vhd_conversion
            }
            if ($null -ne $module.Params.is_guarded) {
                $newParams['IsGuarded'] = `
                    $module.Params.is_guarded
            }
            if ($null -ne $module.Params.vm_paths) {
                $newParams['VMPaths'] = `
                    $module.Params.vm_paths
            }
            if ($null -ne $module.Params.driver_matching_tag) {
                $tagList = [System.Collections.Generic.List[string]]::new()
                foreach ($t in $module.Params.driver_matching_tag) {
                    $tagList.Add($t)
                }
                $newParams['DriverMatchingTag'] = $tagList
            }

            try {
                $computerProfile = `
                    New-SCPhysicalComputerProfile @newParams
                $module.Result.physical_computer_profile = `
                    Get-ProfileResult `
                    -InputObject $computerProfile `
                    -PropertyMap $propertyMap
                $module.Diff.after = `
                    $module.Result.physical_computer_profile
            }
            catch {
                $module.FailJson(
                    "Failed to create physical computer" +
                    " profile '$computerProfileName':" +
                    " $($_.Exception.Message)", $_
                )
            }
        }
        else {
            $module.Result.physical_computer_profile = @{
                id = $null
                name = $module.Params.name
                description = $module.Params.description
                owner = $module.Params.owner
                full_name = $module.Params.full_name
                organization_name = `
                    $module.Params.organization_name
                join_domain = $module.Params.domain
                join_workgroup = $null
                bypass_vhd_conversion = `
                    $module.Params.bypass_vhd_conversion
                is_guarded = $module.Params.is_guarded
                time_zone = $module.Params.time_zone
                vm_paths = $module.Params.vm_paths
                enabled = $true
                os_boot_vhd = `
                    $module.Params.virtual_hard_disk
                driver_matching_tag = if (
                    $module.Params.driver_matching_tag
                ) {
                    @($module.Params.driver_matching_tag)
                }
                else { @() }
            }
            $module.Diff.after = `
                $module.Result.physical_computer_profile
        }
    }
    else {
        $module.Diff.before = Get-ProfileResult `
            -InputObject $computerProfile -PropertyMap $propertyMap

        $needsUpdate = $false
        $setParams = @{
            PhysicalComputerProfile = $computerProfile
            ErrorAction = 'Stop'
        }

        $updateParams = Get-SCVMMParametersFromMap `
            -PropertyMap $updateMap `
            -AnsibleParams $module.Params `
            -CurrentObject $computerProfile
        if ($updateParams.Count -gt 0) {
            foreach ($key in $updateParams.Keys) {
                $setParams[$key] = $updateParams[$key]
            }
            $needsUpdate = $true
        }

        if ($null -ne $module.Params.new_name -and
            $module.Params.new_name -ne $computerProfile.Name) {
            $setParams['Name'] = $module.Params.new_name
            $needsUpdate = $true
        }

        if ($null -ne $module.Params.time_zone -and
            $module.Params.time_zone -ne $computerProfile.TimeZone) {
            $setParams['TimeZone'] = $module.Params.time_zone
            $needsUpdate = $true
        }

        if ($null -ne $module.Params.virtual_hard_disk) {
            $currentVhd = if ($computerProfile.OSBootVHD) {
                $computerProfile.OSBootVHD.Name
            }
            else { $null }
            if ($module.Params.virtual_hard_disk -ne $currentVhd) {
                $vhd = Get-SCVirtualHardDisk `
                    -VMMServer $vmmConnection `
                    -Name $module.Params.virtual_hard_disk |
                    Select-Object -First 1
                if (-not $vhd) {
                    $module.FailJson(
                        "Virtual hard disk" +
                        " '$($module.Params.virtual_hard_disk)'" +
                        " not found"
                    )
                }
                $setParams['VirtualHardDisk'] = $vhd
                $needsUpdate = $true
            }
        }

        if ($needsUpdate) {
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                try {
                    $computerProfile = `
                        Set-SCPhysicalComputerProfile @setParams
                }
                catch {
                    $module.FailJson(
                        "Failed to update physical computer" +
                        " profile '$computerProfileName':" +
                        " $($_.Exception.Message)", $_
                    )
                }
            }
        }

        if ($module.CheckMode -and $needsUpdate) {
            $checkResult = Get-SCVMMCheckModeDiff `
                -Before $module.Diff.before `
                -UpdateMap $updateMap `
                -AnsibleParams $module.Params `
                -CurrentObject $computerProfile
            if ($null -ne $module.Params.new_name) {
                $checkResult['name'] = $module.Params.new_name
            }
            if ($null -ne $module.Params.virtual_hard_disk) {
                $checkResult['os_boot_vhd'] = `
                    $module.Params.virtual_hard_disk
            }
            $module.Result.physical_computer_profile = `
                $checkResult
            $module.Diff.after = $checkResult
        }
        else {
            $module.Result.physical_computer_profile = `
                Get-ProfileResult `
                -InputObject $computerProfile `
                -PropertyMap $propertyMap
            $module.Diff.after = `
                $module.Result.physical_computer_profile
        }
    }
}
else {
    if ($computerProfile) {
        $module.Diff.before = Get-ProfileResult `
            -InputObject $computerProfile -PropertyMap $propertyMap
        $module.Diff.after = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                Remove-SCPhysicalComputerProfile `
                    -PhysicalComputerProfile $computerProfile `
                    -Force -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson(
                    "Failed to remove physical computer" +
                    " profile '$computerProfileName':" +
                    " $($_.Exception.Message)", $_
                )
            }
        }
    }
}

$module.ExitJson()
