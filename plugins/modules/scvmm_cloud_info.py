# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_cloud_info
short_description: Query private cloud information in System Center Virtual Machine Manager
description:
  - Retrieve information about private clouds in SCVMM.
  - Can query all clouds or filter by name.
options:
  name:
    description:
      - Name of the cloud to query.
      - If not specified, returns all clouds.
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
- name: Get all clouds
  microsoft.scvmm.scvmm_cloud_info:
    vmm_server: scvmm.example.com
  register: all_clouds

- name: Get a specific cloud
  microsoft.scvmm.scvmm_cloud_info:
    name: Dev-Cloud
    vmm_server: scvmm.example.com
  register: cloud_info

- name: Display cloud details
  ansible.builtin.debug:
    msg: "Cloud {{ item.name }}: {{ item.description }}"
  loop: "{{ all_clouds.clouds }}"
'''

RETURN = r'''
clouds:
  description: List of private clouds.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: Cloud ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Cloud name.
      type: str
      returned: always
      sample: Dev-Cloud
    description:
      description: Cloud description.
      type: str
      returned: when available
      sample: Development environment cloud
    host_groups:
      description: Names of host groups backing this cloud.
      type: list
      elements: str
      returned: always
      sample: ["Development"]
'''
