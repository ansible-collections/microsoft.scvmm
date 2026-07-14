#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        vm_host = @{ type = 'str'; required = $true }
        adapter_name = @{ type = 'str'; required = $true }
        logical_network = @{ type = 'str' }
        logical_network_action = @{ type = 'str'; choices = @('set', 'remove') }
        description = @{ type = 'str' }
        available_for_placement = @{ type = 'bool' }
        vmm_server = @{ type = 'str' }
    }
    required_by = @{ logical_network_action = 'logical_network' }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

# Get the host
try {
    $vmHost = Get-SCVMHost -VMMServer $vmmConnection -ComputerName $module.Params.vm_host -ErrorAction Stop
}
catch {
    $module.FailJson("Failed to query host '$($module.Params.vm_host)': $($_.Exception.Message)", $_)
}
if ($null -eq $vmHost) {
    $module.FailJson("VM host '$($module.Params.vm_host)' not found")
}

# Get the adapter
$adapterName = $module.Params.adapter_name
try {
    $adapters = @(Get-SCVMHostNetworkAdapter -VMHost $vmHost -ErrorAction Stop)
}
catch {
    $module.FailJson("Failed to query network adapters on host '$($module.Params.vm_host)': $($_.Exception.Message)", $_)
}
$matchedAdapters = @($adapters | Where-Object { $_.Name -eq $adapterName })
if ($matchedAdapters.Count -gt 1) {
    $module.FailJson("Multiple adapters found with name '$adapterName' on host '$($module.Params.vm_host)'")
}
if ($matchedAdapters.Count -eq 0) {
    $module.FailJson("Network adapter '$adapterName' not found on host '$($module.Params.vm_host)'")
}
$adapter = $matchedAdapters[0]

$resultMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{ Param = "connection_name"; Property = "ConnectionName"; Type = "string" }
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "logical_networks"; Property = "LogicalNetworks"; Type = "name_list" }
    @{ Param = "available_for_placement"; Property = "AvailableForPlacement"; Type = "bool" }
)

$updateMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "available_for_placement"; Property = "AvailableForPlacement"; Type = "bool" }
)

function Get-AdapterResultFull {
    param($Adapter)
    $result = Get-SCVMMResultFromMap -PropertyMap $resultMap -CurrentObject $Adapter
    $result['vm_host'] = [string]$Adapter.VMHost.FQDN
    return $result
}

$module.Diff.before = Get-AdapterResultFull -Adapter $adapter

$setParams = @{}
$needsUpdate = $false

# Check logical network (custom — add/remove pattern doesn't fit property map)
if ($null -ne $module.Params.logical_network) {
    $logicalNetworkName = $module.Params.logical_network
    $logicalNetwork = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCLogicalNetwork' -Name $logicalNetworkName `
        -ObjectType 'logical network' -FailIfNotFound $true

    $currentNetworks = @($adapter.LogicalNetworks | ForEach-Object { $_.Name })
    $action = if ($module.Params.logical_network_action) { $module.Params.logical_network_action } else { 'set' }

    if ($action -eq 'set') {
        if ($logicalNetworkName -notin $currentNetworks) {
            $setParams['AddOrSetLogicalNetwork'] = $logicalNetwork
            $needsUpdate = $true
        }
    }
    else {
        if ($logicalNetworkName -in $currentNetworks) {
            $setParams['RemoveLogicalNetwork'] = $logicalNetwork
            $needsUpdate = $true
        }
    }
}

# Check standard properties
$propsChanged = Test-SCVMMPropertiesChanged -PropertyMap $updateMap -CurrentObject $adapter -AnsibleParams $module.Params
if ($propsChanged) {
    $propParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap -AnsibleParams $module.Params -CurrentObject $adapter
    foreach ($key in $propParams.Keys) {
        $setParams[$key] = $propParams[$key]
    }
    $needsUpdate = $true
}

if ($needsUpdate) {
    $module.Result.changed = $true
    if (-not $module.CheckMode) {
        try {
            $adapter = Set-SCVMHostNetworkAdapter -VMHostNetworkAdapter $adapter @setParams -ErrorAction Stop
        }
        catch {
            $module.FailJson("Failed to update adapter: $($_.Exception.Message)", $_)
        }
    }
}

$module.Result.adapter = Get-AdapterResultFull -Adapter $adapter
if ($needsUpdate) {
    if ($module.CheckMode) {
        $projected = Get-SCVMMCheckModeDiff -Before $module.Diff.before -UpdateMap $updateMap -AnsibleParams $module.Params -CurrentObject $adapter
        # Project logical network changes manually
        if ($null -ne $module.Params.logical_network) {
            $networks = [System.Collections.ArrayList]@($projected['logical_networks'])
            $projAction = if ($module.Params.logical_network_action) { $module.Params.logical_network_action } else { 'set' }
            if ($projAction -eq 'set') {
                if ($module.Params.logical_network -notin $networks) {
                    $null = $networks.Add($module.Params.logical_network)
                }
            }
            else {
                $null = $networks.Remove($module.Params.logical_network)
            }
            $projected['logical_networks'] = @($networks)
        }
        $module.Diff.after = $projected
    }
    else {
        $module.Diff.after = $module.Result.adapter
    }
}
else {
    $module.Diff.after = $module.Diff.before
}

$module.ExitJson()
