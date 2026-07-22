#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str' }
        logical_network = @{ type = 'str' }
        vmm_server = @{ type = 'str' }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

$getParams = @{
    VMMServer   = $vmmConnection
    ErrorAction = 'Stop'
}

if ($module.Params.name) {
    $getParams['Name'] = $module.Params.name
}

if ($module.Params.logical_network) {
    try {
        $ln = Get-SCLogicalNetwork -VMMServer $vmmConnection -Name $module.Params.logical_network -ErrorAction Stop
    }
    catch {
        $ln = $null
    }
    if ($ln) {
        $getParams['LogicalNetwork'] = $ln
    }
}

try {
    $vmNetworks = @(Get-SCVMNetwork @getParams)
}
catch {
    $vmNetworks = @()
}

if ($module.Params.name) {
    $vmNetworks = if ($vmNetworks) { @($vmNetworks) } else { @() }
}

$module.Result.vm_networks = @($vmNetworks | ForEach-Object {
        @{
            id              = $_.ID.ToString()
            name            = $_.Name
            description     = $_.Description
            logical_network = $_.LogicalNetwork.Name
            isolation_type  = [string]$_.IsolationType
        }
    })

$module.ExitJson()
