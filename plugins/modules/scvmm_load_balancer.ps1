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

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "address"; Property = "Address"; Type = "string" }
    @{ Param = "port"; Property = "Port"; Type = "int" }
    @{ Param = "manufacturer"; Property = "Manufacturer"; Type = "string" }
    @{ Param = "model"; Property = "Model"; Type = "string" }
    @{ Param = "configuration_provider"; Property = "ConfigurationProvider"; Type = "nested_name" }
    @{ Param = "host_groups"; Property = "HostGroups"; Type = "name_list" }
)

$updateMap = @(
    @{ Param = "port"; Property = "Port"; Type = "int" }
    @{ Param = "manufacturer"; Property = "Manufacturer"; Type = "string" }
    @{ Param = "model"; Property = "Model"; Type = "string" }
)

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
                $module.Result.load_balancer = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $lb
                $module.Diff.after = $module.Result.load_balancer
            }
            catch {
                $module.FailJson("Failed to add load balancer '$($module.Params.address)': $($_.Exception.Message)", $_)
            }
        }
        else {
            $module.Result.load_balancer = @{
                id = $null
                address = $module.Params.address
                port = $module.Params.port
                manufacturer = $module.Params.manufacturer
                model = $module.Params.model
                configuration_provider = $module.Params.configuration_provider
                host_groups = if ($module.Params.host_groups) { @($module.Params.host_groups) } else { @() }
            }
            $module.Diff.after = $module.Result.load_balancer
        }
    }
    else {
        $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $lb

        $needsUpdate = Test-SCVMMPropertiesChanged -PropertyMap $updateMap `
            -CurrentObject $lb -AnsibleParams $module.Params

        if ($needsUpdate) {
            $setParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap `
                -AnsibleParams $module.Params -CurrentObject $lb
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                $setParams['LoadBalancer'] = $lb
                $setParams['ErrorAction'] = 'Stop'
                try {
                    $lb = Set-SCLoadBalancer @setParams
                }
                catch {
                    $module.FailJson("Failed to update load balancer '$($module.Params.address)': $($_.Exception.Message)", $_)
                }
            }
        }

        $module.Result.load_balancer = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $lb
        if ($needsUpdate -and $module.CheckMode) {
            $module.Diff.after = Get-SCVMMCheckModeDiff -Before $module.Diff.before `
                -UpdateMap $updateMap -AnsibleParams $module.Params `
                -CurrentObject $lb
        }
        else {
            $module.Diff.after = $module.Result.load_balancer
        }
    }
}
else {
    if ($lb) {
        $module.Diff.before = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $lb
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
