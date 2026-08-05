#!powershell
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#AnsibleRequires -PowerShell ansible_collections.microsoft.scvmm.plugins.module_utils.scvmm

$spec = @{
    options = @{
        name = @{ type = 'str'; required = $true }
        new_name = @{ type = 'str' }
        description = @{ type = 'str' }
        category = @{ type = 'str' }
        owner = @{ type = 'str' }
        time_zone = @{ type = 'int' }
        start_date = @{ type = 'str' }
        start_time_of_day = @{ type = 'str' }
        minutes_duration = @{ type = 'int' }
        days_to_recur = @{ type = 'int' }
        weekly_schedule_day_of_week = @{
            type = 'str'
            choices = @('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')
        }
        weeks_to_recur = @{ type = 'int' }
        week_of_month = @{
            type = 'str'
            choices = @('First', 'Second', 'Third', 'Fourth', 'Last')
        }
        monthly_schedule_day_of_week = @{
            type = 'str'
            choices = @('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')
        }
        months_to_recur = @{ type = 'int' }
        day_of_month = @{ type = 'int' }
        state = @{
            type = 'str'
            default = 'present'
            choices = @('present', 'absent')
        }
        vmm_server = @{ type = 'str' }
    }
    mutually_exclusive = @(
        , @('days_to_recur', 'weekly_schedule_day_of_week', 'monthly_schedule_day_of_week', 'day_of_month')
    )
    required_together = @(
        , @('monthly_schedule_day_of_week', 'week_of_month')
    )
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

$updateMap = @(
    @{ Param = "description"; Property = "Description"; Type = "string" }
    @{ Param = "category"; Property = "Category" }
    @{ Param = "owner"; Property = "Owner" }
    @{ Param = "minutes_duration"; Property = "MinutesDuration"; Type = "int" }
)

function Get-ServicingWindowResult {
    param($ServicingWindow)
    $result = Get-SCVMMResultFromMap -PropertyMap $propertyMap -CurrentObject $ServicingWindow
    if ($ServicingWindow.StartDate) {
        $result['start_date'] = $ServicingWindow.StartDate.ToString('yyyy-MM-ddTHH:mm:ss')
    }
    else {
        $result['start_date'] = $null
    }
    if ($null -ne $ServicingWindow.StartTimeOfDay) {
        if ($ServicingWindow.StartTimeOfDay -is [timespan]) {
            $result['start_time_of_day'] = '{0:hh\:mm\:ss}' -f $ServicingWindow.StartTimeOfDay
        }
        else {
            $result['start_time_of_day'] = $ServicingWindow.StartTimeOfDay.ToString('HH:mm:ss')
        }
    }
    else {
        $result['start_time_of_day'] = $null
    }
    $result['weekly_schedule_day_of_week'] = if ($ServicingWindow.WeeklyScheduleDayOfWeek) {
        $ServicingWindow.WeeklyScheduleDayOfWeek.ToString()
    }
    else { $null }
    $result['monthly_schedule_day_of_week'] = if ($ServicingWindow.MonthlyScheduleDayOfWeek) {
        $ServicingWindow.MonthlyScheduleDayOfWeek.ToString()
    }
    else { $null }
    $result['week_of_month'] = if ($ServicingWindow.WeekOfMonth) {
        $ServicingWindow.WeekOfMonth.ToString()
    }
    else { $null }
    return $result
}

function Get-ScheduleType {
    if ($null -ne $module.Params.days_to_recur) { return 'daily' }
    if ($null -ne $module.Params.weekly_schedule_day_of_week) { return 'weekly' }
    if ($null -ne $module.Params.monthly_schedule_day_of_week) { return 'monthly_relative' }
    if ($null -ne $module.Params.day_of_month) { return 'monthly' }
    return $null
}

function Add-ScheduleParameter {
    param($Params, $ScheduleType)
    switch ($ScheduleType) {
        'daily' {
            $Params['DaysToRecur'] = $module.Params.days_to_recur
        }
        'weekly' {
            $Params['WeeklyScheduleDayOfWeek'] = $module.Params.weekly_schedule_day_of_week
            if ($null -ne $module.Params.weeks_to_recur) {
                $Params['WeeksToRecur'] = $module.Params.weeks_to_recur
            }
        }
        'monthly_relative' {
            $Params['MonthlyScheduleDayOfWeek'] = $module.Params.monthly_schedule_day_of_week
            $Params['WeekOfMonth'] = $module.Params.week_of_month
            if ($null -ne $module.Params.months_to_recur) {
                $Params['MonthsToRecur'] = $module.Params.months_to_recur
            }
        }
        'monthly' {
            $Params['DayOfMonth'] = $module.Params.day_of_month
            if ($null -ne $module.Params.months_to_recur) {
                $Params['MonthsToRecur'] = $module.Params.months_to_recur
            }
        }
    }
}

function Add-CommonParameter {
    param($Params, $CurrentObject)
    $simpleParams = if ($CurrentObject) {
        Get-SCVMMParametersFromMap -PropertyMap $updateMap `
            -AnsibleParams $module.Params -CurrentObject $CurrentObject
    }
    else {
        Get-SCVMMParametersFromMap -PropertyMap $updateMap -AnsibleParams $module.Params
    }
    foreach ($key in $simpleParams.Keys) {
        $Params[$key] = $simpleParams[$key]
    }
    if ($null -ne $module.Params.time_zone) {
        $Params['TimeZone'] = $module.Params.time_zone
    }
    if ($null -ne $module.Params.start_date) {
        $Params['StartDate'] = [datetime]::Parse($module.Params.start_date)
    }
    if ($null -ne $module.Params.start_time_of_day) {
        $Params['StartTimeOfDay'] = [datetime]::Parse($module.Params.start_time_of_day)
    }
}

function Test-ServicingWindowChanged {
    param($Current)
    $simpleParams = Get-SCVMMParametersFromMap -PropertyMap $updateMap `
        -AnsibleParams $module.Params -CurrentObject $Current
    if ($simpleParams.Count -gt 0) { return $true }
    if ($null -ne $module.Params.new_name -and $module.Params.new_name -ne $Current.Name) {
        return $true
    }
    if ($null -ne $module.Params.start_date) {
        $desired = [datetime]::Parse($module.Params.start_date)
        if ($Current.StartDate.Date -ne $desired.Date) { return $true }
    }
    if ($null -ne $module.Params.start_time_of_day) {
        $desired = [datetime]::Parse($module.Params.start_time_of_day)
        $currentTimeOfDay = if ($Current.StartTimeOfDay -is [timespan]) {
            $Current.StartTimeOfDay
        }
        else {
            $Current.StartTimeOfDay.TimeOfDay
        }
        if ($currentTimeOfDay -ne $desired.TimeOfDay) { return $true }
    }
    $scheduleType = Get-ScheduleType
    if ($null -ne $scheduleType) {
        switch ($scheduleType) {
            'daily' {
                if ($Current.DaysToRecur -ne $module.Params.days_to_recur) { return $true }
            }
            'weekly' {
                if ($Current.WeeklyScheduleDayOfWeek.ToString() -ne $module.Params.weekly_schedule_day_of_week) {
                    return $true
                }
                if ($null -ne $module.Params.weeks_to_recur -and $Current.WeeksToRecur -ne $module.Params.weeks_to_recur) {
                    return $true
                }
            }
            'monthly_relative' {
                if ($Current.MonthlyScheduleDayOfWeek.ToString() -ne $module.Params.monthly_schedule_day_of_week) {
                    return $true
                }
                if ($Current.WeekOfMonth.ToString() -ne $module.Params.week_of_month) { return $true }
                if ($null -ne $module.Params.months_to_recur -and $Current.MonthsToRecur -ne $module.Params.months_to_recur) {
                    return $true
                }
            }
            'monthly' {
                if ($Current.DayOfMonth -ne $module.Params.day_of_month) { return $true }
                if ($null -ne $module.Params.months_to_recur -and $Current.MonthsToRecur -ne $module.Params.months_to_recur) {
                    return $true
                }
            }
        }
    }
    return $false
}

$swName = $module.Params.name
$servicingWindow = Get-SCVMMObject -Module $module -VMMConnection $vmmConnection `
    -CmdletName 'Get-SCServicingWindow' -Name $swName -ObjectType 'servicing window' `
    -FilterScript { $_.Name -eq $swName }

if ($module.Params.state -eq 'present') {
    $scheduleType = Get-ScheduleType

    if (-not $servicingWindow) {
        if ($null -eq $scheduleType) {
            $module.FailJson(
                "A schedule frequency parameter is required when creating a servicing window." +
                " Specify one of: days_to_recur, weekly_schedule_day_of_week," +
                " monthly_schedule_day_of_week (with week_of_month), or day_of_month."
            )
        }
        $module.Diff.before = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            $newParams = @{
                Name = $module.Params.name
                VMMServer = $vmmConnection
                ErrorAction = 'Stop'
            }
            Add-ScheduleParameter -Params $newParams -ScheduleType $scheduleType
            Add-CommonParameter -Params $newParams
            try {
                $servicingWindow = New-SCServicingWindow @newParams
                $module.Result.servicing_window = Get-ServicingWindowResult -ServicingWindow $servicingWindow
                $module.Diff.after = $module.Result.servicing_window
            }
            catch {
                $module.FailJson("Failed to create servicing window '$swName': $($_.Exception.Message)", $_)
            }
        }
        else {
            $module.Result.servicing_window = @{
                id = $null
                name = $module.Params.name
                description = $module.Params.description
                category = $module.Params.category
                owner = $module.Params.owner
                start_date = $module.Params.start_date
                start_time_of_day = $module.Params.start_time_of_day
                minutes_duration = $module.Params.minutes_duration
                days_to_recur = $module.Params.days_to_recur
                weekly_schedule_day_of_week = $module.Params.weekly_schedule_day_of_week
                weeks_to_recur = $module.Params.weeks_to_recur
                monthly_schedule_day_of_week = $module.Params.monthly_schedule_day_of_week
                week_of_month = $module.Params.week_of_month
                months_to_recur = $module.Params.months_to_recur
                day_of_month = $module.Params.day_of_month
            }
            $module.Diff.after = $module.Result.servicing_window
        }
    }
    else {
        $module.Diff.before = Get-ServicingWindowResult -ServicingWindow $servicingWindow

        if (Test-ServicingWindowChanged -Current $servicingWindow) {
            $module.Result.changed = $true
            if (-not $module.CheckMode) {
                $setParams = @{
                    ServicingWindow = $servicingWindow
                    ErrorAction = 'Stop'
                }
                Add-CommonParameter -Params $setParams -CurrentObject $servicingWindow
                if ($null -ne $scheduleType) {
                    Add-ScheduleParameter -Params $setParams -ScheduleType $scheduleType
                }
                if ($null -ne $module.Params.new_name -and $module.Params.new_name -ne $servicingWindow.Name) {
                    $setParams['Name'] = $module.Params.new_name
                }
                try {
                    $servicingWindow = Set-SCServicingWindow @setParams
                }
                catch {
                    $module.FailJson("Failed to update servicing window '$swName': $($_.Exception.Message)", $_)
                }
                $module.Result.servicing_window = Get-ServicingWindowResult -ServicingWindow $servicingWindow
                $module.Diff.after = $module.Result.servicing_window
            }
            else {
                $projected = Get-SCVMMCheckModeDiff -Before $module.Diff.before `
                    -UpdateMap $updateMap -AnsibleParams $module.Params -CurrentObject $servicingWindow
                if ($null -ne $module.Params.new_name) {
                    $projected['name'] = $module.Params.new_name
                }
                if ($null -ne $module.Params.start_date) {
                    $projected['start_date'] = $module.Params.start_date
                }
                if ($null -ne $module.Params.start_time_of_day) {
                    $projected['start_time_of_day'] = $module.Params.start_time_of_day
                }
                if ($null -ne $scheduleType) {
                    switch ($scheduleType) {
                        'daily' { $projected['days_to_recur'] = $module.Params.days_to_recur }
                        'weekly' {
                            $projected['weekly_schedule_day_of_week'] = $module.Params.weekly_schedule_day_of_week
                            if ($null -ne $module.Params.weeks_to_recur) {
                                $projected['weeks_to_recur'] = $module.Params.weeks_to_recur
                            }
                        }
                        'monthly_relative' {
                            $projected['monthly_schedule_day_of_week'] = $module.Params.monthly_schedule_day_of_week
                            $projected['week_of_month'] = $module.Params.week_of_month
                            if ($null -ne $module.Params.months_to_recur) {
                                $projected['months_to_recur'] = $module.Params.months_to_recur
                            }
                        }
                        'monthly' {
                            $projected['day_of_month'] = $module.Params.day_of_month
                            if ($null -ne $module.Params.months_to_recur) {
                                $projected['months_to_recur'] = $module.Params.months_to_recur
                            }
                        }
                    }
                }
                $module.Result.servicing_window = $projected
                $module.Diff.after = $projected
            }
        }
        else {
            $module.Result.servicing_window = Get-ServicingWindowResult -ServicingWindow $servicingWindow
            $module.Diff.after = $module.Result.servicing_window
        }
    }
}
else {
    if ($servicingWindow) {
        $module.Diff.before = Get-ServicingWindowResult -ServicingWindow $servicingWindow
        $module.Diff.after = @{}
        $module.Result.changed = $true
        if (-not $module.CheckMode) {
            try {
                Remove-SCServicingWindow -ServicingWindow $servicingWindow -ErrorAction Stop | Out-Null
            }
            catch {
                $module.FailJson("Failed to remove servicing window '$swName': $($_.Exception.Message)", $_)
            }
        }
    }
}

$module.ExitJson()
