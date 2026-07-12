#!powershell

# Copyright: (c) 2025, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        source_vm = @{ type = 'str'; required = $true }
        vm_host = @{ type = 'str'; required = $false }
        cloud = @{ type = 'str'; required = $false }
        vmm_server = @{ type = 'str'; required = $false }
        state = @{ type = 'str'; default = 'present'; choices = @('present', 'absent') }
        description = @{ type = 'str'; required = $false }
        path = @{ type = 'str'; required = $false }
    }
    mutually_exclusive = @(
        , @('vm_host', 'cloud')
    )
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name
$source_vm = $module.Params.source_vm
$vm_host = $module.Params.vm_host
$cloud = $module.Params.cloud
$vmm_server = $module.Params.vmm_server
$state = $module.Params.state
$description = $module.Params.description
$path = $module.Params.path

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{ Param = "status"; Property = "Status"; Type = "enum" }
    @{ Param = "host"; Property = "HostName"; Type = "string" }
)

$module.Result.changed = $false

try {
    $vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $vmm_server

    if ($state -eq 'present') {
        $existingVm = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
            -CmdletName 'Get-SCVirtualMachine' -Name $name -ObjectType 'virtual machine'

        if ($existingVm) {
            $module.Result.vm = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $existingVm
        }
        else {
            if (-not $module.CheckMode) {
                $sourceVmObject = Get-SCVMMVirtualMachine -Module $module -VMMConnection $vmmConnection -Name $source_vm

                $cloneParams = @{
                    Name = $name
                    VM = $sourceVmObject
                    VMMServer = $vmmConnection
                }

                $vmHostObject = $null
                if ($cloud) {
                    $cloudObject = Get-SCCloud -VMMServer $vmmConnection -Name $cloud -ErrorAction Stop
                    if (-not $cloudObject) {
                        $module.FailJson("Cloud '$cloud' not found")
                    }
                    $cloneParams['Cloud'] = $cloudObject
                }
                else {
                    if ($vm_host) {
                        $vmHostObject = Get-SCVMHost -VMMServer $vmmConnection -ComputerName $vm_host -ErrorAction Stop
                    }
                    else {
                        $vmHostObject = $sourceVmObject.VMHost
                    }
                    if (-not $vmHostObject) {
                        $module.FailJson("Could not determine target VM host for clone")
                    }
                    $cloneParams['VMHost'] = $vmHostObject

                    if ($path) {
                        $cloneParams['Path'] = $path
                    }
                    else {
                        $defaultPaths = $vmHostObject.VMPaths
                        if ($defaultPaths -and $defaultPaths.Count -gt 0) {
                            $cloneParams['Path'] = $defaultPaths[0]
                        }
                    }
                }

                if ($description) {
                    $cloneParams['Description'] = $description
                }

                $clonedVm = New-SCVirtualMachine @cloneParams -ErrorAction Stop
                $module.Result.vm = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $clonedVm
            }
            $module.Result.changed = $true
        }
    }
    elseif ($state -eq 'absent') {
        $removeResult = Remove-SCVMMVirtualMachine -Module $module -VMMConnection $vmmConnection -Name $name
        $module.Result.changed = $removeResult.changed
    }
}
catch {
    $module.FailJson("Failed to clone VM: $($_.Exception.Message)", $_)
}

$module.ExitJson()
