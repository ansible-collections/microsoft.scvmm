#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        vm_name = @{ type = 'str'; required = $true }
        bus_type = @{
            type = 'str'
            default = 'scsi'
            choices = @('ide', 'scsi')
        }
        bus = @{ type = 'int'; default = 0 }
        lun = @{ type = 'int'; default = 0 }
        state = @{
            type = 'str'
            default = 'present'
            choices = @('present', 'absent')
        }
        vhd_name = @{ type = 'str' }
        size_gb = @{ type = 'int' }
        vhd_format = @{
            type = 'str'
            choices = @('VHDX', 'VHD')
        }
        vhd_type = @{
            type = 'str'
            choices = @('Dynamic', 'Fixed')
        }
        path = @{ type = 'str' }
        file_name = @{ type = 'str' }
        shared_storage = @{ type = 'bool' }
        volume_type = @{
            type = 'str'
            choices = @('Boot', 'System', 'None')
        }
        iops_maximum = @{ type = 'int' }
        compress = @{ type = 'bool'; default = $false }
        convert_to_format = @{
            type = 'str'
            choices = @('VHDX', 'VHD')
        }
        convert_to_type = @{
            type = 'str'
            choices = @('Dynamic', 'Fixed')
        }
        validate = @{ type = 'bool'; default = $false }
        delete_vhd = @{ type = 'bool'; default = $false }
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

$updateMap = @(
    @{ Param = "volume_type"; Property = "VolumeType"; Type = "enum" }
    @{ Param = "iops_maximum"; Property = "IOPSMaximum"; Type = "int" }
    @{ Param = "shared_storage"; Property = "HasSharedStorage"; Type = "bool"; CmdletParam = "SharedStorage" }
)

$vhdTypeToEnum = @{ 'Dynamic' = 'DynamicallyExpanding'; 'Fixed' = 'FixedSize' }

function Get-DiskResult {
    param($Drive, $VMName)
    $result = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $Drive
    $result['vm_name'] = if ($Drive.VM) { $Drive.VM.Name } else { $VMName }
    if ($Drive.VirtualHardDisk) {
        $result['vhd_name'] = $Drive.VirtualHardDisk.Name
        $result['vhd_location'] = $Drive.VirtualHardDisk.Location
        $result['vhd_format'] = $Drive.VirtualHardDisk.VHDFormatType.ToString()
        $result['vhd_type'] = $Drive.VirtualHardDisk.VHDType.ToString()
        $result['size_gb'] = [math]::Round($Drive.VirtualHardDisk.MaximumSize / 1GB, 2)
    }
    else {
        $result['vhd_name'] = $null
        $result['vhd_location'] = $null
        $result['vhd_format'] = $null
        $result['vhd_type'] = $null
        $result['size_gb'] = $null
    }
    return $result
}

$vm = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCVirtualMachine' -Name $module.Params.vm_name `
    -ObjectType 'Virtual machine' -FailIfNotFound ($module.Params.state -ne 'absent')
if (-not $vm) {
    $module.ExitJson()
}

$drives = @(Get-SCVirtualDiskDrive -VM $vm -ErrorAction Stop)
$busTypeUpper = $module.Params.bus_type.ToUpper()
$existingDrive = $drives | Where-Object {
    $_.BusType.ToString() -eq $busTypeUpper -and $_.Bus -eq $module.Params.bus -and $_.Lun -eq $module.Params.lun
} | Select-Object -First 1

