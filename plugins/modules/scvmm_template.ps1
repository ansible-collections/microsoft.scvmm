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

$module.Result.changed = $false

function Get-TemplateResult {
    param($TemplateObject)
    $osName = $null
    if ($TemplateObject.OperatingSystem) {
        $osName = $TemplateObject.OperatingSystem.Name
    }
    return @{
        id = $TemplateObject.ID.ToString()
        name = $TemplateObject.Name
        description = $TemplateObject.Description
        owner = $TemplateObject.Owner
        cpu_count = $TemplateObject.CPUCount
        memory_mb = $TemplateObject.Memory
        generation = $TemplateObject.Generation
        dynamic_memory = $TemplateObject.DynamicMemoryEnabled
        operating_system = $osName
        status = $TemplateObject.Status.ToString()
    }
}

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $vmm_server

if ($state -eq 'present') {
    try {
        $existingTemplate = Get-SCVMTemplate -VMMServer $vmmConnection -Name $name -ErrorAction Stop
    }
    catch {
        $module.FailJson("Failed to query template '$name': $($_.Exception.Message)", $_)
    }

    if ($existingTemplate -and $existingTemplate.Count -gt 1) {
        $module.FailJson("Multiple templates found with name '$name'. Cannot determine which template to manage.")
    }

    if ($existingTemplate) {
        $updateParams = @{}
        $needsUpdate = $false

        $propertyMap = @(
            @{ Param = $description; SCVMMKey = 'Description'; Current = $existingTemplate.Description }
            @{ Param = $owner; SCVMMKey = 'Owner'; Current = $existingTemplate.Owner }
            @{ Param = $cpu_count; SCVMMKey = 'CPUCount'; Current = $existingTemplate.CPUCount }
            @{ Param = $memory_mb; SCVMMKey = 'MemoryMB'; Current = $existingTemplate.Memory }
        )

        foreach ($prop in $propertyMap) {
            if ($null -ne $prop.Param -and $prop.Current -ne $prop.Param) {
                $updateParams[$prop.SCVMMKey] = $prop.Param
                $needsUpdate = $true
            }
        }

        if ($null -ne $dynamic_memory -and $existingTemplate.DynamicMemoryEnabled -ne $dynamic_memory) {
            $updateParams.DynamicMemoryEnabled = $dynamic_memory
            $needsUpdate = $true
        }

        if ($needsUpdate) {
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

        $module.Result.template = Get-TemplateResult -TemplateObject $existingTemplate
    }
    else {
        if (-not $module.CheckMode) {
            if ($source_vm) {
                try {
                    $vmObject = Get-SCVirtualMachine -VMMServer $vmmConnection -Name $source_vm -ErrorAction Stop
                }
                catch {
                    $module.FailJson("Failed to find source VM '$source_vm': $($_.Exception.Message)", $_)
                }
                if (-not $vmObject) {
                    $module.FailJson("Source VM '$source_vm' not found")
                }
                if ($vmObject.Count -gt 1) {
                    $module.FailJson("Multiple VMs found with name '$source_vm'. Cannot determine which VM to use.")
                }

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
                try {
                    $srcTemplate = Get-SCVMTemplate -VMMServer $vmmConnection -Name $source_template -ErrorAction Stop
                }
                catch {
                    $module.FailJson("Failed to find source template '$source_template': $($_.Exception.Message)", $_)
                }
                if (-not $srcTemplate) {
                    $module.FailJson("Source template '$source_template' not found")
                }
                if ($srcTemplate.Count -gt 1) {
                    $module.FailJson("Multiple templates found with name '$source_template'. Cannot determine which to use.")
                }

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
            $module.Result.template = Get-TemplateResult -TemplateObject $newTemplate
        }
        $module.Result.changed = $true
    }
}
elseif ($state -eq 'absent') {
    try {
        $existingTemplate = Get-SCVMTemplate -VMMServer $vmmConnection -Name $name -ErrorAction Stop
    }
    catch {
        $module.FailJson("Failed to query template '$name': $($_.Exception.Message)", $_)
    }

    if ($existingTemplate -and $existingTemplate.Count -gt 1) {
        $module.FailJson("Multiple templates found with name '$name'. Cannot determine which template to remove.")
    }

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
