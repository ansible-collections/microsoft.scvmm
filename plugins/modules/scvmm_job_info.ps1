#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        id = @{ type = 'str' }
        name = @{ type = 'str' }
        newest = @{ type = 'int' }
        running = @{ type = 'bool' }
        vmm_server = @{ type = 'str' }
    }
    mutually_exclusive = @(, @('id', 'name'))
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

$module.Result.changed = $false

$vmmConnection = Connect-SCVMMServerSession -Module $module -VMMServer $module.Params.vmm_server

$propertyMap = @(
    @{ Param = "id"; Property = "ID"; Type = "id" }
    @{ Param = "name"; Property = "Name"; Type = "string" }
    @{ Param = "status"; Property = "Status"; Type = "enum" }
    @{ Param = "result_name"; Property = "ResultName" }
    @{ Param = "progress"; Property = "Progress" }
    @{ Param = "is_completed"; Property = "IsCompleted"; Type = "bool" }
    @{ Param = "owner"; Property = "Owner" }
)

try {
    if ($module.Params.id) {
        $jobs = @(Get-SCJob -VMMServer $vmmConnection -ID $module.Params.id -ErrorAction Stop)
    }
    elseif ($module.Params.name) {
        $jobs = @(Get-SCJob -VMMServer $vmmConnection -Name $module.Params.name -ErrorAction Stop)
    }
    elseif ($module.Params.running -eq $true) {
        $allJobs = @(Get-SCJob -VMMServer $vmmConnection -ErrorAction Stop)
        $jobs = @($allJobs | Where-Object { $_.Status.ToString() -eq 'Running' })
    }
    elseif ($null -ne $module.Params.newest) {
        $jobs = @(Get-SCJob -VMMServer $vmmConnection -Newest $module.Params.newest -ErrorAction Stop)
    }
    else {
        $jobs = @(Get-SCJob -VMMServer $vmmConnection -ErrorAction Stop)
    }
}
catch {
    if ($module.Params.id -and $_.Exception.Message -match 'not found|cannot find|does not map') {
        $jobs = @()
    }
    else {
        $module.FailJson("Failed to query jobs: $($_.Exception.Message)", $_)
    }
}

$module.Result.jobs = @($jobs | ForEach-Object {
        $result = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
        if ($_.StartTime -and $_.StartTime -ne [datetime]::MinValue) {
            $result['start_time'] = $_.StartTime.ToString('yyyy-MM-ddTHH:mm:ss')
        }
        else {
            $result['start_time'] = $null
        }
        if ($_.EndTime -and $_.EndTime -ne [datetime]::MinValue) {
            $result['end_time'] = $_.EndTime.ToString('yyyy-MM-ddTHH:mm:ss')
        }
        else {
            $result['end_time'] = $null
        }
        if ($_.ErrorInfo -and $_.ErrorInfo.Problem) {
            $result['error_info'] = $_.ErrorInfo.Problem
        }
        else {
            $result['error_info'] = $null
        }
        $result
    })

$module.ExitJson()
