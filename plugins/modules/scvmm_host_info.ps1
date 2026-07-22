#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str' }
        host_group = @{ type = 'str' }
        vmm_server = @{ type = 'str' }
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "name"; Property = "FQDN"; Type = "string" }
    @{ Param = "host_group"; Property = "VMHostGroup"; Type = "nested_name" }
    @{ Param = "status"; Property = "OverallState"; Type = "enum" }
    @{ Param = "cpu_count"; Property = "LogicalCPUCount"; Type = "int" }
    @{ Param = "total_memory_gb"; Property = "TotalMemory"; Type = "bytes_to_gb" }
    @{ Param = "os_version"; Property = "OperatingSystem"; Type = "nested_name" }
    @{ Param = "cluster_name"; Property = "HostCluster"; Type = "nested_name" }
)

try {
    if ($module.Params.name) {
        $hosts = @(Get-SCVMHost -VMMServer $vmmConnection -ComputerName $module.Params.name -ErrorAction Stop)
    }
    elseif ($module.Params.host_group) {
        $hostGroupObj = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
            -CmdletName 'Get-SCVMHostGroup' -Name $module.Params.host_group `
            -ObjectType 'host group' -FailIfNotFound $true
        $hosts = @(Get-SCVMHost -VMHostGroup $hostGroupObj -ErrorAction Stop)
    }
    else {
        $hosts = @(Get-SCVMHost -VMMServer $vmmConnection -ErrorAction Stop)
    }
}
catch {
    $module.FailJson("Failed to query hosts: $($_.Exception.Message)", $_)
}

$module.Result.hosts = @($hosts | ForEach-Object {
        $result = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
        $result['available_memory_gb'] = if ($null -ne $_.AvailableMemory) {
            [math]::Round($_.AvailableMemory / 1024, 2)
        }
        else {
            $null
        }
        $result['vm_count'] = if ($_.VMs) { @($_.VMs).Count } else { 0 }
        $result
    })

$module.ExitJson()
