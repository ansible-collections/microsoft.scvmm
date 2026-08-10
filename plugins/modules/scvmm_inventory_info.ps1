#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str' }
        cloud = @{ type = 'str' }
        host_group = @{ type = 'str' }
        status = @{
            type = 'str'
            choices = @(
                'Running', 'PowerOff', 'Stopped', 'Paused', 'MissingSharedStorage',
                'IncompleteVMConfig', 'UnderCreation', 'CreationFailed',
                'Stored', 'UnderTemplateCreation', 'TemplateCreationFailed',
                'CustomizationFailed', 'UnderUpdate', 'UpdateFailed',
                'UnderMigration'
            )
        }
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
    @{ Param = "status"; Property = "Status"; Type = "enum" }
    @{ Param = "owner"; Property = "Owner"; Type = "string" }
    @{ Param = "host_name"; Property = "VMHost"; Type = "nested_name" }
    @{ Param = "cloud"; Property = "Cloud"; Type = "nested_name" }
    @{ Param = "cpu_count"; Property = "CPUCount"; Type = "int" }
    @{ Param = "memory_mb"; Property = "Memory"; Type = "int" }
    @{ Param = "operating_system"; Property = "OperatingSystem"; Type = "nested_name" }
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "creation_time"; Property = "CreationTime"; Type = "datetime_iso" }
)

try {
    $getParams = @{
        VMMServer = $vmmConnection
        ErrorAction = 'Stop'
    }

    if ($module.Params.name) {
        $getParams['Name'] = $module.Params.name
    }

    if ($module.Params.cloud) {
        $cloudObj = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
            -CmdletName 'Get-SCCloud' -Name $module.Params.cloud `
            -ObjectType 'cloud' -FailIfNotFound $true
        $getParams['Cloud'] = $cloudObj
    }

    $vms = @(Get-SCVirtualMachine @getParams)

    if ($module.Params.host_group) {
        $hostGroupObj = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
            -CmdletName 'Get-SCVMHostGroup' -Name $module.Params.host_group `
            -ObjectType 'host group' -FailIfNotFound $true
        $groupHosts = @(Get-SCVMHost -VMHostGroup $hostGroupObj -ErrorAction Stop)
        $hostNames = @($groupHosts | ForEach-Object { $_.Name })
        $vms = @($vms | Where-Object {
                $_.VMHost -and $_.VMHost.Name -in $hostNames
            })
    }

    if ($module.Params.status) {
        $vms = @($vms | Where-Object { $_.Status.ToString() -eq $module.Params.status })
    }
}
catch {
    $module.FailJson("Failed to query virtual machines: $($_.Exception.Message)", $_)
}

$module.Result.virtual_machines = @(
    if ($vms.Count -gt 0) {
        $vms | ForEach-Object {
            $result = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_

            $result['host_group'] = if ($_.VMHost -and $_.VMHost.VMHostGroup) {
                $_.VMHost.VMHostGroup.Name
            }
            else {
                $null
            }

            $adapters = @()
            try {
                $adapters = @(Get-SCVirtualNetworkAdapter -VM $_ -ErrorAction Stop)
            }
            catch {
                $module.Warn("Failed to query network adapters for VM '$($result['name'])': $($_.Exception.Message)")
            }
            $allIps = @()
            $adapterList = @(
                if ($adapters.Count -gt 0) {
                    $adapters | ForEach-Object {
                        $adapterIps = @($_.IPv4Addresses | Where-Object { $_ })
                        $allIps += $adapterIps
                        @{
                            name = if ($_.Name) { [string]$_.Name } else { $null }
                            vm_network = if ($_.VMNetwork) { $_.VMNetwork.Name } else { $null }
                            mac_address = if ($_.MACAddress) { [string]$_.MACAddress } else { $null }
                            ipv4_addresses = $adapterIps
                        }
                    }
                }
            )

            $result['ipv4_addresses'] = @($allIps | Where-Object { $_ })
            $result['network_adapters'] = $adapterList
            $result
        }
    }
)

$module.ExitJson()
