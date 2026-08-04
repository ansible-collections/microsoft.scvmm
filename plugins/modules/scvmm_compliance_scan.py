# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_compliance_scan
version_added: "1.1.0"
short_description: Start a compliance scan on a managed computer in SCVMM
description:
  - Triggers a compliance scan on a managed computer against one or more baselines.
  - Uses Start-SCComplianceScan to initiate the scan.
  - This is an action module — it always reports changed since scans produce new results.
options:
  vmm_managed_computer:
    description:
      - Name of the managed computer to scan.
    type: str
    required: true
  baseline:
    description:
      - Name of the baseline to scan against.
      - If not specified, scans against all assigned baselines.
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
- name: Scan a host against all assigned baselines
  microsoft.scvmm.scvmm_compliance_scan:
    vmm_managed_computer: hyperv01.example.com

- name: Scan a host against a specific baseline
  microsoft.scvmm.scvmm_compliance_scan:
    vmm_managed_computer: hyperv01.example.com
    baseline: Security Baseline

- name: Scan and then check compliance status
  microsoft.scvmm.scvmm_compliance_scan:
    vmm_managed_computer: hyperv01.example.com
    baseline: Security Baseline

- name: Get compliance status after scan
  microsoft.scvmm.scvmm_compliance_info:
    vmm_managed_computer: hyperv01.example.com
  register: compliance_status
'''

RETURN = r'''
scan_started:
  description: Whether the compliance scan was started.
  returned: always
  type: bool
  sample: true
'''
