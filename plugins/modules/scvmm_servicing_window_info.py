# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_servicing_window_info
version_added: "1.1.0"
short_description: Query servicing windows in System Center Virtual Machine Manager
description:
  - Retrieve information about servicing windows in SCVMM.
  - Can query all servicing windows or filter by name.
  - Servicing windows define scheduled maintenance periods for update deployment.
options:
  name:
    description:
      - Name of the servicing window to query.
      - If not specified, returns all servicing windows.
    type: str
  vmm_server:
    description:
      - SCVMM server to connect to.
      - Defaults to localhost if not specified.
    type: str
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Get all servicing windows
  microsoft.scvmm.scvmm_servicing_window_info:
    vmm_server: scvmm.example.com
  register: all_windows

- name: Get a specific servicing window
  microsoft.scvmm.scvmm_servicing_window_info:
    name: DailyMaintenance
    vmm_server: scvmm.example.com
  register: window_info

- name: Display servicing windows
  ansible.builtin.debug:
    msg: "{{ item.name }} - Duration: {{ item.minutes_duration }} minutes"
  loop: "{{ all_windows.servicing_windows }}"
'''

RETURN = r'''
servicing_windows:
  description: List of servicing windows.
  returned: always
  type: list
  elements: dict
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
    start_time_of_day:
      description: Start time of day.
      type: str
      returned: when available
    minutes_duration:
      description: Duration in minutes.
      type: int
      returned: always
    days_to_recur:
      description: Number of days between recurrences (daily schedule).
      type: int
      returned: when daily schedule is configured
    weekly_schedule_day_of_week:
      description: Day of week for weekly schedule.
      type: str
      returned: when weekly schedule is configured
    monthly_schedule_day_of_week:
      description: Day of week for monthly-relative schedule.
      type: str
      returned: when monthly-relative schedule is configured
    week_of_month:
      description: Week of month for monthly-relative schedule.
      type: str
      returned: when monthly-relative schedule is configured
    weeks_to_recur:
      description: Number of weeks between recurrences for weekly schedule.
      type: int
      returned: when weekly schedule is configured
    months_to_recur:
      description: Number of months between recurrences for monthly schedule.
      type: int
      returned: when monthly schedule is configured
    day_of_month:
      description: Day of month for monthly schedule.
      type: int
      returned: when monthly schedule is configured
'''
