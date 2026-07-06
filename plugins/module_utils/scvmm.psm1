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

Export-ModuleMember -Function 'Connect-SCVMMServerSession'
