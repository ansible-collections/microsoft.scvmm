#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str' }
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
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "category"; Property = "Category" }
    @{ Param = "owner"; Property = "Owner" }
    @{ Param = "minutes_duration"; Property = "MinutesDuration"; Type = "int" }
    @{ Param = "days_to_recur"; Property = "DaysToRecur"; Type = "int" }
    @{ Param = "day_of_month"; Property = "DayOfMonth" }
    @{ Param = "weeks_to_recur"; Property = "WeeksToRecur"; Type = "int" }
    @{ Param = "months_to_recur"; Property = "MonthsToRecur"; Type = "int" }
)

try {
    $windows = @(Get-SCServicingWindow -VMMServer $vmmConnection -ErrorAction Stop)
    if ($module.Params.name) {
        $windows = @($windows | Where-Object { $_.Name -eq $module.Params.name })
    }
}
catch {
    $module.FailJson("Failed to query servicing windows: $($_.Exception.Message)", $_)
}

$module.Result.servicing_windows = @($windows | ForEach-Object {
        $result = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $_
        if ($_.StartDate) {
            $result['start_date'] = $_.StartDate.ToString('yyyy-MM-ddTHH:mm:ss')
        }
        else {
            $result['start_date'] = $null
        }
        if ($null -ne $_.StartTimeOfDay) {
            if ($_.StartTimeOfDay -is [timespan]) {
                $result['start_time_of_day'] = '{0:hh\:mm\:ss}' -f $_.StartTimeOfDay
            }
            else {
                $result['start_time_of_day'] = $_.StartTimeOfDay.ToString('HH:mm:ss')
            }
        }
        else {
            $result['start_time_of_day'] = $null
        }
        $result['weekly_schedule_day_of_week'] = if ($_.WeeklyScheduleDayOfWeek) {
            $_.WeeklyScheduleDayOfWeek.ToString()
        }
        else { $null }
        $result['monthly_schedule_day_of_week'] = if ($_.MonthlyScheduleDayOfWeek) {
            $_.MonthlyScheduleDayOfWeek.ToString()
        }
        else { $null }
        $result['week_of_month'] = if ($_.WeekOfMonth) {
            $_.WeekOfMonth.ToString()
        }
        else { $null }
        $result
    })

$module.ExitJson()
