# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_compliance_info
version_added: "1.1.0"
short_description: Query compliance status of managed computers in SCVMM
description:
  - Retrieve compliance status for managed computers in SCVMM.
  - Uses Get-SCComplianceStatus to query compliance state against baselines.
options:
  vmm_managed_computer:
    description:
      - Name of the managed computer to query compliance status for.
    type: str
    required: true
  baseline:
    description:
      - Name of a specific baseline to filter compliance status.
      - If not specified, returns compliance status for all baselines.
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
- name: Get compliance status for a managed computer
  microsoft.scvmm.scvmm_compliance_info:
    vmm_managed_computer: hyperv01.example.com
  register: compliance

- name: Get compliance status for a specific baseline
  microsoft.scvmm.scvmm_compliance_info:
    vmm_managed_computer: hyperv01.example.com
    baseline: Security Baseline
  register: compliance

- name: Display compliance details
  ansible.builtin.debug:
    msg: "Baseline {{ item.baseline_name }}: {{ item.compliance_status }}"
  loop: "{{ compliance.compliance_statuses }}"
'''

RETURN = r'''
compliance_statuses:
  description: List of compliance statuses for the managed computer.
  returned: always
  type: list
  elements: dict
  contains:
    baseline_name:
      description: Name of the baseline.
      type: str
      returned: always
      sample: "Security Baseline"
    compliance_status:
      description: Compliance status.
      type: str
      returned: always
      sample: "Compliant"
    computer_name:
      description: Name of the managed computer.
      type: str
      returned: always
      sample: "hyperv01.example.com"
'''
