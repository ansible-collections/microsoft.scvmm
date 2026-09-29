#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        template_name = @{ type = 'str'; required = $true }
        vm_network = @{ type = 'str'; required = $true }
        vm_subnet = @{ type = 'str' }
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
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{ Param = "vm_network"; Property = "VMNetwork"; Type = "nested_name" }
    @{ Param = "vm_subnet"; Property = "VMSubnet"; Type = "nested_name" }
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

function Get-TemplateNicResult {
    param($Adapter, $TemplateName)
    $result = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $Adapter
    $result['template_name'] = $TemplateName
    $result['is_synthetic'] = -not $Adapter.IsEmulated
    return $result
}

$template = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCVMTemplate' -Name $module.Params.template_name `
    -ObjectType 'VM template' -FailIfNotFound $true

$adapter = @(Get-SCVirtualNetworkAdapter -Template $template -ErrorAction Stop) | Select-Object -First 1

if (-not $adapter) {
    $module.FailJson("No network adapter found on VM template '$($module.Params.template_name)'")
}

$module.Diff.before = Get-TemplateNicResult -Adapter $adapter -TemplateName $module.Params.template_name

$setParams = @{}
$needsUpdate = $false

# Rebind the adapter to the requested VM network (and subnet). SCVMM requires the subnet
# to be supplied alongside the network when moving an adapter across networks on a
# logical-switch fabric, so both are set together whenever either differs.
$currentNetwork = if ($adapter.VMNetwork) { $adapter.VMNetwork.Name } else { $null }
$currentSubnet = if ($adapter.VMSubnet) { $adapter.VMSubnet.Name } else { $null }

if ($currentNetwork -ne $module.Params.vm_network -or
    ($module.Params.vm_subnet -and $currentSubnet -ne $module.Params.vm_subnet)) {
    $needsUpdate = $true

    $networkObject = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCVMNetwork' -Name $module.Params.vm_network `
        -ObjectType 'VM network' -FailIfNotFound $true
    $setParams['VMNetwork'] = $networkObject

    if ($module.Params.vm_subnet) {
        $subnetObject = Get-SCVMSubnet -VMNetwork $networkObject -Name $module.Params.vm_subnet -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if (-not $subnetObject) {
            $module.FailJson("VM subnet '$($module.Params.vm_subnet)' not found in VM network '$($module.Params.vm_network)'")
        }
        $setParams['VMSubnet'] = $subnetObject
    }
    else {
        # SCVMM requires a subnet when rebinding on a logical-switch fabric; default to
        # the network's first subnet when the caller did not name one.
        $subnetObject = Get-SCVMSubnet -VMNetwork $networkObject -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($subnetObject) {
            $setParams['VMSubnet'] = $subnetObject
        }
    }
}

if (Test-SCVMMPropertiesChanged -PropertyMap $updateMap -CurrentObject $adapter -AnsibleParams $module.Params) {
    $needsUpdate = $true
    $mapParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap `
        -AnsibleParams $module.Params -CurrentObject $adapter
    foreach ($key in $mapParams.Keys) {
        $setParams[$key] = $mapParams[$key]
    }
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
            $module.FailJson("Failed to update network adapter on VM template '$($module.Params.template_name)': $($_.Exception.Message)", $_)
        }
    }
}

$module.Result.template_nic = Get-TemplateNicResult -Adapter $adapter -TemplateName $module.Params.template_name

if ($needsUpdate -and $module.CheckMode) {
    $projected = Get-SCVMMCheckModeDiff -Before $module.Diff.before `
        -UpdateMap $updateMap -AnsibleParams $module.Params `
        -CurrentObject $adapter
    $projected['vm_network'] = $module.Params.vm_network
    if ($module.Params.vm_subnet) {
        $projected['vm_subnet'] = $module.Params.vm_subnet
    }
    if ($null -ne $module.Params.port_classification) {
        $projected['port_classification'] = $module.Params.port_classification
    }
    $module.Diff.after = $projected
}
else {
    $module.Diff.after = $module.Result.template_nic
}

$module.ExitJson()
