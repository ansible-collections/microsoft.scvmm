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

function Get-AdapterResult {
    param($Adapter, $VMName)
    return @{
        id = $Adapter.ID.ToString()
        name = $Adapter.Name
        vm_name = if ($Adapter.VM) { $Adapter.VM.Name } else { $VMName }
        vm_network = if ($Adapter.VMNetwork) { $Adapter.VMNetwork.Name } else { $null }
        mac_address = $Adapter.MACAddress
        mac_address_type = $Adapter.MACAddressType.ToString()
        ipv4_addresses = @($Adapter.IPv4Addresses)
        is_synthetic = -not $Adapter.IsEmulated
    }
}

$vm = Get-SCVirtualMachine -VMMServer $vmmConnection -Name $module.Params.vm_name -ErrorAction SilentlyContinue
if (-not $vm) {
    if ($module.Params.state -eq 'absent') {
        $module.ExitJson()
    }
    $module.FailJson("VM '$($module.Params.vm_name)' not found")
}

$adapters = @(Get-SCVirtualNetworkAdapter -VM $vm -ErrorAction Stop)

if ($module.Params.state -eq 'present') {
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
                $vmNet = Get-SCVMNetwork -VMMServer $vmmConnection -Name $module.Params.vm_network -ErrorAction Stop
                if (-not $vmNet) {
                    $module.FailJson("VM network '$($module.Params.vm_network)' not found")
                }
                $newParams['VMNetwork'] = $vmNet
            }
            else {
                $newParams['NoConnection'] = $true
            }
            if ($null -ne $module.Params.mac_address_type) {
                $newParams['MACAddressType'] = $module.Params.mac_address_type
            }
            if ($null -ne $module.Params.mac_address) {
                $newParams['MACAddress'] = $module.Params.mac_address
            }
            if ($null -ne $module.Params.ipv4_address_type) {
                $newParams['IPv4AddressType'] = $module.Params.ipv4_address_type
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
            vm_name = $module.Params.vm_name
            vm_network = $module.Params.vm_network
        }
        $module.Diff.after = $module.Result.network_adapter
    }
}
else {
    if ($adapters.Count -gt 0) {
        $targetAdapter = $adapters[-1]
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
