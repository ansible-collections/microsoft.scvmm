<#
.SYNOPSIS
Connects to an SCVMM server session.
#>
function Connect-SCVMMServerSession {
    param(
        [Parameter(Mandatory = $true)]
        [Object]$Module,
        [string]$VMMServer
    )

    if (-not (Get-Module -Name VirtualMachineManager -ListAvailable)) {
        $Module.FailJson("The VirtualMachineManager PowerShell module is not installed.")
    }
    try {
        Import-Module -Name VirtualMachineManager -ErrorAction Stop
    }
    catch {
        $Module.FailJson("Failed to import VirtualMachineManager module: $($_.Exception.Message)")
    }

    $serverName = if ($VMMServer) {
        $VMMServer
    }
    else {
        "localhost"
    }
    try {
        $connection = Get-SCVMMServer -ComputerName $serverName -ErrorAction Stop
        return $connection
    }
    catch {
        $Module.FailJson("Failed to connect to SCVMM server '$serverName': $($_.Exception.Message)")
    }
}

<#
.SYNOPSIS
Removes a virtual machine from SCVMM by name.
#>
function Remove-SCVMMVirtualMachine {
    param(
        [Parameter(Mandatory = $true)]
        [Object]$Module,
        [Parameter(Mandatory = $true)]
        [Object]$VMMConnection,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $vm = Get-SCVirtualMachine -VMMServer $VMMConnection -Name $Name -ErrorAction Stop

    if ($vm -and $vm.Count -gt 1) {
        $Module.FailJson("Multiple VMs found with name '$Name'. Cannot determine which VM to remove.")
    }

    if (-not $vm) {
        return @{ changed = $false; vm = $null }
    }

    if (-not $Module.CheckMode) {
        if ($vm.Status -eq 'Running') {
            Stop-SCVirtualMachine -VM $vm -Force -ErrorAction Stop | Out-Null
        }
        Remove-SCVirtualMachine -VM $vm -Force -ErrorAction Stop | Out-Null
    }

    return @{ changed = $true; vm = $vm }
}

<#
.SYNOPSIS
Builds a result hashtable from an SCVMM object using a property map.

.PARAMETER PropertyMap
Array of hashtables. Each must contain 'Param' (Ansible return key) and 'Property' (SCVMM object property).
Supported Type values: 'string', 'bool', 'enum', 'int', 'id', 'bytes_to_gb', 'name_list', 'nested_name', 'datetime_iso'.

.PARAMETER CurrentObject
The SCVMM object to extract properties from.
#>
function Get-SCVMMResultFromMap {
    param (
        [Parameter(Mandatory = $true)]
        [array]$PropertyMap,

        [Parameter(Mandatory = $true)]
        $CurrentObject
    )

    $result = @{}
    foreach ($map in $PropertyMap) {
        $val = $CurrentObject.($map.Property)
        switch ($map.Type) {
            "id" {
                $result.($map.Param) = if ($null -ne $val) { $val.ToString() } else { $null }
            }
            "enum" {
                $result.($map.Param) = if ($null -ne $val) { $val.ToString() } else { $null }
            }
            "bool" {
                $result.($map.Param) = [bool]$val
            }
            "string" {
                $result.($map.Param) = if ($null -ne $val) { [string]$val } else { $null }
            }
            "int" {
                $result.($map.Param) = $val
            }
            "bytes_to_gb" {
                $result.($map.Param) = if ($null -ne $val) { [math]::Round($val / 1GB, 2) } else { $null }
            }
            "mb_to_gb" {
                $result.($map.Param) = if ($null -ne $val) { [math]::Round($val / 1024, 2) } else { $null }
            }
            "name_list" {
                $result.($map.Param) = if ($val) { @($val | ForEach-Object { $_.Name }) } else { @() }
            }
            "nested_name" {
                $result.($map.Param) = if ($null -ne $val) { $val.Name } else { $null }
            }
            "datetime_iso" {
                $result.($map.Param) = if ($null -ne $val) { $val.ToString('o') } else { $null }
            }
            default {
                $result.($map.Param) = $val
            }
        }
    }
    return $result
}

<#
.SYNOPSIS
Compares a single property value using type-aware comparison.
#>
function Test-SCVMMPropertyChanged {
    param (
        [string]$Type,
        $CurrentValue,
        $DesiredValue
    )

    switch ($Type) {
        "enum" {
            $curStr = if ($null -ne $CurrentValue) { $CurrentValue.ToString() } else { "" }
            return $curStr -ne $DesiredValue
        }
        "string" {
            return [string]$CurrentValue -ne [string]$DesiredValue
        }
        "bool" {
            return [bool]$CurrentValue -ne [bool]$DesiredValue
        }
        "bytes_to_gb" {
            $curGb = if ($null -ne $CurrentValue) { [math]::Round($CurrentValue / 1GB, 2) } else { $null }
            return $curGb -ne $DesiredValue
        }
        "mb_to_gb" {
            $curGb = if ($null -ne $CurrentValue) { [math]::Round($CurrentValue / 1024, 2) } else { $null }
            return $curGb -ne $DesiredValue
        }
        default {
            return $CurrentValue -ne $DesiredValue
        }
    }
}

<#
.SYNOPSIS
Compares current SCVMM object properties against desired Ansible parameters.
#>
function Test-SCVMMPropertiesChanged {
    param (
        [Parameter(Mandatory = $true)]
        [array]$PropertyMap,

        [Parameter(Mandatory = $true)]
        $CurrentObject,

        [Parameter(Mandatory = $true)]
        $AnsibleParams
    )

    foreach ($map in $PropertyMap) {
        $paramValue = $AnsibleParams.($map.Param)
        if ($null -eq $paramValue) { continue }

        $currentValue = $CurrentObject.($map.Property)
        if (Test-SCVMMPropertyChanged -Type $map.Type -CurrentValue $currentValue -DesiredValue $paramValue) {
            return $true
        }
    }
    return $false
}

<#
.SYNOPSIS
Builds a hashtable of parameters for SCVMM Set-* cmdlets from a property map.

.PARAMETER PropertyMap
The property mapping definition.
.PARAMETER AnsibleParams
The $module.Params object containing the user's playbook inputs.
#>
function Get-SCVMMParametersFromMap {
    param (
        [Parameter(Mandatory = $true)]
        [array]$PropertyMap,

        [Parameter(Mandatory = $true)]
        $AnsibleParams,

        $CurrentObject
    )

    $outParams = @{}
    foreach ($map in $PropertyMap) {
        $paramValue = $AnsibleParams.($map.Param)
        if ($null -eq $paramValue) { continue }

        if ($CurrentObject) {
            $currentValue = $CurrentObject.($map.Property)
            if (-not (Test-SCVMMPropertyChanged -Type $map.Type -CurrentValue $currentValue -DesiredValue $paramValue)) {
                continue
            }
        }

        $targetParam = if ($null -ne $map.CmdletParam) { $map.CmdletParam } else { $map.Property }
        switch ($map.Type) {
            "mb_to_gb" { $outParams.($targetParam) = $paramValue * 1024 }
            "bytes_to_gb" { $outParams.($targetParam) = [long]($paramValue * 1GB) }
            default { $outParams.($targetParam) = $paramValue }
        }
    }
    return $outParams
}

<#
.SYNOPSIS
Projects a diff.after hashtable for check-mode by overlaying desired parameters onto the before-state.
#>
function Get-SCVMMCheckModeDiff {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Before,

        [Parameter(Mandatory = $true)]
        [array]$UpdateMap,

        [Parameter(Mandatory = $true)]
        $AnsibleParams,

        $CurrentObject
    )

    $projected = $Before.Clone()
    foreach ($map in $UpdateMap) {
        $paramValue = $AnsibleParams.($map.Param)
        if ($null -eq $paramValue) { continue }

        if ($CurrentObject) {
            $currentValue = $CurrentObject.($map.Property)
            if (-not (Test-SCVMMPropertyChanged -Type $map.Type -CurrentValue $currentValue -DesiredValue $paramValue)) {
                continue
            }
        }

        $projected[$map.Param] = $paramValue
    }
    return $projected
}

