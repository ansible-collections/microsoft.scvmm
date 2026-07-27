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

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{ Param = "bus_type"; Property = "BusType"; Type = "enum" }
    @{ Param = "bus"; Property = "Bus"; Type = "int" }
    @{ Param = "lun"; Property = "Lun"; Type = "int" }
    @{ Param = "shared_storage"; Property = "HasSharedStorage"; Type = "bool" }
    @{ Param = "volume_type"; Property = "VolumeType"; Type = "enum" }
    @{ Param = "iops_maximum"; Property = "IOPSMaximum"; Type = "int" }
    @{ Param = "create_diff_disk"; Property = "CreateDiffDisk"; Type = "bool" }
    @{ Param = "enabled"; Property = "Enabled"; Type = "bool" }
)

$vm = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCVirtualMachine' -Name $module.Params.vm_name `
    -ObjectType 'Virtual machine'
if (-not $vm) {
    $module.Result.disk_drives = @()
    $module.ExitJson()
}

$drives = @(Get-SCVirtualDiskDrive -VM $vm -ErrorAction Stop)

$module.Result.disk_drives = @($drives | ForEach-Object {
        $result = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
        $result['vm_name'] = if ($_.VM) { $_.VM.Name } else { $module.Params.vm_name }
        if ($_.VirtualHardDisk) {
            $result['vhd_name'] = $_.VirtualHardDisk.Name
            $result['vhd_location'] = $_.VirtualHardDisk.Location
            $result['vhd_format'] = $_.VirtualHardDisk.VHDFormatType.ToString()
            $result['vhd_type'] = $_.VirtualHardDisk.VHDType.ToString()
            $result['size_gb'] = [math]::Round($_.VirtualHardDisk.MaximumSize / 1GB, 2)
        }
        else {
            $result['vhd_name'] = $null
            $result['vhd_location'] = $null
            $result['vhd_format'] = $null
            $result['vhd_type'] = $null
            $result['size_gb'] = $null
        }
        $result
    })

$module.ExitJson()
