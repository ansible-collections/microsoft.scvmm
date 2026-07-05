#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        state = @{ type = 'str'; default = 'present'; choices = @('present', 'absent') }
        vmm_server = @{ type = 'str' }
        template = @{ type = 'str' }
        vm_host = @{ type = 'str' }
        cloud = @{ type = 'str' }
        host_group = @{ type = 'str' }
        description = @{ type = 'str' }
        cpu_count = @{ type = 'int' }
        memory_mb = @{ type = 'int' }
        dynamic_memory = @{ type = 'bool' }
        hardware_profile = @{ type = 'str' }
        generation = @{ type = 'int'; choices = @(1, 2) }
        path = @{ type = 'str' }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name
$state = $module.Params.state
$vmmServer = $module.Params.vmm_server
$template = $module.Params.template
$vmHostParam = $module.Params.vm_host
$cloud = $module.Params.cloud
$hostGroup = $module.Params.host_group
$description = $module.Params.description
$cpuCount = $module.Params.cpu_count
$memoryMb = $module.Params.memory_mb
$dynamicMemory = $module.Params.dynamic_memory
$hardwareProfile = $module.Params.hardware_profile
$generation = $module.Params.generation
$path = $module.Params.path

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $vmmServer

$vm = Get-SCVirtualMachine -VMMServer $vmmConnection -Name $name -ErrorAction SilentlyContinue

function Get-VmResultDict {
    param([object]$VmObject)
    $hostName = $null
    if ($VmObject.VMHost) {
        $hostName = $VmObject.VMHost.Name
    }
    return @{
        id = $VmObject.ID.ToString()
        name = $VmObject.Name
        status = $VmObject.Status.ToString()
        host = $hostName
        cpu_count = $VmObject.CPUCount
        memory_mb = $VmObject.Memory
        generation = $VmObject.Generation
        description = $VmObject.Description
    }
}

