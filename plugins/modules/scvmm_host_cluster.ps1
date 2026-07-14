#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        state = @{ type = 'str'; default = 'present'; choices = @('present', 'absent') }
        description = @{ type = 'str' }
        cluster_reserve = @{ type = 'int' }
        nodes = @{ type = 'list'; elements = 'str' }
        cluster_ip_address = @{ type = 'str' }
        credential_username = @{ type = 'str' }
        credential_password = @{ type = 'str'; no_log = $true }
        skip_validation = @{ type = 'bool'; default = $false }
        cleanup_disks = @{ type = 'bool'; default = $false }
        vmm_server = @{ type = 'str' }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

$name = $module.Params.name

$existingCluster = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCVMHostCluster' `
    -FilterScript { $_.Name -eq $name } `
    -ObjectType 'host cluster'

$resultMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "cluster_reserve"; Property = "ClusterReserve"; Type = "int" }
    @{ Param = "host_group"; Property = "HostGroup"; Type = "nested_name" }
)

$updateMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "cluster_reserve"; Property = "ClusterReserve"; Type = "int" }
)

function Get-ClusterResultFull {
    param($Cluster)
    $result = Get-SCVMMResultFromMap -PropertyMap $resultMap -CurrentObject $Cluster
    $result['node_count'] = if ($Cluster.Nodes) { @($Cluster.Nodes).Count } else { 0 }
    $result['nodes'] = @($Cluster.Nodes | ForEach-Object { [string]$_.Name })
    return $result
}

if ($module.Params.state -eq 'present') {
    if ($null -eq $existingCluster) {
        $requiredParams = @('nodes', 'cluster_ip_address', 'credential_username', 'credential_password')
        $missing = @($requiredParams | Where-Object { $null -eq $module.Params.$_ })
        if ($missing.Count -gt 0) {
            $module.FailJson("Missing required parameter(s) for cluster creation: $($missing -join ', ')")
        }
        $module.Result.changed = $true
        $module.Diff.before = @{}
        if (-not $module.CheckMode) {
            try {
                $secPassword = ConvertTo-SecureString $module.Params.credential_password -AsPlainText -Force
                $credential = New-Object System.Management.Automation.PSCredential(
                    $module.Params.credential_username, $secPassword
                )

                $vmHosts = @()
                foreach ($nodeName in $module.Params.nodes) {
                    $vmHost = Get-SCVMHost -VMMServer $vmmConnection `
                        -ComputerName $nodeName -ErrorAction SilentlyContinue
                    if ($null -eq $vmHost) {
                        $module.FailJson("VM host '$nodeName' not found")
                    }
                    $vmHosts += $vmHost
                }

                $installParams = @{
                    ClusterName = $name
                    VMHost = $vmHosts
                    ClusterIPAddress = $module.Params.cluster_ip_address
                    Credential = $credential
                    VMMServer = $vmmConnection
                    ErrorAction = 'Stop'
                }

                if ($null -ne $module.Params.description) {
                    $installParams['Description'] = $module.Params.description
                }
                if ($null -ne $module.Params.cluster_reserve) {
                    $installParams['ClusterReserve'] = $module.Params.cluster_reserve
                }
                if ($module.Params.skip_validation) {
                    $installParams['SkipValidation'] = $true
                }

                $existingCluster = Install-SCVMHostCluster @installParams
            }
            catch {
                $module.FailJson("Failed to create cluster: $($_.Exception.Message)", $_)
            }
            $module.Result.cluster = Get-ClusterResultFull -Cluster $existingCluster
            $module.Diff.after = $module.Result.cluster
        }
        else {
            $module.Result.cluster = @{
                name = $name
                description = $module.Params.description
                cluster_reserve = $module.Params.cluster_reserve
                nodes = $module.Params.nodes
                node_count = if ($module.Params.nodes) { $module.Params.nodes.Count } else { 0 }
            }
            $module.Diff.after = $module.Result.cluster
        }
    }
    else {
        $module.Diff.before = Get-ClusterResultFull -Cluster $existingCluster

        $needsUpdate = Test-SCVMMPropertiesChanged -PropertyMap $updateMap `
            -CurrentObject $existingCluster -AnsibleParams $module.Params

        if ($needsUpdate) {
            $setParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap `
                -AnsibleParams $module.Params -CurrentObject $existingCluster
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                try {
                    $existingCluster = Set-SCVMHostCluster -VMHostCluster $existingCluster `
                        @setParams -ErrorAction Stop
                }
                catch {
                    $module.FailJson("Failed to update cluster: $($_.Exception.Message)", $_)
                }
            }
        }

        $module.Result.cluster = Get-ClusterResultFull -Cluster $existingCluster
        if ($needsUpdate -and $module.CheckMode) {
            $module.Diff.after = Get-SCVMMCheckModeDiff -Before $module.Diff.before `
                -UpdateMap $updateMap -AnsibleParams $module.Params `
                -CurrentObject $existingCluster
        }
        else {
            $module.Diff.after = $module.Result.cluster
        }
    }
}
else {
    if ($null -ne $existingCluster) {
        $module.Diff.before = Get-ClusterResultFull -Cluster $existingCluster
        $module.Diff.after = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                $uninstallParams = @{
                    VMHostCluster = $existingCluster
                    ErrorAction = 'Stop'
                }
                if ($module.Params.cleanup_disks) {
                    $uninstallParams['CleanupDisks'] = $true
                }
                Uninstall-SCVMHostCluster @uninstallParams
            }
            catch {
                $module.FailJson("Failed to remove cluster: $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
