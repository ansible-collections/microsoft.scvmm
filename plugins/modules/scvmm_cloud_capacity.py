# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_cloud_capacity
short_description: Manage cloud capacity limits in System Center Virtual Machine Manager
description:
  - Configure capacity limits for an SCVMM private cloud.
  - Sets maximum CPU, memory, storage, and VM count limits.
  - The cloud must already exist before managing its capacity.
options:
  cloud:
    description:
      - Name of the cloud to configure capacity for.
    type: str
    required: true
  cpu_count:
    description:
      - Maximum number of virtual CPUs allowed in the cloud.
    type: int
  memory_gb:
    description:
      - Maximum memory in GB allowed in the cloud.
    type: int
  storage_gb:
    description:
      - Maximum storage in GB allowed in the cloud.
    type: int
  vm_count:
    description:
      - Maximum number of virtual machines allowed in the cloud.
    type: int
  vmm_server:
    description:
      - SCVMM server to connect to.
      - Defaults to localhost if not specified.
    type: str
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Set cloud capacity limits
  microsoft.scvmm.scvmm_cloud_capacity:
    cloud: Dev-Cloud
    cpu_count: 100
    memory_gb: 512
    storage_gb: 2048
    vm_count: 50
    vmm_server: scvmm.example.com

- name: Update VM count limit only
  microsoft.scvmm.scvmm_cloud_capacity:
    cloud: Dev-Cloud
    vm_count: 100
    vmm_server: scvmm.example.com
'''

RETURN = r'''
cloud_capacity:
  description: Current capacity settings after changes.
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
'''