if ($state -eq 'absent') {
    if ($vm) {
        $hostName = $null
        if ($vm.VMHost) {
            $hostName = $vm.VMHost.Name
        }
        $module.Diff.before = @{
            name = $vm.Name
            status = $vm.Status.ToString()
            host = $hostName
        }
        $module.Diff.after = @{}

        if (-not $module.CheckMode) {
            if ($vm.Status -eq 'Running') {
                try {
                    Stop-SCVirtualMachine -VM $vm -Force -ErrorAction Stop | Out-Null
                }
                catch {
                    $module.FailJson("Failed to stop VM: $($_.Exception.Message)")
                }
            }

            try {
                Remove-SCVirtualMachine -VM $vm -Force -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove VM: $($_.Exception.Message)")
            }
        }

        $module.Result.changed = $true
        $module.Result.name = $name
        $module.Result.state = 'absent'
    }
    else {
        $module.Result.changed = $false
        $module.Result.name = $name
        $module.Result.state = 'absent'
    }
}
else {
    if (-not $vm) {
        $createParams = @{
            Name = $name
            VMMServer = $vmmConnection
        }

        $placementTarget = $null
        if ($cloud) {
            try {
                $placementTarget = Get-SCCloud -VMMServer $vmmConnection -Name $cloud -ErrorAction Stop
                $createParams.Cloud = $placementTarget
            }
            catch {
                $module.FailJson("Failed to find cloud '$cloud': $($_.Exception.Message)")
            }
        }
        elseif ($hostGroup) {
            try {
                $placementTarget = Get-SCVMHostGroup -VMMServer $vmmConnection -Name $hostGroup -ErrorAction Stop
                $createParams.VMHostGroup = $placementTarget
            }
            catch {
                $module.FailJson("Failed to find host group '$hostGroup': $($_.Exception.Message)")
            }
        }
        elseif ($vmHostParam) {
            try {
                $placementTarget = Get-SCVMHost -VMMServer $vmmConnection -ComputerName $vmHostParam -ErrorAction Stop
                $createParams.VMHost = $placementTarget
            }
            catch {
                $module.FailJson("Failed to find VM host '$vmHostParam': $($_.Exception.Message)")
            }
        }
        else {
            $module.FailJson("One of vm_host, cloud, or host_group must be specified to create a VM")
        }

        if ($template) {
            try {
                $templateObj = Get-SCVMTemplate -VMMServer $vmmConnection -Name $template -ErrorAction Stop
                $createParams.VMTemplate = $templateObj
            }
            catch {
                $module.FailJson("Failed to find template '$template': $($_.Exception.Message)")
            }
        }

        if ($hardwareProfile) {
            try {
                $hwProfileObj = Get-SCHardwareProfile -VMMServer $vmmConnection -Name $hardwareProfile -ErrorAction Stop
                $createParams.HardwareProfile = $hwProfileObj
            }
            catch {
                $module.FailJson("Failed to find hardware profile '$hardwareProfile': $($_.Exception.Message)")
            }
        }

        if ($description) {
            $createParams.Description = $description
        }
        if ($cpuCount) {
            $createParams.CPUCount = $cpuCount
        }
        if ($memoryMb) {
            $createParams.MemoryMB = $memoryMb
        }
        if ($null -ne $dynamicMemory) {
            $createParams.DynamicMemoryEnabled = $dynamicMemory
        }
        if ($generation) {
            $createParams.Generation = $generation
        }

        if ($path) {
            $createParams.Path = $path
        }
        elseif ($vmHostParam -and $placementTarget) {
            $defaultPaths = $placementTarget.VMPaths
            if ($defaultPaths -and $defaultPaths.Count -gt 0) {
                $createParams.Path = $defaultPaths[0]
            }
        }

        $module.Diff.before = @{}

        if (-not $module.CheckMode) {
            try {
                $vm = New-SCVirtualMachine @createParams -ErrorAction Stop -StartVM:$false
            }
            catch {
                $module.FailJson("Failed to create VM: $($_.Exception.Message)")
            }
        }

        $module.Result.changed = $true
        $module.Result.name = $name
        $module.Result.state = 'present'

        if (-not $module.CheckMode) {
            $module.Result.vm = Get-VmResultDict -VmObject $vm
            $module.Diff.after = $module.Result.vm
        }
        else {
            $module.Result.vm = @{
                id = $null
                name = $name
                status = 'PowerOff'
                host = $vmHostParam
                cpu_count = $cpuCount
                memory_mb = $memoryMb
                generation = $generation
                description = $description
            }
            $module.Diff.after = $module.Result.vm
        }
    }
    else {
        $updateParams = @{}
        $needsUpdate = $false

        $beforeState = @{
            name = $vm.Name
            cpu_count = $vm.CPUCount
            memory_mb = $vm.Memory
            description = $vm.Description
        }

        $propertyMap = @(
            @{ Param = $cpuCount; SCVMMKey = 'CPUCount'; ResultKey = 'cpu_count'; Current = $vm.CPUCount }
            @{ Param = $memoryMb; SCVMMKey = 'MemoryMB'; ResultKey = 'memory_mb'; Current = $vm.Memory }
            @{ Param = $description; SCVMMKey = 'Description'; ResultKey = 'description'; Current = $vm.Description }
        )

        foreach ($prop in $propertyMap) {
            if ($prop.Param -and $prop.Current -ne $prop.Param) {
                $updateParams[$prop.SCVMMKey] = $prop.Param
                $needsUpdate = $true
            }
        }

        if ($null -ne $dynamicMemory -and $vm.DynamicMemoryEnabled -ne $dynamicMemory) {
            $updateParams.DynamicMemoryEnabled = $dynamicMemory
            $needsUpdate = $true
        }

        if ($needsUpdate) {
            $module.Diff.before = $beforeState
            if (-not $module.CheckMode) {
                try {
                    $vm = Set-SCVirtualMachine -VM $vm @updateParams -ErrorAction Stop
                }
                catch {
                    $module.FailJson("Failed to update VM: $($_.Exception.Message)")
                }
            }

            $module.Result.changed = $true
        }
        else {
            $module.Result.changed = $false
        }

        $module.Result.name = $name
        $module.Result.state = 'present'

        if (-not $module.CheckMode) {
            $module.Result.vm = Get-VmResultDict -VmObject $vm
            if ($needsUpdate) {
                $module.Diff.after = $module.Result.vm
            }
        }
        else {
            $afterState = $beforeState.Clone()
            foreach ($prop in $propertyMap) {
                if ($prop.Param) {
                    $afterState[$prop.ResultKey] = $prop.Param
                }
            }

            $module.Result.vm = Get-VmResultDict -VmObject $vm
            if ($needsUpdate) {
                $module.Diff.after = $afterState
            }
        }
    }
}

$module.ExitJson()
