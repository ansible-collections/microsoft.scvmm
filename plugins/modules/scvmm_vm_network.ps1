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

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "logical_network"; Property = "LogicalNetwork"; Type = "nested_name" }
    @{ Param = "isolation_type"; Property = "IsolationType"; Type = "enum" }
)

$createMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "isolation_type"; Property = "IsolationType"; Type = "enum" }
)

$updateMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string" }
)

$vmNetwork = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCVMNetwork' -Name $module.Params.name `
    -ObjectType 'VM network'

if ($module.Params.state -eq 'present') {
    if (-not $vmNetwork) {
        $module.Diff.before = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                $logicalNetwork = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
                    -CmdletName 'Get-SCLogicalNetwork' -Name $module.Params.logical_network `
                    -ObjectType 'Logical network' -FailIfNotFound $true

                $newParams = @{
                    Name = $module.Params.name
                    LogicalNetwork = $logicalNetwork
                    ErrorAction = 'Stop'
                }
                $createParams = Get-SCVMMParametersFromMap -PropertyMap $createMap -AnsibleParams $module.Params
                foreach ($key in $createParams.Keys) {
                    $newParams[$key] = $createParams[$key]
                }
                $vmNetwork = New-SCVMNetwork @newParams
                $module.Result.vm_network = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $vmNetwork
                $module.Diff.after = $module.Result.vm_network
            }
            catch {
                $module.FailJson("Failed to create VM network '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
        else {
            $module.Result.vm_network = @{
                id = $null
                name = $module.Params.name
                description = $module.Params.description
                logical_network = $module.Params.logical_network
                isolation_type = $module.Params.isolation_type
            }
            $module.Diff.after = $module.Result.vm_network
        }
    }
    else {
        $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $vmNetwork

        $needsUpdate = Test-SCVMMPropertiesChanged -PropertyMap $updateMap `
            -CurrentObject $vmNetwork -AnsibleParams $module.Params

        if ($needsUpdate) {
            $setParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap `
                -AnsibleParams $module.Params -CurrentObject $vmNetwork
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                $setParams['VMNetwork'] = $vmNetwork
                $setParams['ErrorAction'] = 'Stop'
                try {
                    $vmNetwork = Set-SCVMNetwork @setParams
                }
                catch {
                    $module.FailJson("Failed to update VM network '$($module.Params.name)': $($_.Exception.Message)", $_)
                }
            }
        }

        $module.Result.vm_network = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $vmNetwork
        if ($needsUpdate -and $module.CheckMode) {
            $module.Diff.after = Get-SCVMMCheckModeDiff -Before $module.Diff.before `
                -UpdateMap $updateMap -AnsibleParams $module.Params `
                -CurrentObject $vmNetwork
        }
        else {
            $module.Diff.after = $module.Result.vm_network
        }
    }
}
else {
    if ($vmNetwork) {
        $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $vmNetwork
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
