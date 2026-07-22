#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        logical_network = @{ type = 'str' }
        description = @{ type = 'str' }
        isolation_type = @{
            type = 'str'
            choices = @('NoIsolation', 'WindowsNetworkVirtualization', 'VLANNetwork', 'External')
        }
        state = @{
            type = 'str'
            default = 'present'
            choices = @('present', 'absent')
        }
        vmm_server = @{ type = 'str' }
    }
    required_if = @(
        , @('state', 'present', @('logical_network'))
    )
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

function Get-VMNetworkResult {
    param($VMNetwork)
    return @{
        id = $VMNetwork.ID.ToString()
        name = $VMNetwork.Name
        description = $VMNetwork.Description
        logical_network = $VMNetwork.LogicalNetwork.Name
        isolation_type = [string]$VMNetwork.IsolationType
    }
}

$vmNetwork = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCVMNetwork' -Name $module.Params.name `
    -ObjectType 'VM network'

if ($module.Params.state -eq 'present') {
    if (-not $vmNetwork) {
        $module.Diff.before = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                $logicalNetwork = Get-SCLogicalNetwork -VMMServer $vmmConnection -Name $module.Params.logical_network -ErrorAction Stop
                if (-not $logicalNetwork) {
                    $module.FailJson("Logical network '$($module.Params.logical_network)' not found")
                }

                $newParams = @{
                    Name = $module.Params.name
                    LogicalNetwork = $logicalNetwork
                    ErrorAction = 'Stop'
                }
                if ($null -ne $module.Params.description) {
                    $newParams['Description'] = $module.Params.description
                }
                if ($null -ne $module.Params.isolation_type) {
                    $newParams['IsolationType'] = $module.Params.isolation_type
                }
                $vmNetwork = New-SCVMNetwork @newParams
            }
            catch {
                $module.FailJson("Failed to create VM network '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
    }
    else {
        $needsUpdate = $false
        $updateParams = @{}

        if ($null -ne $module.Params.description -and $module.Params.description -ne $vmNetwork.Description) {
            $needsUpdate = $true
            $updateParams['Description'] = $module.Params.description
        }

        if ($needsUpdate) {
            $module.Diff.before = Get-VMNetworkResult -VMNetwork $vmNetwork
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                $updateParams['VMNetwork'] = $vmNetwork
                $updateParams['ErrorAction'] = 'Stop'
                try {
                    $vmNetwork = Set-SCVMNetwork @updateParams
                }
                catch {
                    $module.FailJson("Failed to update VM network '$($module.Params.name)': $($_.Exception.Message)", $_)
                }
            }
        }
    }

    if ($vmNetwork) {
        $module.Result.vm_network = Get-VMNetworkResult -VMNetwork $vmNetwork
        if ($module.Result.changed -and $module.Diff.before) {
            $module.Diff.after = $module.Result.vm_network
        }
    }
    elseif ($module.CheckMode) {
        $module.Result.vm_network = @{
            id = $null
            name = $module.Params.name
            description = $module.Params.description
            logical_network = $module.Params.logical_network
        }
        $module.Diff.after = $module.Result.vm_network
    }
}
else {
    if ($vmNetwork) {
        $module.Diff.before = Get-VMNetworkResult -VMNetwork $vmNetwork
        $module.Diff.after = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                Remove-SCVMNetwork -VMNetwork $vmNetwork -Force -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove VM network '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
