# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_cloud_capacity_info
short_description: Query cloud capacity information in System Center Virtual Machine Manager
description:
  - Retrieve capacity limits and current usage for an SCVMM private cloud.
options:
  cloud:
    description:
      - Name of the cloud to query capacity for.
    type: str
    required: true
  vmm_server:
    description:
      - SCVMM server to connect to.
      - Defaults to localhost if not specified.
    type: str
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Get cloud capacity
  microsoft.scvmm.scvmm_cloud_capacity_info:
    cloud: Dev-Cloud
    vmm_server: scvmm.example.com
  register: capacity_info

- name: Display capacity limits
  ansible.builtin.debug:
    msg: "Cloud {{ capacity_info.cloud_capacity.cloud }}: {{ capacity_info.cloud_capacity.vm_count }} VMs max"
'''

RETURN = r'''
cloud_capacity:
  description: Capacity details for the cloud.
  returned: always
  type: dict
  contains:
    cloud:
      description: Name of the cloud.
      type: str
      returned: always
      sample: Dev-Cloud
    cpu_count:
      description: Maximum virtual CPU count.
      type: int
      returned: always
      sample: 100
    memory_gb:
      description: Maximum memory in GB.
      type: int
      returned: always
      sample: 512
    storage_gb:
      description: Maximum storage in GB.
      type: int
      returned: always
      sample: 2048
    vm_count:
      description: Maximum VM count.
      type: int
      returned: always
      sample: 50
    used_cpu_count:
      description: Currently used virtual CPU count.
      type: int
      returned: always
      sample: 24
    used_memory_gb:
      description: Currently used memory in GB.
      type: int
      returned: always
      sample: 128
    used_storage_gb:
      description: Currently used storage in GB.
      type: int
      returned: always
      sample: 500
    used_vm_count:
      description: Current number of VMs.
      type: int
      returned: always
      sample: 12
'''
