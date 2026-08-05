# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_job_info
version_added: "1.1.0"
short_description: Query jobs in System Center Virtual Machine Manager
description:
  - Retrieve information about jobs in SCVMM.
  - Jobs represent background operations such as VM deployments, host refreshes, and updates.
  - Can query by job ID, filter running jobs, or retrieve recent jobs.
options:
  id:
    description:
      - ID (GUID) of a specific job to query.
      - If specified, returns only the matching job.
      - Mutually exclusive with I(name).
    type: str
  name:
    description:
      - Name of the job to query.
      - Filters jobs by name using the SCVMM C(Get-SCJob -Name) parameter.
      - Mutually exclusive with I(id).
    type: str
    version_added: "1.1.0"
  newest:
    description:
      - Number of hours to look back for recent jobs.
      - Returns jobs from the last N hours.
    type: int
  running:
    description:
      - If C(true), returns only currently running jobs.
    type: bool
  vmm_server:
    description:
      - SCVMM server to connect to.
      - Defaults to localhost if not specified.
    type: str
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Get all recent jobs
  microsoft.scvmm.scvmm_job_info:
    vmm_server: scvmm.example.com
  register: all_jobs

- name: Get a specific job by ID
  microsoft.scvmm.scvmm_job_info:
    id: "12345678-1234-1234-1234-123456789012"
    vmm_server: scvmm.example.com
  register: job_info

- name: Get jobs by name
  microsoft.scvmm.scvmm_job_info:
    name: "Refresh virtual machine"
    vmm_server: scvmm.example.com
  register: refresh_jobs

- name: Get only running jobs
  microsoft.scvmm.scvmm_job_info:
    running: true
    vmm_server: scvmm.example.com
  register: running_jobs

- name: Get jobs from the last 24 hours
  microsoft.scvmm.scvmm_job_info:
    newest: 24
    vmm_server: scvmm.example.com
  register: recent_jobs

- name: Display job statuses
  ansible.builtin.debug:
    msg: "{{ item.name }} - {{ item.status }} ({{ item.progress }}%)"
  loop: "{{ all_jobs.jobs }}"
'''

RETURN = r'''
jobs:
  description: List of SCVMM jobs.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: Job ID (GUID).
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Job name describing the operation.
      type: str
      returned: always
      sample: "Refresh virtual machine"
    status:
      description: Current job status.
      type: str
      returned: always
      sample: "Completed"
    result_name:
      description: Name of the object affected by the job.
      type: str
      returned: when available
    progress:
      description: Job progress percentage (0-100).
      type: int
      returned: always
      sample: 100
    start_time:
      description: Job start time in ISO format.
      type: str
      returned: when available
      sample: "2024-01-15T10:30:00"
    end_time:
      description: Job end time in ISO format.
      type: str
      returned: when available
      sample: "2024-01-15T10:35:00"
    is_completed:
      description: Whether the job has completed.
      type: bool
      returned: always
    owner:
      description: User who initiated the job.
      type: str
      returned: when available
      sample: "DOMAIN\\admin"
    error_info:
      description: Error description if the job failed.
      type: str
      returned: when job has errors
'''
