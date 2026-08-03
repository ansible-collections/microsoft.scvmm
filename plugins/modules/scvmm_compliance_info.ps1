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

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

$computerName = $module.Params.vmm_managed_computer

$managedComputer = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCVMMManagedComputer' -Name $computerName `
    -LookupParam 'ComputerName' -ObjectType 'managed computer' -FailIfNotFound $true

try {
    $statuses = @(Get-SCComplianceStatus -VMMManagedComputer $managedComputer -ErrorAction Stop)
}
catch {
    $module.FailJson("Failed to query compliance status: $($_.Exception.Message)", $_)
}

if ($module.Params.baseline) {
    $statuses = @($statuses | Where-Object { $_.Baseline.Name -eq $module.Params.baseline })
}

$module.Result.compliance_statuses = @($statuses | Where-Object { $null -ne $_.Baseline } | ForEach-Object {
        @{
            baseline_name = $_.Baseline.Name
            compliance_status = $_.ComplianceStatus.ToString()
            computer_name = $computerName
        }
    })

$module.ExitJson()