if ($module.Params.state -eq 'present') {
    if ($module.Params.delete_vhd) {
        $module.Warn("'delete_vhd' has no effect when state=present and will be ignored")
    }
    if (-not $existingDrive) {
        if (-not $module.Params.vhd_name -and -not $module.Params.size_gb) {
            $module.FailJson("One of 'vhd_name' or 'size_gb' must be specified to create a new disk drive")
        }

        $module.Diff.before = @{}
        $module.Result.changed = $true

        if (-not $module.CheckMode) {
            $newParams = @{
                VM = $vm
                Bus = $module.Params.bus
                LUN = $module.Params.lun
                ErrorAction = 'Stop'
            }
            if ($module.Params.bus_type -eq 'ide') {
                $newParams['IDE'] = $true
            }
            else {
                $newParams['SCSI'] = $true
            }

            if ($module.Params.vhd_name) {
                $vhdName = $module.Params.vhd_name
                $vhd = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
                    -CmdletName 'Get-SCVirtualHardDisk' -Name $vhdName `
                    -ObjectType 'virtual hard disk' `
                    -FilterScript { $_.Name -eq $vhdName } -FailIfNotFound $true
                $newParams['VirtualHardDisk'] = $vhd
            }
            else {
                $newParams['VirtualHardDiskSizeMB'] = $module.Params.size_gb * 1024
                if ($module.Params.vhd_type -eq 'Fixed') {
                    $newParams['Fixed'] = $true
                }
                else {
                    $newParams['Dynamic'] = $true
                }
                if ($module.Params.vhd_format) {
                    $newParams['VirtualHardDiskFormatType'] = $module.Params.vhd_format
                }
                if ($module.Params.file_name) {
                    $newParams['FileName'] = $module.Params.file_name
                }
                else {
                    $newParams['FileName'] = "$($module.Params.vm_name)_disk_$($module.Params.bus)_$($module.Params.lun)"
                }
                if ($module.Params.path) {
                    $newParams['Path'] = $module.Params.path
                }
            }

            if ($null -ne $module.Params.shared_storage -and $module.Params.shared_storage) {
                $newParams['SharedStorage'] = $true
            }
            if ($module.Params.volume_type) {
                $newParams['VolumeType'] = $module.Params.volume_type
            }

            try {
                $existingDrive = New-SCVirtualDiskDrive @newParams
            }
            catch {
                $module.FailJson("Failed to create disk drive on VM '$($module.Params.vm_name)': $($_.Exception.Message)", $_)
            }
        }

        if ($existingDrive) {
            $module.Result.vm_disk = Get-DiskResult -Drive $existingDrive -VMName $module.Params.vm_name
            $module.Diff.after = $module.Result.vm_disk
        }
        else {
            $module.Result.vm_disk = @{
                id = $null
                name = $null
                vm_name = $module.Params.vm_name
                bus_type = $busTypeUpper
                bus = $module.Params.bus
                lun = $module.Params.lun
                vhd_name = $module.Params.vhd_name
                vhd_location = $null
                vhd_format = if ($module.Params.vhd_format) { $module.Params.vhd_format } else { 'VHDX' }
                vhd_type = if ($module.Params.vhd_type) { $vhdTypeToEnum[$module.Params.vhd_type] } else { 'DynamicallyExpanding' }
                size_gb = $module.Params.size_gb
                shared_storage = if ($null -ne $module.Params.shared_storage) { $module.Params.shared_storage } else { $false }
                volume_type = if ($module.Params.volume_type) { $module.Params.volume_type } else { 'None' }
                iops_maximum = 0
                create_diff_disk = $false
                enabled = $true
            }
            $module.Diff.after = $module.Result.vm_disk
        }
    }
    else {
        $module.Diff.before = Get-DiskResult -Drive $existingDrive -VMName $module.Params.vm_name

        $needsUpdate = Test-SCVMMPropertiesChanged -PropertyMap $updateMap `
            -CurrentObject $existingDrive -AnsibleParams $module.Params

        if ($needsUpdate) {
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                $setParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap `
                    -AnsibleParams $module.Params -CurrentObject $existingDrive
                $setParams['VirtualDiskDrive'] = $existingDrive
                $setParams['ErrorAction'] = 'Stop'
                try {
                    $existingDrive = Set-SCVirtualDiskDrive @setParams
                }
                catch {
                    $module.FailJson("Failed to update disk drive: $($_.Exception.Message)", $_)
                }
            }
        }

        if (-not $existingDrive.VirtualHardDisk) {
            $slot = "${busTypeUpper}:$($module.Params.bus):$($module.Params.lun)"
            $reason = "no virtual hard disk attached (pass-through disk)"
            if ($null -ne $module.Params.size_gb) {
                $module.Warn("Cannot expand disk drive at $slot - $reason")
            }
            if ($module.Params.compress) {
                $module.Warn("Cannot compress disk drive at $slot - $reason")
            }
            if ($module.Params.convert_to_format -or $module.Params.convert_to_type) {
                $module.Warn("Cannot convert disk drive at $slot - $reason")
            }
        }

        if ($null -ne $module.Params.size_gb -and $existingDrive.VirtualHardDisk) {
            $currentSizeGb = [math]::Round($existingDrive.VirtualHardDisk.MaximumSize / 1GB, 2)
            if ($module.Params.size_gb -gt $currentSizeGb) {
                $module.Result.changed = $true
                if (-not $module.CheckMode) {
                    try {
                        $existingDrive = Expand-SCVirtualDiskDrive -VirtualDiskDrive $existingDrive `
                            -VirtualHardDiskSizeGB $module.Params.size_gb -ErrorAction Stop
                    }
                    catch {
                        $module.FailJson("Failed to expand disk drive: $($_.Exception.Message)", $_)
                    }
                }
            }
            elseif ($module.Params.size_gb -lt $currentSizeGb) {
                $module.FailJson("Cannot shrink disk from $currentSizeGb GB to $($module.Params.size_gb) GB. Only expansion is supported.")
            }
        }

        if ($module.Params.compress) {
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                try {
                    Compress-SCVirtualDiskDrive -VirtualDiskDrive $existingDrive -ErrorAction Stop | Out-Null
                    $drives = @(Get-SCVirtualDiskDrive -VM $vm -ErrorAction Stop)
                    $existingDrive = $drives | Where-Object {
                        $_.BusType.ToString() -eq $busTypeUpper -and $_.Bus -eq $module.Params.bus -and $_.Lun -eq $module.Params.lun
                    } | Select-Object -First 1
                }
                catch {
                    $module.FailJson("Failed to compress disk drive: $($_.Exception.Message)", $_)
                }
            }
        }

        if ($module.Params.convert_to_format -or $module.Params.convert_to_type) {
            $needsConvert = $false
            $convertParams = @{
                VirtualDiskDrive = $existingDrive
                ErrorAction = 'Stop'
            }

            if ($module.Params.convert_to_format -and $existingDrive.VirtualHardDisk) {
                $currentFormat = $existingDrive.VirtualHardDisk.VHDFormatType.ToString()
                if ($currentFormat -ne $module.Params.convert_to_format) {
                    $convertParams['VHDFormatType'] = $module.Params.convert_to_format
                    $needsConvert = $true
                }
            }

            if ($module.Params.convert_to_type -and $existingDrive.VirtualHardDisk) {
                $currentType = $existingDrive.VirtualHardDisk.VHDType.ToString()
                $currentTypeSimple = if ($currentType -like 'Dynamic*') { 'Dynamic' } elseif ($currentType -like 'Fixed*') { 'Fixed' } else { $currentType }
                if ($currentTypeSimple -ne $module.Params.convert_to_type) {
                    if ($module.Params.convert_to_type -eq 'Dynamic') {
                        $convertParams['Dynamic'] = $true
                    }
                    else {
                        $convertParams['Fixed'] = $true
                    }
                    $needsConvert = $true
                }
            }

            if ($needsConvert) {
                $module.Result.changed = $true
                if (-not $module.CheckMode) {
                    try {
                        Convert-SCVirtualDiskDrive @convertParams | Out-Null
                        $drives = @(Get-SCVirtualDiskDrive -VM $vm -ErrorAction Stop)
                        $existingDrive = $drives | Where-Object {
                            $_.BusType.ToString() -eq $busTypeUpper -and $_.Bus -eq $module.Params.bus -and $_.Lun -eq $module.Params.lun
                        } | Select-Object -First 1
                    }
                    catch {
                        $module.FailJson("Failed to convert disk drive: $($_.Exception.Message)", $_)
                    }
                }
            }
        }

        if ($module.Params.validate) {
            if (-not $module.CheckMode) {
                try {
                    Test-SCVirtualDiskDrive -VirtualDiskDrive $existingDrive -ErrorAction Stop | Out-Null
                    $module.Result.validation = "passed"
                }
                catch {
                    $module.FailJson("Disk drive validation failed: $($_.Exception.Message)", $_)
                }
            }
        }

        $module.Result.vm_disk = Get-DiskResult -Drive $existingDrive -VMName $module.Params.vm_name

        if ($module.Result.changed -and $module.CheckMode) {
            $projected = Get-SCVMMCheckModeDiff -Before $module.Diff.before `
                -UpdateMap $updateMap -AnsibleParams $module.Params `
                -CurrentObject $existingDrive
            if ($null -ne $module.Params.size_gb -and $projected.size_gb) {
                if ($module.Params.size_gb -gt $projected.size_gb) {
                    $projected['size_gb'] = $module.Params.size_gb
                }
            }
            if ($module.Params.convert_to_format) { $projected['vhd_format'] = $module.Params.convert_to_format }
            if ($module.Params.convert_to_type) { $projected['vhd_type'] = $vhdTypeToEnum[$module.Params.convert_to_type] }
            $module.Diff.after = $projected
            $module.Result.vm_disk = $projected
        }
        else {
            $module.Diff.after = $module.Result.vm_disk
        }
    }
}
else {
    if ($existingDrive) {
        $module.Diff.before = Get-DiskResult -Drive $existingDrive -VMName $module.Params.vm_name
        $module.Diff.after = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            $removeParams = @{
                VirtualDiskDrive = $existingDrive
                ErrorAction = 'Stop'
            }
            if (-not $module.Params.delete_vhd) {
                $removeParams['SkipDeleteVHD'] = $true
            }
            try {
                Remove-SCVirtualDiskDrive @removeParams | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove disk drive from VM '$($module.Params.vm_name)': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
