#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        vm_name = @{ type = 'str'; required = $true }
        vm_network = @{ type = 'str' }
        mac_address_type = @{
            type = 'str'
            choices = @('Static', 'Dynamic')
        }
        mac_address = @{ type = 'str' }
        ipv4_address_type = @{
            type = 'str'
            choices = @('Static', 'Dynamic')
        }
        synthetic = @{ type = 'bool'; default = $true }
        state = @{
            type = 'str'
            default = 'present'
            choices = @('present', 'absent')
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
    @{ Param = "vm_network"; Property = "VMNetwork"; Type = "nested_name" }
    @{ Param = "mac_address"; Property = "MACAddress"; Type = "string" }
    @{ Param = "mac_address_type"; Property = "MACAddressType"; Type = "enum" }
)

$createMap = @(
    @{ Param = "mac_address_type"; Property = "MACAddressType"; Type = "enum" }
    @{ Param = "mac_address"; Property = "MACAddress"; Type = "string" }
    @{ Param = "ipv4_address_type"; Property = "IPv4AddressType"; Type = "enum" }
)

function Get-AdapterResult {
    param($Adapter, $VMName)
    $result = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $Adapter
    $result['vm_name'] = if ($Adapter.VM) { $Adapter.VM.Name } else { $VMName }
    $result['ipv4_addresses'] = @($Adapter.IPv4Addresses)
    $result['is_synthetic'] = -not $Adapter.IsEmulated
    return $result
}

$vm = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCVirtualMachine' -Name $module.Params.vm_name `
    -ObjectType 'Virtual machine' -FailIfNotFound ($module.Params.state -ne 'absent')
if (-not $vm) {
    $module.ExitJson()
}

$adapters = @(Get-SCVirtualNetworkAdapter -VM $vm -ErrorAction Stop)

$existingAdapter = $null
if ($module.Params.vm_network) {
    $existingAdapter = $adapters | Where-Object {
        $_.VMNetwork -and $_.VMNetwork.Name -eq $module.Params.vm_network
    } | Select-Object -First 1
}

if ($module.Params.state -eq 'present') {
    if ($null -eq $existingAdapter) {
        $module.Diff.before = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                $newParams = @{
                    VM = $vm
                    Synthetic = $module.Params.synthetic
                    ErrorAction = 'Stop'
                }
                if ($module.Params.vm_network) {
                    $vmNet = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
                        -CmdletName 'Get-SCVMNetwork' -Name $module.Params.vm_network `
                        -ObjectType 'VM network' -FailIfNotFound $true
                    $newParams['VMNetwork'] = $vmNet
                }
                else {
                    $newParams['NoConnection'] = $true
                }
                $createParams = Get-SCVMMParametersFromMap -PropertyMap $createMap -AnsibleParams $module.Params
                foreach ($key in $createParams.Keys) {
                    $newParams[$key] = $createParams[$key]
                }

                $adapter = New-SCVirtualNetworkAdapter @newParams
                $module.Result.network_adapter = Get-AdapterResult -Adapter $adapter -VMName $module.Params.vm_name
                $module.Diff.after = $module.Result.network_adapter
            }
            catch {
                $module.FailJson("Failed to add network adapter to VM '$($module.Params.vm_name)': $($_.Exception.Message)", $_)
            }
        }
        else {
            $module.Result.network_adapter = @{
                id = $null
                name = $null
                vm_name = $module.Params.vm_name
                vm_network = $module.Params.vm_network
                mac_address = $module.Params.mac_address
                mac_address_type = $module.Params.mac_address_type
                ipv4_addresses = @()
                is_synthetic = $module.Params.synthetic
            }
            $module.Diff.after = $module.Result.network_adapter
        }
    }
    else {
        $module.Result.network_adapter = Get-AdapterResult -Adapter $existingAdapter -VMName $module.Params.vm_name
    }
}
else {
    if ($module.Params.vm_network) {
        $targetAdapter = $existingAdapter
    }
    else {
        $targetAdapter = $adapters | Select-Object -Last 1
    }
    if ($targetAdapter) {
        $module.Diff.before = Get-AdapterResult -Adapter $targetAdapter -VMName $module.Params.vm_name
        $module.Diff.after = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                Remove-SCVirtualNetworkAdapter -VirtualNetworkAdapter $targetAdapter -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove network adapter from VM '$($module.Params.vm_name)': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
