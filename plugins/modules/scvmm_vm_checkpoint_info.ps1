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

$propertyMap = @(
    @{ Param = "id"; Property = "CheckpointID"; Type = "id" }
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "creation_time"; Property = "AddedTime"; Type = "datetime_iso" }
)

$vmmConnection = Connect-SCVMMServerSession -VMMServer $vmm_server -Module $module

$vm = Get-SCVMMVirtualMachine -Module $module -VMMConnection $vmmConnection -Name $vm_name

$checkpoints = @(Get-SCVMCheckpoint -VM $vm -ErrorAction SilentlyContinue)

if ($name) {
    $checkpoints = @($checkpoints | Where-Object { $_.Name -eq $name })
}

$module.Result.checkpoints = @($checkpoints | ForEach-Object {
        Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
    })

$module.ExitJson()
