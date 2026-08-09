#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        computer_name = @{ type = 'str'; required = $true }
        run_as_account = @{ type = 'str' }
        state = @{
            type = 'str'
            default = 'present'
            choices = @('present', 'absent')
        }
        vmm_server = @{ type = 'str' }
    }
    required_if = @(, @('state', 'present', @('run_as_account')))
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{ Param = "managed_computer"; Property = "ManagedComputer"; Type = "nested_name" }
)

$computerName = $module.Params.computer_name
$pxeFilter = {
    $_.Name -eq $computerName -or
    $_.ManagedComputer.Name -eq $computerName -or
    $_.ManagedComputer.FQDN -eq $computerName
}
$pxeServer = Get-SCVMMObject -Module $module `
    -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCPXEServer' `
    -ObjectType 'PXE server' `
    -FilterScript $pxeFilter

if ($module.Params.state -eq 'present') {
    if (-not $pxeServer) {
        $module.Result.changed = $true
        $module.Diff.before = @{}
        if (-not $module.CheckMode) {
            $runAs = Get-SCRunAsAccount -VMMServer $vmmConnection -Name $module.Params.run_as_account
            if (-not $runAs) {
                $module.FailJson("Run As account '$($module.Params.run_as_account)' not found")
            }
            $addParams = @{
                ComputerName = $computerName
                Credential = $runAs
                VMMServer = $vmmConnection
                ErrorAction = 'Stop'
            }
            try {
                $pxeServer = Add-SCPXEServer @addParams
            }
            catch {
                $module.FailJson("Failed to register PXE server '$computerName': $($_.Exception.Message)", $_)
            }
            $afterResult = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $pxeServer
            if ($pxeServer.ManagedComputer) {
                $afterResult['managed_computer'] = $pxeServer.ManagedComputer.FQDN
            }
            $module.Diff.after = $afterResult
        }
    }

    if ($pxeServer) {
        $result = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $pxeServer
        if ($pxeServer.ManagedComputer) {
            $result['managed_computer'] = $pxeServer.ManagedComputer.FQDN
        }
        $module.Result.pxe_server = $result
    }
    elseif ($module.CheckMode) {
        $module.Result.pxe_server = @{
            id = $null
            name = $computerName
            managed_computer = $null
        }
        $module.Diff.after = $module.Result.pxe_server
    }
}
else {
    if ($pxeServer) {
        $module.Result.changed = $true
        $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $pxeServer
        $module.Diff.after = @{}
        if (-not $module.CheckMode) {
            $removeParams = @{
                PXEServer = $pxeServer
                Force = $true
                ErrorAction = 'Stop'
            }
            if ($module.Params.run_as_account) {
                $runAs = Get-SCRunAsAccount -VMMServer $vmmConnection -Name $module.Params.run_as_account
                if ($runAs) {
                    $removeParams['Credential'] = $runAs
                }
            }
            try {
                Remove-SCPXEServer @removeParams | Out-Null
            }
            catch {
                $module.FailJson("Failed to unregister PXE server '$computerName': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