<#
.SYNOPSIS
Queries an SCVMM object by name with duplicate checking.

.DESCRIPTION
Wraps a Get-SC* cmdlet call with optional name filtering, fails if multiple objects found.

.PARAMETER Module
The Ansible module object for error reporting.
.PARAMETER VMMConnection
The SCVMM server connection.
.PARAMETER CmdletName
The Get-SC* cmdlet to invoke (e.g. 'Get-SCStorageClassification').
.PARAMETER Name
Optional name filter. If not specified, returns all objects.
.PARAMETER ObjectType
Human-readable type name for error messages (e.g. 'storage classification').
.PARAMETER FailIfNotFound
If $true, fails the module when no object is found. Default $false.
.PARAMETER FilterScript
Optional scriptblock for client-side filtering (e.g. for cmdlets without -Name parameter).
#>
function Get-SCVMMObject {
    param (
        [Parameter(Mandatory = $true)]
        $Module,

        [Parameter(Mandatory = $true)]
        $VMMConnection,

        [Parameter(Mandatory = $true)]
        [string]$CmdletName,

        [string]$Name,

        [string]$ObjectType,

        [bool]$FailIfNotFound = $false,

        [scriptblock]$FilterScript
    )

    $typeName = if ($ObjectType) { $ObjectType } else { $CmdletName -replace '^Get-SC', '' }

    try {
        if ($Name -and -not $FilterScript) {
            $objects = @(& $CmdletName -VMMServer $VMMConnection -Name $Name -ErrorAction Stop)
        }
        else {
            $objects = @(& $CmdletName -VMMServer $VMMConnection -ErrorAction Stop)
            if ($FilterScript) {
                $objects = @($objects | Where-Object $FilterScript)
            }
        }
    }
    catch {
        $Module.FailJson("Failed to query ${typeName}: $($_.Exception.Message)", $_)
    }

    if ($Name -or $FilterScript) {
        if ($objects.Count -gt 1) {
            $Module.FailJson("Multiple ${typeName} found with name '$Name'")
        }
        if ($objects.Count -eq 0) {
            if ($FailIfNotFound) {
                $Module.FailJson("${typeName} '$Name' not found")
            }
            return $null
        }
        return $objects[0]
    }

    return $objects
}

