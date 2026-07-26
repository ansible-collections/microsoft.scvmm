#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        vm_name = @{ type = 'str'; required = $true }
        vm_network = @{ type = 'str'; required = $true }
        mac_address_type = @{
            type = 'str'
            choices = @('Static', 'Dynamic')
        }
        mac_address = @{ type = 'str' }
        ipv4_address_type = @{
            type = 'str'
            choices = @('Static', 'Dynamic')
        }
        vlan_enabled = @{ type = 'bool' }
        vlan_id = @{ type = 'int' }
        port_classification = @{ type = 'str' }
        vmm_server = @{ type = 'str' }
    }
    required_one_of = @(, @('mac_address_type', 'mac_address', 'ipv4_address_type', 'vlan_enabled', 'vlan_id', 'port_classification'))
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{ Param = "vm_network"; Property = "VMNetwork"; Type = "nested_name" }
    @{ Param = "mac_address"; Property = "MACAddress"; Type = "string" }
    @{ Param = "mac_address_type"; Property = "MACAddressType"; Type = "enum" }
    @{ Param = "vlan_enabled"; Property = "VlanEnabled"; Type = "bool" }
    @{ Param = "vlan_id"; Property = "VLanID"; Type = "int" }
    @{ Param = "port_classification"; Property = "PortClassification"; Type = "nested_name" }
)

$updateMap = @(
    @{ Param = "mac_address_type"; Property = "MACAddressType"; Type = "enum" }
    @{ Param = "mac_address"; Property = "MACAddress"; Type = "string" }
    @{ Param = "ipv4_address_type"; Property = "IPv4AddressType"; Type = "enum" }
    @{ Param = "vlan_enabled"; Property = "VlanEnabled"; Type = "bool" }
    @{ Param = "vlan_id"; Property = "VLanID"; Type = "int" }
)

function Get-NicResult {
    param($Adapter, $VMName)
    $result = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $Adapter
    $result['vm_name'] = if ($Adapter.VM) { $Adapter.VM.Name } else { $VMName }
    $result['ipv4_addresses'] = @($Adapter.IPv4Addresses)
    $result['is_synthetic'] = -not $Adapter.IsEmulated
    return $result
}

$vm = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCVirtualMachine' -Name $module.Params.vm_name `
    -ObjectType 'Virtual machine' -FailIfNotFound $true

$adapters = @(Get-SCVirtualNetworkAdapter -VM $vm -ErrorAction Stop)

$adapter = $adapters | Where-Object {
    $_.VMNetwork -and $_.VMNetwork.Name -eq $module.Params.vm_network
} | Select-Object -First 1

if (-not $adapter) {
    $module.FailJson("No network adapter connected to VM network '$($module.Params.vm_network)' found on VM '$($module.Params.vm_name)'")
}

$module.Diff.before = Get-NicResult -Adapter $adapter -VMName $module.Params.vm_name

$needsUpdate = Test-SCVMMPropertiesChanged -PropertyMap $updateMap `
    -CurrentObject $adapter -AnsibleParams $module.Params
$setParams = @{}

if ($needsUpdate) {
    $setParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap `
        -AnsibleParams $module.Params -CurrentObject $adapter
}

if ($null -ne $module.Params.port_classification) {
    $currentPC = if ($adapter.PortClassification) { $adapter.PortClassification.Name } else { $null }
    if ($currentPC -ne $module.Params.port_classification) {
        $needsUpdate = $true
        $pc = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
            -CmdletName 'Get-SCPortClassification' -Name $module.Params.port_classification `
            -ObjectType 'Port classification' -FailIfNotFound $true
        $setParams['PortClassification'] = $pc
    }
}

if ($needsUpdate) {
    $module.Result.changed = $true
    if (-not $module.CheckMode) {
        $setParams['VirtualNetworkAdapter'] = $adapter
        $setParams['ErrorAction'] = 'Stop'
        try {
            $adapter = Set-SCVirtualNetworkAdapter @setParams
        }
        catch {
            $module.FailJson("Failed to update network adapter on VM '$($module.Params.vm_name)': $($_.Exception.Message)", $_)
        }
    }
}

$module.Result.vm_nic = Get-NicResult -Adapter $adapter -VMName $module.Params.vm_name

if ($needsUpdate -and $module.CheckMode) {
    $projected = Get-SCVMMCheckModeDiff -Before $module.Diff.before `
        -UpdateMap $updateMap -AnsibleParams $module.Params `
        -CurrentObject $adapter
    if ($null -ne $module.Params.port_classification) {
        $projected['port_classification'] = $module.Params.port_classification
    }
    $module.Diff.after = $projected
}
else {
    $module.Diff.after = $module.Result.vm_nic
}

$module.ExitJson()
