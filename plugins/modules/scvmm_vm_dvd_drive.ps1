#!powershell

# Copyright: (c) 2025, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        vm_name = @{ type = "str"; required = $true }
        state = @{ type = "str"; default = "present"; choices = @("present", "absent") }
        vmm_server = @{ type = "str"; required = $false }
        bus = @{ type = "int"; default = 0 }
        lun = @{ type = "int"; default = 1 }
        iso = @{ type = "str"; required = $false }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$vm_name = $module.Params.vm_name
$state = $module.Params.state
$vmm_server = $module.Params.vmm_server
$bus = $module.Params.bus
$lun = $module.Params.lun
$iso = $module.Params.iso

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "bus"; Property = "Bus"; Type = "int" }
    @{ Param = "lun"; Property = "LUN"; Type = "int" }
    @{ Param = "iso"; Property = "ISO"; Type = "nested_name" }
)

$module.Result.changed = $false

try {
    $vmmConnection = Connect-SCVMMServerSession -VMMServer $vmm_server -Module $module

    $vm = Get-SCVMMVirtualMachine -Module $module -VMMConnection $vmmConnection -Name $vm_name

    $dvdDrives = Get-SCVirtualDVDDrive -VM $vm -ErrorAction Stop
    $existingDrive = $dvdDrives | Where-Object { $_.Bus -eq $bus -and $_.LUN -eq $lun }

    if ($state -eq "present") {
        if (-not $existingDrive) {
            if (-not $module.CheckMode) {
                $newDrive = New-SCVirtualDVDDrive -VM $vm -Bus $bus -LUN $lun -ErrorAction Stop

                if ($iso) {
                    $isoObject = Get-SCISO -VMMServer $vmmConnection -Name $iso -ErrorAction Stop
                    if (-not $isoObject) {
                        $module.FailJson("ISO file '$iso' not found in SCVMM library")
                    }
                    $newDrive = Set-SCVirtualDVDDrive -VirtualDVDDrive $newDrive -ISO $isoObject -ErrorAction Stop
                }

                $existingDrive = $newDrive
            }
            $module.Result.changed = $true
        }
        else {
            if ($iso) {
                $currentIso = $existingDrive.ISO.Name
                if ($currentIso -ne $iso) {
                    if (-not $module.CheckMode) {
                        $isoObject = Get-SCISO -VMMServer $vmmConnection -Name $iso -ErrorAction Stop
                        if (-not $isoObject) {
                            $module.FailJson("ISO file '$iso' not found in SCVMM library")
                        }
                        $existingDrive = Set-SCVirtualDVDDrive -VirtualDVDDrive $existingDrive -ISO $isoObject -ErrorAction Stop
                    }
                    $module.Result.changed = $true
                }
            }
        }

        if ($existingDrive) {
            $module.Result.dvd_drive = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $existingDrive
        }
        else {
            $module.Result.dvd_drive = @{
                id = $null
                bus = $bus
                lun = $lun
                iso = $iso
            }
        }
    }
    elseif ($state -eq "absent") {
        if ($existingDrive) {
            if (-not $module.CheckMode) {
                Remove-SCVirtualDVDDrive -VirtualDVDDrive $existingDrive -ErrorAction Stop
            }
            $module.Result.changed = $true
        }
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("Failed to manage DVD drive: $($_.Exception.Message)", $_)
}
