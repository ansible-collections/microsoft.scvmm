#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        id = @{ type = 'str'; required = $true }
        state = @{
            type = 'str'
            required = $true
            choices = @('stopped', 'restarted')
        }
        credential = @{ type = 'str' }
        skip_last_failed_step = @{ type = 'bool'; default = $false }
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
    @{ Param = "status"; Property = "Status"; Type = "enum" }
    @{ Param = "result_name"; Property = "ResultName" }
    @{ Param = "progress"; Property = "Progress" }
    @{ Param = "is_completed"; Property = "IsCompleted"; Type = "bool" }
    @{ Param = "owner"; Property = "Owner" }
)

function Get-JobResult {
    param($Job)
    $result = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $Job
    if ($Job.StartTime -and $Job.StartTime -ne [datetime]::MinValue) {
        $result['start_time'] = $Job.StartTime.ToString('yyyy-MM-ddTHH:mm:ss')
    }
    else {
        $result['start_time'] = $null
    }
    if ($Job.EndTime -and $Job.EndTime -ne [datetime]::MinValue) {
        $result['end_time'] = $Job.EndTime.ToString('yyyy-MM-ddTHH:mm:ss')
    }
    else {
        $result['end_time'] = $null
    }
    if ($Job.ErrorInfo -and $Job.ErrorInfo.Problem) {
        $result['error_info'] = $Job.ErrorInfo.Problem
    }
    else {
        $result['error_info'] = $null
    }
    return $result
}

$jobId = $module.Params.id
try {
    $job = Get-SCJob -VMMServer $vmmConnection -ID $jobId -ErrorAction Stop
}
catch {
    $module.FailJson("Failed to query job '$jobId': $($_.Exception.Message)", $_)
}

if (-not $job) {
    $module.FailJson("Job '$jobId' not found")
}

$currentStatus = $job.Status.ToString()
$module.Diff.before = @{ state = $currentStatus }

if ($module.Params.state -eq 'stopped') {
    if ($currentStatus -eq 'Running') {
        $module.Diff.after = @{ state = 'Stopped' }
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                Stop-SCJob -Job $job -ErrorAction Stop | Out-Null
                $job = Get-SCJob -VMMServer $vmmConnection -ID $jobId -ErrorAction Stop
            }
            catch {
                $module.FailJson("Failed to stop job '$jobId': $($_.Exception.Message)", $_)
            }
        }
    }
    else {
        $module.Diff.after = @{ state = $currentStatus }
    }
}
else {
    if ($currentStatus -eq 'Failed' -or $currentStatus -eq 'Canceled') {
        $module.Diff.after = @{ state = 'Running' }
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                $restartParams = @{
                    Job = $job
                    ErrorAction = 'Stop'
                }
                if ($module.Params.skip_last_failed_step) {
                    $restartParams['SkipLastFailedStep'] = $true
                }
                if ($null -ne $module.Params.credential) {
                    $runAsAccount = Get-SCRunAsAccount -VMMServer $vmmConnection `
                        -Name $module.Params.credential -ErrorAction Stop
                    if (-not $runAsAccount) {
                        $module.FailJson("RunAs account '$($module.Params.credential)' not found")
                    }
                    $restartParams['Credential'] = $runAsAccount
                }
                Restart-SCJob @restartParams | Out-Null
                $job = Get-SCJob -VMMServer $vmmConnection -ID $jobId -ErrorAction Stop
            }
            catch {
                $module.FailJson("Failed to restart job '$jobId': $($_.Exception.Message)", $_)
            }
        }
    }
    elseif ($currentStatus -eq 'Running') {
        $module.Diff.after = @{ state = $currentStatus }
    }
    else {
        $module.FailJson(
            "Cannot restart job '$jobId' in status '$currentStatus'." +
            " Only failed or canceled jobs can be restarted."
        )
    }
}

$module.Result.job = Get-JobResult -Job $job

$module.ExitJson()
