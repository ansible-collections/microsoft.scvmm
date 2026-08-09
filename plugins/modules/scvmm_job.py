# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_job
version_added: "1.1.0"
short_description: Manage SCVMM job state
description:
  - Stop or restart jobs in System Center Virtual Machine Manager.
  - Jobs are background operations created by SCVMM when performing tasks such as VM deployments,
    host refreshes, and update remediation.
  - Running jobs can be stopped, and failed or canceled jobs can be restarted.
options:
  id:
    description:
      - ID (GUID) of the SCVMM job to manage.
    type: str
    required: true
  state:
    description:
      - Desired action for the job.
      - C(stopped) stops a running job.
      - C(restarted) restarts a failed or canceled job.
    type: str
    required: true
    choices: ['stopped', 'restarted']
  credential:
    description:
      - Name of a RunAs account to use when restarting the job.
      - Only used with I(state=restarted).
    type: str
    version_added: "1.1.0"
  skip_last_failed_step:
    description:
      - When I(true), skips the last failed step when restarting a job.
      - Only used with I(state=restarted).
    type: bool
    default: false
    version_added: "1.1.0"
  vmm_server:
    description:
      - SCVMM server to connect to.
      - Defaults to localhost if not specified.
    type: str
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Stop a running job
  microsoft.scvmm.scvmm_job:
    id: "12345678-1234-1234-1234-123456789012"
    state: stopped
    vmm_server: scvmm.example.com

- name: Restart a failed job
  microsoft.scvmm.scvmm_job:
    id: "12345678-1234-1234-1234-123456789012"
    state: restarted
    vmm_server: scvmm.example.com

- name: Restart a failed job skipping the last failed step
  microsoft.scvmm.scvmm_job:
    id: "12345678-1234-1234-1234-123456789012"
    state: restarted
    skip_last_failed_step: true
    vmm_server: scvmm.example.com

- name: Find and stop all running jobs
  microsoft.scvmm.scvmm_job_info:
    running: true
    vmm_server: scvmm.example.com
  register: running_jobs

- name: Stop each running job
  microsoft.scvmm.scvmm_job:
    id: "{{ item.id }}"
    state: stopped
    vmm_server: scvmm.example.com
  loop: "{{ running_jobs.jobs }}"
'''

RETURN = r'''
job:
  description: Details of the job after the operation.
  returned: always
  type: dict
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
    end_time:
      description: Job end time in ISO format.
      type: str
      returned: when available
    is_completed:
      description: Whether the job has completed.
      type: bool
      returned: always
    owner:
      description: User who initiated the job.
      type: str
      returned: when available
    error_info:
      description: Error description if the job failed.
      type: str
      returned: when job has errors
'''
