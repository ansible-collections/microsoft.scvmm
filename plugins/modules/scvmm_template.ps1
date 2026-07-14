#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        source_vm = @{ type = 'str' }
        source_template = @{ type = 'str' }
        description = @{ type = 'str' }
        owner = @{ type = 'str' }
        cpu_count = @{ type = 'int' }
        memory_mb = @{ type = 'int' }
        dynamic_memory = @{ type = 'bool' }
        generation = @{ type = 'int'; choices = @(1, 2) }
        vmm_server = @{ type = 'str' }
        state = @{ type = 'str'; default = 'present'; choices = @('present', 'absent') }
    }
    mutually_exclusive = @(
        , @('source_vm', 'source_template')
    )
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name
$source_vm = $module.Params.source_vm
$source_template = $module.Params.source_template
$description = $module.Params.description
$owner = $module.Params.owner
$cpu_count = $module.Params.cpu_count
$memory_mb = $module.Params.memory_mb
$dynamic_memory = $module.Params.dynamic_memory
$generation = $module.Params.generation
$vmm_server = $module.Params.vmm_server
$state = $module.Params.state

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "owner"; Property = "Owner"; Type = "string" }
    @{ Param = "cpu_count"; Property = "CPUCount"; Type = "int" }
    @{ Param = "memory_mb"; Property = "Memory"; Type = "int" }
    @{ Param = "generation"; Property = "Generation"; Type = "int" }
    @{ Param = "dynamic_memory"; Property = "DynamicMemoryEnabled"; Type = "bool" }
    @{ Param = "operating_system"; Property = "OperatingSystem"; Type = "nested_name" }
    @{ Param = "status"; Property = "Status"; Type = "enum" }
)

$updateMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "owner"; Property = "Owner"; Type = "string" }
    @{ Param = "cpu_count"; Property = "CPUCount"; Type = "int" }
    @{ Param = "memory_mb"; Property = "Memory"; Type = "int"; CmdletParam = "MemoryMB" }
    @{ Param = "dynamic_memory"; Property = "DynamicMemoryEnabled"; Type = "bool" }
)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $vmm_server

if ($state -eq 'present') {
    $existingTemplate = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCVMTemplate' -Name $name -ObjectType 'template'

    if ($existingTemplate) {
        $updateParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap `
            -AnsibleParams $module.Params -CurrentObject $existingTemplate
        $needsUpdate = $updateParams.Count -gt 0

        if ($needsUpdate) {
            $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $existingTemplate
            if (-not $module.CheckMode) {
                try {
                    $existingTemplate = Set-SCVMTemplate -VMTemplate $existingTemplate @updateParams -ErrorAction Stop
                }
                catch {
                    $module.FailJson("Failed to update template '$name': $($_.Exception.Message)", $_)
                }
            }
            $module.Result.changed = $true
        }

        $module.Result.template = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $existingTemplate

        if ($needsUpdate) {
            if ($module.CheckMode) {
                $module.Diff.after = Get-SCVMMCheckModeDiff -Before $module.Diff.before `
                    -UpdateMap $updateMap -AnsibleParams $module.Params -CurrentObject $existingTemplate
            }
            else {
                $module.Diff.after = $module.Result.template
            }
        }
    }
    else {
        if (-not $module.CheckMode) {
            if ($source_vm) {
                $vmObject = Get-SCVMMVirtualMachine -Module $module -VMMConnection $vmmConnection -Name $source_vm

                try {
                    $libraryServer = Get-SCLibraryServer -VMMServer $vmmConnection -ErrorAction Stop | Select-Object -First 1
                }
                catch {
                    $module.FailJson("Failed to get library server: $($_.Exception.Message)", $_)
                }
                if (-not $libraryServer) {
                    $module.FailJson("No library server found on the VMM server")
                }

                try {
                    $libraryShare = Get-SCLibraryShare -VMMServer $vmmConnection -ErrorAction Stop | Select-Object -First 1
                }
                catch {
                    $module.FailJson("Failed to get library share: $($_.Exception.Message)", $_)
                }
                if (-not $libraryShare) {
                    $module.FailJson("No library share found on the VMM server")
                }

                $templateParams = @{
                    Name = $name
                    VM = $vmObject
                    LibraryServer = $libraryServer
                    SharePath = $libraryShare
                    RunAsynchronously = $false
                }

                if ($generation) {
                    $templateParams['Generation'] = $generation
                }
            }
            elseif ($source_template) {
                $srcTemplate = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
                    -CmdletName 'Get-SCVMTemplate' -Name $source_template -ObjectType 'template' `
                    -FailIfNotFound $true

                $jobGroupId = [System.Guid]::NewGuid()

                $templateParams = @{
                    Name = $name
                    VMTemplate = $srcTemplate
                    JobGroup = $jobGroupId
                }

                if ($generation) {
                    $templateParams['Generation'] = $generation
                }
            }
            else {
                $jobGroupId = [System.Guid]::NewGuid()

                $templateParams = @{
                    Name = $name
                    JobGroup = $jobGroupId
                }

                if ($generation) {
                    $templateParams['Generation'] = $generation
                }
            }

            if ($description) {
                $templateParams['Description'] = $description
            }
            if ($owner) {
                $templateParams['Owner'] = $owner
            }
            if ($cpu_count) {
                $templateParams['CPUCount'] = $cpu_count
            }
            if ($memory_mb) {
                $templateParams['MemoryMB'] = $memory_mb
            }
            if ($null -ne $dynamic_memory) {
                $templateParams['DynamicMemoryEnabled'] = $dynamic_memory
            }

            try {
                $newTemplate = New-SCVMTemplate @templateParams -ErrorAction Stop
            }
            catch {
                $module.FailJson("Failed to create template '$name': $($_.Exception.Message)", $_)
            }
            $module.Result.template = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $newTemplate
        }
        $module.Result.changed = $true
    }
}
elseif ($state -eq 'absent') {
    $existingTemplate = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCVMTemplate' -Name $name -ObjectType 'template'

    if ($existingTemplate) {
        if (-not $module.CheckMode) {
            try {
                Remove-SCVMTemplate -VMTemplate $existingTemplate -Force -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove template '$name': $($_.Exception.Message)", $_)
            }
        }
        $module.Result.changed = $true
    }
}

$module.ExitJson()
