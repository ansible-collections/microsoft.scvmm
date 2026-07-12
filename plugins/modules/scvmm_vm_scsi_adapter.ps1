#!powershell

# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        vm_name = @{ type = 'str'; required = $true }
        state = @{ type = 'str'; default = 'present'; choices = @('present', 'absent') }
        vmm_server = @{ type = 'str' }
        adapter_id = @{ type = 'int' }
        scsi_adapter_id = @{ type = 'str' }
        shared = @{ type = 'bool'; default = $false }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$vm_name = $module.Params.vm_name
$state = $module.Params.state
$vmm_server = $module.Params.vmm_server
$adapter_id = $module.Params.adapter_id
$scsi_adapter_id = $module.Params.scsi_adapter_id
$shared = $module.Params.shared

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "adapter_id"; Property = "AdapterID"; Type = "int" }
    @{ Param = "shared"; Property = "Shared"; Type = "bool" }
)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -VMMServer $vmm_server -Module $module

$vm = Get-SCVMMVirtualMachine -Module $module -VMMConnection $vmmConnection -Name $vm_name

$adapters = @(Get-SCVirtualScsiAdapter -VM $vm)

$existingAdapter = $null
if ($scsi_adapter_id) {
    $existingAdapter = $adapters | Where-Object { $_.ID.ToString() -eq $scsi_adapter_id } | Select-Object -First 1
}
elseif ($null -ne $adapter_id) {
    $existingAdapter = $adapters | Where-Object { $_.AdapterID -eq $adapter_id } | Select-Object -First 1
}

if ($state -eq 'present') {
    if ($null -eq $existingAdapter) {
        if (-not $module.CheckMode) {
            try {
                $newAdapter = New-SCVirtualScsiAdapter -VM $vm -ShareVirtualScsiAdapter $shared -ErrorAction Stop
            }
            catch {
                $module.FailJson("Failed to create SCSI adapter on VM '$vm_name': $($_.Exception.Message)", $_)
            }
            $module.Result.scsi_adapter = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $newAdapter
        }
        else {
            $module.Result.scsi_adapter = @{
                id = '00000000-0000-0000-0000-000000000000'
                adapter_id = $adapter_id
                shared = $shared
            }
        }
        $module.Result.changed = $true
    }
    else {
        if ($existingAdapter.Shared -ne $shared) {
            if (-not $module.CheckMode) {
                try {
                    $updatedAdapter = Set-SCVirtualScsiAdapter -VirtualScsiAdapter $existingAdapter -ShareVirtualScsiAdapter $shared -ErrorAction Stop
                }
                catch {
                    $module.FailJson("Failed to update SCSI adapter on VM '$vm_name': $($_.Exception.Message)", $_)
                }
                $module.Result.scsi_adapter = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $updatedAdapter
            }
            else {
                $module.Result.scsi_adapter = @{
                    id = $existingAdapter.ID.ToString()
                    adapter_id = $existingAdapter.AdapterID
                    shared = $shared
                }
            }
            $module.Result.changed = $true
        }
        else {
            $module.Result.scsi_adapter = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $existingAdapter
        }
    }
}
elseif ($state -eq 'absent') {
    if ($null -eq $scsi_adapter_id -and $null -eq $adapter_id) {
        $module.FailJson("One of adapter_id or scsi_adapter_id must be specified when state is absent")
    }
    if ($null -ne $existingAdapter) {
        if (-not $module.CheckMode) {
            try {
                Remove-SCVirtualScsiAdapter -VirtualScsiAdapter $existingAdapter -ErrorAction Stop
            }
            catch {
                $module.FailJson("Failed to remove SCSI adapter from VM '$vm_name': $($_.Exception.Message)", $_)
            }
        }
        $module.Result.changed = $true
    }
}

$module.ExitJson()
