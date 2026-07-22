#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        address = @{ type = 'str'; required = $true }
        port = @{ type = 'int'; default = 443 }
        manufacturer = @{ type = 'str' }
        model = @{ type = 'str' }
        configuration_provider = @{ type = 'str' }
        run_as_account = @{ type = 'str' }
        host_groups = @{
            type = 'list'
            elements = 'str'
        }
        state = @{
            type = 'str'
            default = 'present'
            choices = @('present', 'absent')
        }
        vmm_server = @{ type = 'str' }
    }
    required_if = @(
        , @('state', 'present', @('manufacturer', 'model', 'configuration_provider', 'run_as_account', 'host_groups'))
    )
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

function Get-LBResult {
    param($LB)
    return @{
        id                     = $LB.ID.ToString()
        address                = $LB.Address
        port                   = $LB.Port
        manufacturer           = $LB.Manufacturer
        model                  = $LB.Model
        configuration_provider = if ($LB.ConfigurationProvider) { $LB.ConfigurationProvider.Name } else { $null }
        host_groups            = @($LB.HostGroups | ForEach-Object { $_.Name })
    }
}

$lb = Get-SCLoadBalancer -VMMServer $vmmConnection -LoadBalancerAddress $module.Params.address -ErrorAction SilentlyContinue

if ($module.Params.state -eq 'present') {
    if (-not $lb) {
        $module.Diff.before = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                $hostGroups = @($module.Params.host_groups | ForEach-Object {
                        $hg = Get-SCVMHostGroup -VMMServer $vmmConnection -Name $_ -ErrorAction Stop
                        if (-not $hg) { $module.FailJson("Host group '$_' not found") }
                        $hg
                    })

                $configProvider = Get-SCConfigurationProvider -VMMServer $vmmConnection | Where-Object { $_.Name -eq $module.Params.configuration_provider }
                if (-not $configProvider) {
                    $module.FailJson("Configuration provider '$($module.Params.configuration_provider)' not found")
                }

                $runAs = Get-SCRunAsAccount -VMMServer $vmmConnection -Name $module.Params.run_as_account -ErrorAction Stop
                if (-not $runAs) {
                    $module.FailJson("Run As account '$($module.Params.run_as_account)' not found")
                }

                $lb = Add-SCLoadBalancer -VMMServer $vmmConnection `
                    -LoadBalancerAddress $module.Params.address `
                    -Port $module.Params.port `
                    -Manufacturer $module.Params.manufacturer `
                    -Model $module.Params.model `
                    -ConfigurationProvider $configProvider `
                    -RunAsAccount $runAs `
                    -VMHostGroup $hostGroups `
                    -ErrorAction Stop
            }
            catch {
                $module.FailJson("Failed to add load balancer '$($module.Params.address)': $($_.Exception.Message)", $_)
            }
        }
    }
    else {
        $needsUpdate = $false
        $updateParams = @{}

        if ($null -ne $module.Params.port -and $module.Params.port -ne $lb.Port) {
            $needsUpdate = $true
            $updateParams['Port'] = $module.Params.port
        }

        if ($needsUpdate) {
            $module.Diff.before = Get-LBResult -LB $lb
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                $updateParams['LoadBalancer'] = $lb
                $updateParams['ErrorAction'] = 'Stop'
                try {
                    $lb = Set-SCLoadBalancer @updateParams
                }
                catch {
                    $module.FailJson("Failed to update load balancer '$($module.Params.address)': $($_.Exception.Message)", $_)
                }
            }
        }
    }

    if ($lb) {
        $module.Result.load_balancer = Get-LBResult -LB $lb
        if ($module.Result.changed -and $module.Diff.before) {
            $module.Diff.after = $module.Result.load_balancer
        }
    }
    elseif ($module.CheckMode) {
        $module.Result.load_balancer = @{
            address      = $module.Params.address
            port         = $module.Params.port
            manufacturer = $module.Params.manufacturer
            model        = $module.Params.model
        }
        $module.Diff.after = $module.Result.load_balancer
    }
}
else {
    if ($lb) {
        $module.Diff.before = Get-LBResult -LB $lb
        $module.Diff.after = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                Remove-SCLoadBalancer -LoadBalancer $lb -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove load balancer '$($module.Params.address)': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
