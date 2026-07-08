#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        vm_name = @{ type = 'str'; required = $true }
        name = @{ type = 'str' }
        vmm_server = @{ type = 'str' }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$vm_name = $module.Params.vm_name
$name = $module.Params.name
$vmm_server = $module.Params.vmm_server

$vmmConnection = Connect-SCVMMServerSession -VMMServer $vmm_server -Module $module

$vms = @(Get-SCVirtualMachine -VMMServer $vmmConnection -Name $vm_name -ErrorAction Stop)
if ($vms.Count -eq 0) {
    $module.FailJson("Virtual machine '$vm_name' not found")
}
if ($vms.Count -gt 1) {
    $module.FailJson("Multiple virtual machines found with name '$vm_name'. VM names are not guaranteed to be unique in SCVMM.")
}
$vm = $vms[0]

$checkpoints = @(Get-SCVMCheckpoint -VM $vm -ErrorAction SilentlyContinue)

if ($name) {
    $checkpoints = @($checkpoints | Where-Object { $_.Name -eq $name })
}

$module.Result.checkpoints = @($checkpoints | ForEach-Object {
        @{
            id = $_.CheckpointID.ToString()
            name = $_.Name
            description = $_.Description
            creation_time = $_.AddedTime.ToString('o')
        }
    })

$module.ExitJson()
