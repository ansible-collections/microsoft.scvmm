# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_baseline
version_added: "1.1.0"
short_description: Manage update baselines in System Center Virtual Machine Manager
description:
  - Create, update, or remove update baselines in SCVMM.
  - Uses New-SCBaseline to create a baseline.
  - Uses Set-SCBaseline to modify name, description, updates, and assignment scopes.
  - Uses Remove-SCBaseline to remove a baseline.
  - Updates and assignment scopes are managed declaratively — the module ensures the baseline
    contains exactly the specified items, adding or removing as needed.
options:
  name:
    description:
      - Name of the baseline.
      - This is the primary identifier for the baseline.
    type: str
    required: true
  description:
    description:
      - Description for the baseline.
    type: str
  updates:
    description:
      - List of software update names to include in the baseline.
      - Each entry is matched against update names via Get-SCUpdate.
      - The module ensures the baseline contains exactly these updates.
    type: list
    elements: str
  assignment_scopes:
    description:
      - List of assignment scopes for the baseline.
      - Each entry specifies a VMM object to which the baseline applies.
    type: list
    elements: dict
    suboptions:
      name:
        description:
          - Name of the scope object (host group, host cluster, or managed computer).
        type: str
        required: true
      type:
        description:
          - Type of scope object.
        type: str
        required: true
        choices: ['host_group', 'host_cluster', 'managed_computer']
  state:
    description:
      - Desired state of the baseline.
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
- name: Create a baseline
  microsoft.scvmm.scvmm_baseline:
    name: Security Baseline
    description: Security updates baseline
    state: present

- name: Create a baseline with updates
  microsoft.scvmm.scvmm_baseline:
    name: Security Baseline
    description: Security updates baseline
    updates:
      - "Security Update for Windows (KB5001234)"
      - "Critical Update for Windows (KB5005678)"
    state: present

- name: Assign baseline to a host group
  microsoft.scvmm.scvmm_baseline:
    name: Security Baseline
    assignment_scopes:
      - name: All Hosts
        type: host_group
    state: present

- name: Remove a baseline
  microsoft.scvmm.scvmm_baseline:
    name: Security Baseline
    state: absent
'''

RETURN = r'''
baseline:
  description: Details of the baseline.
  returned: when state is present and baseline exists
  type: dict
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
