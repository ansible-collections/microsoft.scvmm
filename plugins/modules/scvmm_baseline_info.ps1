#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str' }
        vmm_server = @{ type = 'str' }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

if ($module.Params.name) {
    $baselines = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCBaseline' -Name $module.Params.name `
        -ObjectType 'baseline' -AllowMultiple $true
    if ($null -eq $baselines) {
        $baselines = @()
    }
    else {
        $baselines = @($baselines)
    }
}
else {
    $baselines = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
        -CmdletName 'Get-SCBaseline' -ObjectType 'baseline'
    $baselines = @($baselines)
}

$module.Result.baselines = @($baselines | ForEach-Object {
        @{
            id = $_.ID.ToString()
            name = $_.Name
            description = $_.Description
            updates = @($_.Updates | ForEach-Object { $_.Name })
            assignment_scopes = @($_.AssignmentScopes | ForEach-Object { $_.Name })
        }
    })

$module.ExitJson()
