#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        description = @{ type = 'str' }
        updates = @{ type = 'list'; elements = 'str' }
        assignment_scopes = @{
            type = 'list'
            elements = 'dict'
            options = @{
                name = @{ type = 'str'; required = $true }
                type = @{
                    type = 'str'
                    required = $true
                    choices = @('host_group', 'host_cluster', 'managed_computer')
                }
            }
        }
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

$name = $module.Params.name

$existing = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCBaseline' -Name $name -ObjectType 'baseline'

function Get-BaselineResult {
    param($Baseline)
    return @{
        id = $Baseline.ID.ToString()
        name = $Baseline.Name
        description = $Baseline.Description
        updates = @($Baseline.Updates | ForEach-Object { $_.Name })
        assignment_scopes = @($Baseline.AssignmentScopes | ForEach-Object { $_.Name })
    }
}

function Get-ScopeObject {
    param($Module, $VMMConnection, $ScopeName, $ScopeType)
    $cmdletMap = @{
        'host_group'       = @{ Cmdlet = 'Get-SCVMHostGroup'; ObjectType = 'host group' }
        'host_cluster'     = @{ Cmdlet = 'Get-SCVMHostCluster'; ObjectType = 'host cluster' }
        'managed_computer' = @{ Cmdlet = 'Get-SCVMManagedComputer'; ObjectType = 'managed computer' }
    }
    $info = $cmdletMap[$ScopeType]
    return Get-SCVMMObject -Module $Module -VMMConnection $VMMConnection `
        -CmdletName $info.Cmdlet -Name $ScopeName `
        -ObjectType $info.ObjectType -FailIfNotFound $true
}

if ($module.Params.state -eq 'present') {
    if (-not $existing) {
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                $newParams = @{
                    VMMServer = $vmmConnection
                    Name = $name
                    ErrorAction = 'Stop'
                }
                if ($module.Params.description) {
                    $newParams['Description'] = $module.Params.description
                }
                $existing = New-SCBaseline @newParams
            }
            catch {
                $module.FailJson("Failed to create baseline '$name': $($_.Exception.Message)", $_)
            }

            $setParams = @{
                Baseline = $existing
                ErrorAction = 'Stop'
            }
            $needsSet = $false

            if ($null -ne $module.Params.updates -and $module.Params.updates.Count -gt 0) {
                $updateObjects = @()
                foreach ($updateName in $module.Params.updates) {
                    try {
                        $update = Get-SCUpdate -Name $updateName -ErrorAction Stop
                        if ($null -eq $update) {
                            $module.FailJson("Update '$updateName' not found")
                        }
                        $updateObjects += $update
                    }
                    catch {
                        $module.FailJson("Failed to find update '$updateName': $($_.Exception.Message)", $_)
                    }
                }
                $setParams['AddUpdates'] = $updateObjects
                $needsSet = $true
            }

            if ($null -ne $module.Params.assignment_scopes -and $module.Params.assignment_scopes.Count -gt 0) {
                $scopeObjects = @()
                foreach ($scope in $module.Params.assignment_scopes) {
                    $scopeObjects += Get-ScopeObject -Module $module -VMMConnection $vmmConnection `
                        -ScopeName $scope.name -ScopeType $scope.type
                }
                $setParams['AddAssignmentScope'] = $scopeObjects
                $needsSet = $true
            }

            if ($needsSet) {
                try {
                    $existing = Set-SCBaseline @setParams
                }
                catch {
                    $module.FailJson("Failed to configure baseline '$name': $($_.Exception.Message)", $_)
                }
            }
        }
    }
    else {
        $needsUpdate = $false
        $setParams = @{
            Baseline = $existing
            ErrorAction = 'Stop'
        }

        if ($null -ne $module.Params.description -and $existing.Description -ne $module.Params.description) {
            $setParams['Description'] = $module.Params.description
            $needsUpdate = $true
        }

        if ($null -ne $module.Params.updates) {
            $currentUpdateNames = @($existing.Updates | ForEach-Object { $_.Name })
            $desiredUpdateNames = @($module.Params.updates)

            $toAdd = @($desiredUpdateNames | Where-Object { $_ -notin $currentUpdateNames })
            $toRemove = @($currentUpdateNames | Where-Object { $_ -notin $desiredUpdateNames })

            if ($toAdd.Count -gt 0) {
                $addObjects = @()
                foreach ($updateName in $toAdd) {
                    try {
                        $update = Get-SCUpdate -Name $updateName -ErrorAction Stop
                        if ($null -eq $update) {
                            $module.FailJson("Update '$updateName' not found")
                        }
                        $addObjects += $update
                    }
                    catch {
                        $module.FailJson("Failed to find update '$updateName': $($_.Exception.Message)", $_)
                    }
                }
                $setParams['AddUpdates'] = $addObjects
                $needsUpdate = $true
            }

            if ($toRemove.Count -gt 0) {
                $removeObjects = @()
                foreach ($updateName in $toRemove) {
                    $removeObjects += @($existing.Updates | Where-Object { $_.Name -eq $updateName })
                }
                $setParams['RemoveUpdates'] = $removeObjects
                $needsUpdate = $true
            }
        }

        if ($null -ne $module.Params.assignment_scopes) {
            $currentScopeNames = @($existing.AssignmentScopes | ForEach-Object { $_.Name })
            $desiredScopeNames = @($module.Params.assignment_scopes | ForEach-Object { $_.name })

            $scopesToAdd = @($module.Params.assignment_scopes | Where-Object { $_.name -notin $currentScopeNames })
            $scopeNamesToRemove = @($currentScopeNames | Where-Object { $_ -notin $desiredScopeNames })

            if ($scopesToAdd.Count -gt 0) {
                $addScopeObjects = @()
                foreach ($scope in $scopesToAdd) {
                    $addScopeObjects += Get-ScopeObject -Module $module -VMMConnection $vmmConnection `
                        -ScopeName $scope.name -ScopeType $scope.type
                }
                $setParams['AddAssignmentScope'] = $addScopeObjects
                $needsUpdate = $true
            }

            if ($scopeNamesToRemove.Count -gt 0) {
                $removeScopeObjects = @($existing.AssignmentScopes | Where-Object { $_.Name -in $scopeNamesToRemove })
                $setParams['RemoveAssignmentScope'] = $removeScopeObjects
                $needsUpdate = $true
            }
        }

        if ($needsUpdate) {
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                try {
                    $existing = Set-SCBaseline @setParams
                }
                catch {
                    $module.FailJson("Failed to update baseline '$name': $($_.Exception.Message)", $_)
                }
            }
        }
    }

    if ($existing) {
        $module.Result.baseline = Get-BaselineResult -Baseline $existing
    }
    elseif ($module.CheckMode) {
        $module.Result.baseline = @{
            id = $null
            name = $name
            description = $module.Params.description
            updates = if ($module.Params.updates) { @($module.Params.updates) } else { @() }
            assignment_scopes = if ($module.Params.assignment_scopes) { @($module.Params.assignment_scopes | ForEach-Object { $_.name }) } else { @() }
        }
    }
}
else {
    if ($existing) {
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                Remove-SCBaseline -Baseline $existing -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove baseline '$name': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
