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
    @{ Param = "fqdn"; Property = "FQDN"; Type = "string" }
    @{ Param = "port"; Property = "Port"; Type = "int" }
    @{ Param = "is_connection_secure"; Property = "IsConnectionSecure"; Type = "bool" }
    @{ Param = "server_state"; Property = "ServerState"; Type = "enum" }
)

if ($module.Params.computer_name) {
    try {
        $servers = @(Get-SCUpdateServer -VMMServer $vmmConnection -ComputerName $module.Params.computer_name -ErrorAction Stop)
    }
    catch {
        if ($_.Exception.Message -match 'not found|cannot find|cannot resolve') {
            $servers = @()
        }
        else {
            $module.FailJson("Failed to query update server: $($_.Exception.Message)", $_)
        }
    }
}
else {
    try {
        $servers = @(Get-SCUpdateServer -VMMServer $vmmConnection -ErrorAction Stop)
    }
    catch {
        $module.FailJson("Failed to query update servers: $($_.Exception.Message)", $_)
    }
}

$module.Result.update_servers = @($servers | ForEach-Object {
        $result = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
        $result['update_categories'] = @($_.UpdateCategories | Where-Object { $_.IsEnabled } | ForEach-Object { $_.Name })
        $result['update_classifications'] = @($_.UpdateClassifications | Where-Object { $_.IsEnabled } | ForEach-Object { $_.ClassificationName })
        $result['update_languages'] = @($_.Languages | Where-Object { $_.IsEnabled } | ForEach-Object { $_.LanguageCode })
        $result['proxy_server_name'] = $_.ProxyServerName
        $result['proxy_server_port'] = $_.ProxyServerPort
        $result
    })

$module.ExitJson()
