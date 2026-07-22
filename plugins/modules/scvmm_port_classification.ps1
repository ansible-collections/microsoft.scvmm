#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        description = @{ type = 'str' }
        state = @{
            type = 'str'
            default = 'present'
            choices = @('present', 'absent')
        }
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
    @{ Param = "description"; Property = "Description"; Type = "string" }
)

$updateMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string" }
)

$classification = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCPortClassification' -Name $module.Params.name `
    -ObjectType 'port classification'

if ($module.Params.state -eq 'present') {
    if (-not $classification) {
        $module.Diff.before = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            $newParams = @{
                Name = $module.Params.name
                VMMServer = $vmmConnection
                ErrorAction = 'Stop'
            }
            if ($null -ne $module.Params.description) {
                $newParams['Description'] = $module.Params.description
            }
            try {
                $classification = New-SCPortClassification @newParams
                $module.Result.port_classification = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $classification
                $module.Diff.after = $module.Result.port_classification
            }
            catch {
                $module.FailJson("Failed to create port classification '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
        else {
            $module.Result.port_classification = @{
                id = $null
                name = $module.Params.name
                description = $module.Params.description
            }
            $module.Diff.after = $module.Result.port_classification
        }
    }
    else {
        $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $classification

        $updateParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap `
            -AnsibleParams $module.Params -CurrentObject $classification
        $needsUpdate = $updateParams.Count -gt 0

        if ($needsUpdate) {
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                $updateParams['PortClassification'] = $classification
                $updateParams['ErrorAction'] = 'Stop'
                try {
                    $classification = Set-SCPortClassification @updateParams
                }
                catch {
                    $module.FailJson("Failed to update port classification '$($module.Params.name)': $($_.Exception.Message)", $_)
                }
            }
        }

        $module.Result.port_classification = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $classification
        if ($needsUpdate -and $module.CheckMode) {
            $module.Diff.after = Get-SCVMMCheckModeDiff -Before $module.Diff.before `
                -UpdateMap $updateMap -AnsibleParams $module.Params -CurrentObject $classification
        }
        else {
            $module.Diff.after = $module.Result.port_classification
        }
    }
}
else {
    if ($classification) {
        $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $classification
        $module.Diff.after = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                Remove-SCPortClassification -PortClassification $classification -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove port classification '$($module.Params.name)': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
