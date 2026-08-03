#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        computer_name = @{ type = 'str'; required = $true }
        tcp_port = @{ type = 'int' }
        credential = @{ type = 'str' }
        use_ssl = @{ type = 'bool' }
        start_sync = @{ type = 'bool' }
        update_categories = @{ type = 'list'; elements = 'str' }
        update_classifications = @{ type = 'list'; elements = 'str' }
        update_languages = @{ type = 'list'; elements = 'str' }
        enable_proxy = @{ type = 'bool' }
        proxy_server_name = @{ type = 'str' }
        proxy_server_port = @{ type = 'int' }
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
    @{ Param = "fqdn"; Property = "FQDN"; Type = "string" }
    @{ Param = "port"; Property = "Port"; Type = "int" }
    @{ Param = "is_connection_secure"; Property = "IsConnectionSecure"; Type = "bool" }
    @{ Param = "server_state"; Property = "ServerState"; Type = "enum" }
)

$computerName = $module.Params.computer_name

try {
    $existing = Get-SCUpdateServer -VMMServer $vmmConnection -ComputerName $computerName -ErrorAction Stop
}
catch {
    if ($_.Exception.Message -match 'not found|cannot find|cannot resolve') {
        $existing = $null
    }
    else {
        $module.FailJson("Failed to query update server: $($_.Exception.Message)", $_)
    }
}

function Get-UpdateServerResult {
    param($Server, $PropertyMap)
    $result = Get-SCVMMResultFromMap -PropertyMap $PropertyMap -CurrentObject $Server
    $result['update_categories'] = @($Server.UpdateCategories | Where-Object { $_.IsEnabled } | ForEach-Object { $_.Name })
    $result['update_classifications'] = @($Server.UpdateClassifications | Where-Object { $_.IsEnabled } | ForEach-Object { $_.ClassificationName })
    $result['update_languages'] = @($Server.Languages | Where-Object { $_.IsEnabled } | ForEach-Object { $_.LanguageCode })
    $result['proxy_server_name'] = $Server.ProxyServerName
    $result['proxy_server_port'] = $Server.ProxyServerPort
    return $result
}

if ($module.Params.state -eq 'present') {
    $created = $false
    if (-not $existing) {
        $created = $true
        $module.Diff.before = @{}
        if (-not $module.Params.tcp_port) {
            $module.FailJson("'tcp_port' is required when adding a new update server")
        }
        if (-not $module.Params.credential) {
            $module.FailJson("'credential' is required when adding a new update server")
        }

        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            $runAs = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
                -CmdletName 'Get-SCRunAsAccount' -Name $module.Params.credential `
                -ObjectType 'RunAs account' -FailIfNotFound $true

            $addParams = @{
                ComputerName = $computerName
                TCPPort = $module.Params.tcp_port
                Credential = $runAs
                ErrorAction = 'Stop'
            }
            if ($module.Params.use_ssl) {
                $addParams['UseSSLConnection'] = $true
            }
            if ($module.Params.start_sync) {
                $addParams['StartUpdateServerSync'] = $true
            }

            try {
                $existing = Add-SCUpdateServer @addParams
            }
            catch {
                $module.FailJson("Failed to add update server '$computerName': $($_.Exception.Message)", $_)
            }
        }
    }

    if ($existing) {
        $beforeResult = Get-UpdateServerResult -Server $existing -PropertyMap $propertyMap
        $needsUpdate = $false
        $setParams = @{
            UpdateServer = $existing
            ErrorAction = 'Stop'
        }

        if ($null -ne $module.Params.update_categories) {
            if (Test-SCVMMListChanged -CurrentCollection $existing.UpdateCategories -DesiredNames $module.Params.update_categories) {
                $setParams['UpdateCategories'] = [string[]]@($module.Params.update_categories)
                $needsUpdate = $true
            }
        }
        if ($null -ne $module.Params.update_classifications) {
            if (Test-SCVMMListChanged -CurrentCollection $existing.UpdateClassifications `
                    -NameProperty 'ClassificationName' -DesiredNames $module.Params.update_classifications) {
                $setParams['UpdateClassifications'] = [string[]]@($module.Params.update_classifications)
                $needsUpdate = $true
            }
        }
        if ($null -ne $module.Params.update_languages) {
            if (Test-SCVMMListChanged -CurrentCollection $existing.Languages -NameProperty 'LanguageCode' -DesiredNames $module.Params.update_languages) {
                $setParams['UpdateLanguages'] = [string[]]@($module.Params.update_languages)
                $needsUpdate = $true
            }
        }

        if ($null -ne $module.Params.enable_proxy) {
            $currentProxyEnabled = $existing.UsesProxy
            if ($module.Params.enable_proxy -and -not $currentProxyEnabled) {
                $setParams['EnableProxy'] = $true
                $setParams['IsProxyAccessAnonymous'] = $true
                if ($module.Params.proxy_server_name) {
                    $setParams['ProxyServerName'] = $module.Params.proxy_server_name
                }
                if ($module.Params.proxy_server_port) {
                    $setParams['ProxyServerPort'] = $module.Params.proxy_server_port
                }
                $needsUpdate = $true
            }
            elseif ($module.Params.enable_proxy -and $currentProxyEnabled) {
                $proxyChanged = $false
                if ($module.Params.proxy_server_name -and
                    $existing.ProxyServerName -ne $module.Params.proxy_server_name) {
                    $setParams['ProxyServerName'] = $module.Params.proxy_server_name
                    $proxyChanged = $true
                }
                if ($module.Params.proxy_server_port -and
                    $existing.ProxyServerPort -ne $module.Params.proxy_server_port) {
                    $setParams['ProxyServerPort'] = $module.Params.proxy_server_port
                    $proxyChanged = $true
                }
                if ($proxyChanged) {
                    $setParams['EnableProxy'] = $true
                    $setParams['IsProxyAccessAnonymous'] = $true
                    $needsUpdate = $true
                }
            }
            elseif (-not $module.Params.enable_proxy -and $currentProxyEnabled) {
                $setParams['DisableProxy'] = $true
                $needsUpdate = $true
            }
        }

        if ($needsUpdate) {
            if (-not $created) {
                $module.Diff.before = $beforeResult
            }
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                try {
                    $existing = Set-SCUpdateServer @setParams
                }
                catch {
                    $module.FailJson("Failed to update server '$computerName': $($_.Exception.Message)", $_)
                }
            }
        }
    }

    if ($existing) {
        $module.Result.update_server = Get-UpdateServerResult -Server $existing -PropertyMap $propertyMap
    }
    elseif ($module.CheckMode) {
        $module.Result.update_server = @{
            id = $null
            name = $computerName
            fqdn = $computerName
            port = $module.Params.tcp_port
            is_connection_secure = if ($module.Params.use_ssl) { $true } else { $false }
            server_state = $null
            update_categories = @()
            update_classifications = @()
            update_languages = @()
            proxy_server_name = $null
            proxy_server_port = $null
        }
    }
    if ($module.Result.changed) {
        $module.Diff.after = $module.Result.update_server
    }
}
else {
    if ($existing) {
        if (-not $module.Params.credential) {
            $module.FailJson("'credential' is required when removing an update server")
        }
        $module.Diff.before = Get-UpdateServerResult -Server $existing -PropertyMap $propertyMap
        $module.Diff.after = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            $runAs = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
                -CmdletName 'Get-SCRunAsAccount' -Name $module.Params.credential `
                -ObjectType 'RunAs account' -FailIfNotFound $true
            try {
                Remove-SCUpdateServer -UpdateServer $existing -Credential $runAs -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove update server '$computerName': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
