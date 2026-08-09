# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_custom_property
version_added: "1.1.0"
short_description: Manage custom properties in System Center Virtual Machine Manager
description:
  - Create, update, or remove custom properties in SCVMM.
  - Custom properties are user-defined metadata fields that can be attached to SCVMM objects
    such as VMs, hosts, clouds, and templates.
  - When creating a custom property, at least one member type must be specified.
  - Member types can be added or removed from existing custom properties.
options:
  name:
    description:
      - Name of the custom property.
    type: str
    required: true
  new_name:
    description:
      - New name for the custom property when renaming.
      - Only used when updating an existing custom property.
    type: str
    version_added: "1.1.0"
  description:
    description:
      - Description of the custom property.
    type: str
  member_types:
    description:
      - List of SCVMM object types that this custom property applies to.
      - Required when I(state=present).
      - Specifies which object types can have this custom property assigned.
    type: list
    elements: str
    choices:
      - VM
      - Template
      - VMHost
      - HostCluster
      - VMHostGroup
      - ServiceTemplate
      - ServiceInstance
      - ComputerTier
      - Cloud
      - ProtectionUnit
  state:
    description:
      - Desired state of the custom property.
      - C(present) creates or updates a custom property.
      - C(absent) removes a custom property.
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
- name: Create a custom property for VMs
  microsoft.scvmm.scvmm_custom_property:
    name: CostCenter
    description: Cost center code for billing
    member_types:
      - VM
      - Cloud
    state: present
    vmm_server: scvmm.example.com

- name: Update custom property to apply to additional types
  microsoft.scvmm.scvmm_custom_property:
    name: CostCenter
    member_types:
      - VM
      - Cloud
      - VMHost
    state: present
    vmm_server: scvmm.example.com

- name: Rename a custom property
  microsoft.scvmm.scvmm_custom_property:
    name: CostCenter
    new_name: BillingCode
    member_types:
      - VM
      - Cloud
    state: present
    vmm_server: scvmm.example.com

- name: Remove a custom property
  microsoft.scvmm.scvmm_custom_property:
    name: CostCenter
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
custom_property:
  description: Details of the custom property.
  returned: when state is present and custom property exists
  type: dict
  contains:
    id:
      description: Custom property ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Custom property name.
      type: str
      returned: always
      sample: "CostCenter"
    description:
      description: Custom property description.
      type: str
      returned: when available
      sample: "Cost center code for billing"
    member_types:
      description: List of SCVMM object types this custom property applies to.
      type: list
      elements: str
      returned: always
      sample: ["Cloud", "VM"]
'''
