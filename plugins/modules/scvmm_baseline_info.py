# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_baseline_info
version_added: "1.1.0"
short_description: Query update baselines in System Center Virtual Machine Manager
description:
  - Retrieve information about update baselines in SCVMM.
  - Can query a specific baseline by name or return all baselines.
options:
  name:
    description:
      - Name of the baseline to query.
      - If not specified, returns all baselines.
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
- name: Get all baselines
  microsoft.scvmm.scvmm_baseline_info:
  register: all_baselines

- name: Get a specific baseline
  microsoft.scvmm.scvmm_baseline_info:
    name: Security Baseline
  register: baseline_info

- name: Display baseline details
  ansible.builtin.debug:
    msg: "Baseline {{ item.name }} has {{ item.update_count }} updates"
  loop: "{{ all_baselines.baselines }}"
'''

RETURN = r'''
baselines:
  description: List of baselines.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: Baseline ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Name of the baseline.
      type: str
      returned: always
      sample: "Security Baseline"
    description:
      description: Description of the baseline.
      type: str
      returned: when available
      sample: "Security updates baseline"
    updates:
      description: List of update names included in the baseline.
      type: list
      elements: str
      returned: always
      sample: ["Security Update for Windows (KB5001234)"]
    assignment_scopes:
      description: List of assignment scope names for the baseline.
      type: list
      elements: str
      returned: always
      sample: ["All Hosts"]
'''
