# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_servicing_window
version_added: "1.1.0"
short_description: Manage servicing windows in System Center Virtual Machine Manager
description:
  - Create, update, or remove servicing windows in SCVMM.
  - Servicing windows define scheduled maintenance periods for applying updates to managed hosts.
  - Supports daily, weekly, monthly, and monthly-relative recurrence schedules.
  - When creating a servicing window, exactly one schedule frequency parameter must be specified.
options:
  name:
    description:
      - Name of the servicing window.
    type: str
    required: true
  description:
    description:
      - Description of the servicing window.
    type: str
  category:
    description:
      - Category for the servicing window.
    type: str
  owner:
    description:
      - Owner of the servicing window.
    type: str
  time_zone:
    description:
      - Time zone index for the servicing window schedule.
    type: int
  start_date:
    description:
      - Start date for the servicing window in ISO format (e.g., C(2024-01-15)).
    type: str
  start_time_of_day:
    description:
      - Start time of day for the servicing window (e.g., C(08:00:00)).
    type: str
  minutes_duration:
    description:
      - Duration of the servicing window in minutes.
    type: int
  days_to_recur:
    description:
      - Number of days between recurrences for a daily schedule.
      - Mutually exclusive with I(weekly_schedule_day_of_week), I(monthly_schedule_day_of_week), and I(day_of_month).
    type: int
  weekly_schedule_day_of_week:
    description:
      - Day of the week for a weekly schedule.
      - Mutually exclusive with I(days_to_recur), I(monthly_schedule_day_of_week), and I(day_of_month).
    type: str
    choices: ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
  week_of_month:
    description:
      - Week of the month for a monthly-relative schedule.
      - Required together with I(monthly_schedule_day_of_week).
    type: str
    choices: ['First', 'Second', 'Third', 'Fourth', 'Last']
  monthly_schedule_day_of_week:
    description:
      - Day of the week for a monthly-relative schedule.
      - Required together with I(week_of_month).
      - Mutually exclusive with I(days_to_recur), I(weekly_schedule_day_of_week), and I(day_of_month).
    type: str
    choices: ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
  weeks_to_recur:
    description:
      - Number of weeks between recurrences for a weekly schedule.
      - Used together with I(weekly_schedule_day_of_week).
    type: int
    version_added: "1.1.0"
  months_to_recur:
    description:
      - Number of months between recurrences for a monthly or monthly-relative schedule.
      - Used together with I(day_of_month) or I(monthly_schedule_day_of_week).
    type: int
    version_added: "1.1.0"
  day_of_month:
    description:
      - Day of the month for a monthly schedule (1-31).
      - Mutually exclusive with I(days_to_recur), I(weekly_schedule_day_of_week), and I(monthly_schedule_day_of_week).
    type: int
  new_name:
    description:
      - New name for the servicing window when renaming.
      - Only used when updating an existing servicing window.
    type: str
    version_added: "1.1.0"
  state:
    description:
      - Desired state of the servicing window.
      - C(present) creates or updates a servicing window.
      - C(absent) removes a servicing window.
    type: str
    choices: ['present', 'absent']
    default: present
  vmm_server:
    description:
      - SCVMM server to connect to.
      - Defaults to localhost if not specified.
    type: str
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Create a daily servicing window
  microsoft.scvmm.scvmm_servicing_window:
    name: DailyMaintenance
    description: Daily maintenance window
    days_to_recur: 1
    start_time_of_day: "02:00:00"
    minutes_duration: 120
    state: present
    vmm_server: scvmm.example.com

- name: Create a weekly servicing window
  microsoft.scvmm.scvmm_servicing_window:
    name: WeeklyPatching
    description: Weekly patching on Sundays
    weekly_schedule_day_of_week: Sunday
    start_time_of_day: "03:00:00"
    minutes_duration: 240
    state: present
    vmm_server: scvmm.example.com

- name: Create a monthly servicing window (relative)
  microsoft.scvmm.scvmm_servicing_window:
    name: MonthlyMaintenance
    description: First Monday of each month
    monthly_schedule_day_of_week: Monday
    week_of_month: First
    start_time_of_day: "01:00:00"
    minutes_duration: 360
    state: present
    vmm_server: scvmm.example.com

- name: Create a monthly servicing window (specific day)
  microsoft.scvmm.scvmm_servicing_window:
    name: MonthEndMaintenance
    description: Maintenance on the 15th of each month
    day_of_month: 15
    start_time_of_day: "22:00:00"
    minutes_duration: 480
    state: present
    vmm_server: scvmm.example.com

- name: Create a weekly servicing window recurring every 2 weeks
  microsoft.scvmm.scvmm_servicing_window:
    name: BiweeklyPatching
    weekly_schedule_day_of_week: Tuesday
    weeks_to_recur: 2
    start_time_of_day: "04:00:00"
    minutes_duration: 180
    state: present
    vmm_server: scvmm.example.com

- name: Rename a servicing window
  microsoft.scvmm.scvmm_servicing_window:
    name: DailyMaintenance
    new_name: DailyMaintenanceRenamed
    state: present
    vmm_server: scvmm.example.com

- name: Remove a servicing window
  microsoft.scvmm.scvmm_servicing_window:
    name: DailyMaintenance
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
servicing_window:
  description: Details of the servicing window.
  returned: when state is present and servicing window exists
  type: dict
  contains:
    id:
      description: Servicing window ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Servicing window name.
      type: str
      returned: always
      sample: "DailyMaintenance"
    description:
      description: Servicing window description.
      type: str
      returned: always
      sample: "Daily maintenance window"
    category:
      description: Servicing window category.
      type: str
      returned: when available
    owner:
      description: Servicing window owner.
      type: str
      returned: when available
    start_date:
      description: Start date in ISO format.
      type: str
      returned: when available
      sample: "2024-01-15T00:00:00"
    start_time_of_day:
      description: Start time of day.
      type: str
      returned: when available
      sample: "02:00:00"
    minutes_duration:
      description: Duration in minutes.
      type: int
      returned: always
      sample: 120
    days_to_recur:
      description: Number of days between recurrences (daily schedule).
      type: int
      returned: when daily schedule is configured
    weekly_schedule_day_of_week:
      description: Day of week for weekly schedule.
      type: str
      returned: when weekly schedule is configured
      sample: "Sunday"
    monthly_schedule_day_of_week:
      description: Day of week for monthly-relative schedule.
      type: str
      returned: when monthly-relative schedule is configured
    week_of_month:
      description: Week of month for monthly-relative schedule.
      type: str
      returned: when monthly-relative schedule is configured
      sample: "First"
    weeks_to_recur:
      description: Number of weeks between recurrences for weekly schedule.
      type: int
      returned: when weekly schedule is configured
      sample: 2
    months_to_recur:
      description: Number of months between recurrences for monthly schedule.
      type: int
      returned: when monthly schedule is configured
      sample: 3
    day_of_month:
      description: Day of month for monthly schedule.
      type: int
      returned: when monthly schedule is configured
      sample: 15
'''
