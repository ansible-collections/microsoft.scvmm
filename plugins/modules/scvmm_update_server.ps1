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
    $existing = $null
}

function Get-UpdateServerResult {
    param($Server, $PropertyMap)
    $result = Get-SCVMMResultFromMap -PropertyMap $PropertyMap -CurrentObject $Server
    $result['update_categories'] = @($Server.UpdateCategories | ForEach-Object { $_.Name })
    $result['update_classifications'] = @($Server.UpdateClassifications | ForEach-Object { $_.Name })
    $result['update_languages'] = @($Server.UpdateLanguages | ForEach-Object { $_.Name })
    return $result
}

if ($module.Params.state -eq 'present') {
    if (-not $existing) {
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
        $needsUpdate = $false
        $setParams = @{
            UpdateServer = $existing
            ErrorAction = 'Stop'
        }

        if ($null -ne $module.Params.update_categories) {
            $currentNames = @($existing.UpdateCategories | ForEach-Object { $_.Name }) | Sort-Object
            $desiredNames = @($module.Params.update_categories) | Sort-Object
            if (Compare-Object -ReferenceObject $currentNames -DifferenceObject $desiredNames -ErrorAction SilentlyContinue) {
                $setParams['UpdateCategories'] = $module.Params.update_categories
                $needsUpdate = $true
            }
        }
        if ($null -ne $module.Params.update_classifications) {
            $currentNames = @($existing.UpdateClassifications | ForEach-Object { $_.Name }) | Sort-Object
            $desiredNames = @($module.Params.update_classifications) | Sort-Object
            if (Compare-Object -ReferenceObject $currentNames -DifferenceObject $desiredNames -ErrorAction SilentlyContinue) {
                $setParams['UpdateClassifications'] = $module.Params.update_classifications
                $needsUpdate = $true
            }
        }
        if ($null -ne $module.Params.update_languages) {
            $currentNames = @($existing.UpdateLanguages | ForEach-Object { $_.Name }) | Sort-Object
            $desiredNames = @($module.Params.update_languages) | Sort-Object
            if (Compare-Object -ReferenceObject $currentNames -DifferenceObject $desiredNames -ErrorAction SilentlyContinue) {
                $setParams['UpdateLanguages'] = $module.Params.update_languages
                $needsUpdate = $true
            }
        }

        if ($null -ne $module.Params.enable_proxy) {
            if ($module.Params.enable_proxy) {
                $setParams['EnableProxy'] = $true
                if ($module.Params.proxy_server_name) {
                    $setParams['ProxyServerName'] = $module.Params.proxy_server_name
                }
                if ($module.Params.proxy_server_port) {
                    $setParams['ProxyServerPort'] = $module.Params.proxy_server_port
                }
            }
            else {
                $setParams['DisableProxy'] = $true
            }
            $needsUpdate = $true
        }

        if ($needsUpdate) {
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
        }
    }
}
else {
    if ($existing) {
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            if (-not $module.Params.credential) {
                $module.FailJson("'credential' is required when removing an update server")
            }
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
