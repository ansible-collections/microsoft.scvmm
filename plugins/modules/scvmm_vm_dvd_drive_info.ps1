#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        vm_name = @{ type = 'str'; required = $true }
        vmm_server = @{ type = 'str' }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$vm_name = $module.Params.vm_name
$vmm_server = $module.Params.vmm_server

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "bus"; Property = "Bus"; Type = "int" }
    @{ Param = "lun"; Property = "LUN"; Type = "int" }
    @{ Param = "iso"; Property = "ISO"; Type = "nested_name" }
)

$vmmConnection = Connect-SCVMMServerSession -VMMServer $vmm_server -Module $module

$vm = Get-SCVMMVirtualMachine -Module $module -VMMConnection $vmmConnection -Name $vm_name

$dvdDrives = @(Get-SCVirtualDVDDrive -VM $vm -ErrorAction SilentlyContinue)

$module.Result.dvd_drives = @($dvdDrives | ForEach-Object {
        Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
    })

$module.ExitJson()
