#!powershell

# Copyright: (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        state = @{ type = 'str'; required = $true; choices = @('started', 'stopped', 'suspended', 'saved') }
        vmm_server = @{ type = 'str'; required = $false }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$name = $module.Params.name
$state = $module.Params.state
$vmmServer = $module.Params.vmm_server

# Connect to SCVMM server
$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -VMMServer $vmmServer -Module $module

try {
    $vm = Get-SCVirtualMachine -VMMServer $vmmConnection -Name $name -ErrorAction Stop

    if (-not $vm) {
        $module.FailJson("Virtual machine '$name' not found")
    }

    $currentStatus = $vm.Status.ToString()

    $statusMap = @{
        'started' = 'Running'
        'stopped' = 'PowerOff'
        'suspended' = 'Paused'
        'saved' = 'Saved'
    }

    $desiredStatus = $statusMap[$state]

    $module.Diff.before = @{ state = $currentStatus }
    $module.Diff.after = @{ state = $desiredStatus }

    if ($currentStatus -eq $desiredStatus) {
        $module.Result.state = $currentStatus
        $module.ExitJson()
    }

    $module.Result.previous_state = $currentStatus

    if ($module.CheckMode) {
        $module.Result.state = $desiredStatus
        $module.Result.changed = $true
        $module.ExitJson()
    }

    try {
        switch ($state) {
            'started' {
                if ($currentStatus -eq 'Paused') {
                    Resume-SCVirtualMachine -VM $vm -ErrorAction Stop | Out-Null
                }
                else {
                    Start-SCVirtualMachine -VM $vm -ErrorAction Stop | Out-Null
                }
            }
            'stopped' {
                Stop-SCVirtualMachine -VM $vm -ErrorAction Stop | Out-Null
            }
            'suspended' {
                Suspend-SCVirtualMachine -VM $vm -ErrorAction Stop | Out-Null
            }
            'saved' {
                Save-SCVirtualMachine -VM $vm -ErrorAction Stop | Out-Null
            }
        }

        $vm = Get-SCVirtualMachine -VMMServer $vmmConnection -Name $name
        $module.Result.state = $vm.Status.ToString()
        $module.Result.changed = $true
    }
    catch {
        $module.FailJson("Failed to change VM state: $($_.Exception.Message)", $_)
    }

    $module.ExitJson()
}
catch {
    $module.FailJson("An error occurred: $($_.Exception.Message)", $_)
}
