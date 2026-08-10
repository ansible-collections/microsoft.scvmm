#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        computer_name = @{ type = 'str' }
        vmm_server = @{ type = 'str' }
    }
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

$filterName = $module.Params.computer_name
$filterScript = if ($filterName) {
    {
        $_.Name -eq $filterName -or
        $_.ManagedComputer.Name -eq $filterName -or
        $_.ManagedComputer.FQDN -eq $filterName
    }
}
else { $null }

$pxeServers = Get-SCVMMObject -Module $module `
    -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCPXEServer' `
    -ObjectType 'PXE server' `
    -FilterScript $filterScript `
    -AllowMultiple $true

if ($filterName) {
    $pxeServers = if ($pxeServers) { @($pxeServers) } else { @() }
}

$module.Result.pxe_servers = @(
    if ($pxeServers.Count -gt 0) {
        $pxeServers | ForEach-Object {
            $result = Get-SCVMMResultFromMap `
                -PropertyMap $propertyMap -CurrentObject $_
            if ($_.ManagedComputer) {
                $result['managed_computer'] = $_.ManagedComputer.FQDN
            }
            $result
        }
    }
)

$module.ExitJson()
