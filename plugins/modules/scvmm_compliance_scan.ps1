#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        vmm_managed_computer = @{ type = 'str'; required = $true }
        baseline = @{ type = 'str' }
        vmm_server = @{ type = 'str' }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false
$module.Result.scan_started = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

$computerName = $module.Params.vmm_managed_computer

try {
    $managedComputer = Get-SCVMMManagedComputer -VMMServer $vmmConnection -ComputerName $computerName -ErrorAction Stop
}
catch {
    $managedComputer = $null
}

if (-not $managedComputer) {
    $module.FailJson("Managed computer '$computerName' not found")
}

$scanParams = @{
    VMMManagedComputer = $managedComputer
    ErrorAction = 'Stop'
}

if ($module.Params.baseline) {
    $baseline = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCBaseline' -Name $module.Params.baseline `
        -ObjectType 'baseline' -FailIfNotFound $true
    $scanParams['Baseline'] = $baseline
}

$module.Result.changed = $true

if (-not $module.CheckMode) {
    try {
        Start-SCComplianceScan @scanParams | Out-Null
        $module.Result.scan_started = $true
    }
    catch {
        $module.FailJson("Failed to start compliance scan on '$computerName': $($_.Exception.Message)", $_)
    }
}

$module.ExitJson()