<#
.SYNOPSIS
Looks up a single virtual machine by name with validation.

.DESCRIPTION
Convenience wrapper around Get-SCVirtualMachine that fails if the VM is not found
or if multiple VMs share the same name.

.PARAMETER Module
The Ansible module object for error reporting.
.PARAMETER VMMConnection
The SCVMM server connection.
.PARAMETER Name
The VM name to look up.
#>
function Get-SCVMMVirtualMachine {
    param (
        [Parameter(Mandatory = $true)]
        $Module,

        [Parameter(Mandatory = $true)]
        $VMMConnection,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    try {
        $vms = @(Get-SCVirtualMachine -VMMServer $VMMConnection -Name $Name -ErrorAction Stop)
    }
    catch {
        $Module.FailJson("Failed to query virtual machine '$Name': $($_.Exception.Message)", $_)
    }

    if ($vms.Count -eq 0) {
        $Module.FailJson("Virtual machine '$Name' not found")
    }
    if ($vms.Count -gt 1) {
        $Module.FailJson("Multiple virtual machines found with name '$Name'. Please ensure VM names are unique.")
    }

    return $vms[0]
}

Export-ModuleMember -Function 'Connect-SCVMMServerSession', 'Remove-SCVMMVirtualMachine', `
    'Get-SCVMMResultFromMap', 'Test-SCVMMPropertiesChanged', 'Get-SCVMMParametersFromMap', `
    'Get-SCVMMCheckModeDiff', 'Get-SCVMMObject', 'Get-SCVMMVirtualMachine'
