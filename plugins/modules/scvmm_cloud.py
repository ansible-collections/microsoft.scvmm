# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_cloud
short_description: Manage private clouds in System Center Virtual Machine Manager
description:
  - Create, update, or remove private clouds in SCVMM.
  - Clouds provide logical resource boundaries for self-service provisioning.
  - A cloud is backed by one or more host groups that supply the compute resources.
  - Cloud capacity limits can be managed separately with the cloud capacity module.
options:
  name:
    description:
      - Name of the cloud.
    type: str
    required: true
  host_group:
    description:
      - Name of the host group that backs this cloud.
      - Required when creating a new cloud.
    type: str
  description:
    description:
      - Description of the cloud.
    type: str
  state:
    description:
      - Desired state of the cloud.
      - C(present) creates or updates a cloud.
      - C(absent) removes a cloud.
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
- name: Create a cloud from a host group
  microsoft.scvmm.scvmm_cloud:
    name: Dev-Cloud
    host_group: Development
    description: Development environment cloud
    state: present
    vmm_server: scvmm.example.com

- name: Update cloud description
  microsoft.scvmm.scvmm_cloud:
    name: Dev-Cloud
    description: Updated development cloud
    state: present
    vmm_server: scvmm.example.com

- name: Remove a cloud
  microsoft.scvmm.scvmm_cloud:
    name: Old-Cloud
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
cloud:
  description: Details of the cloud.
  returned: when state is present and cloud exists
  type: dict
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
