# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_custom_property_info
version_added: "1.1.0"
short_description: Query custom properties in System Center Virtual Machine Manager
description:
  - Retrieve information about custom properties in SCVMM.
  - Can query all custom properties or filter by name.
  - Custom properties are user-defined metadata fields attached to SCVMM objects.
options:
  name:
    description:
      - Name of the custom property to query.
      - If not specified, returns all custom properties.
      - Mutually exclusive with I(member).
    type: str
  member:
    description:
      - Filter custom properties by SCVMM object member type.
      - Returns only custom properties that apply to the specified member type.
      - Mutually exclusive with I(name).
    type: str
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
- name: Get all custom properties
  microsoft.scvmm.scvmm_custom_property_info:
    vmm_server: scvmm.example.com
  register: all_properties

- name: Get a specific custom property
  microsoft.scvmm.scvmm_custom_property_info:
    name: CostCenter
    vmm_server: scvmm.example.com
  register: property_info

- name: Get custom properties for VMs
  microsoft.scvmm.scvmm_custom_property_info:
    member: VM
    vmm_server: scvmm.example.com
  register: vm_properties

- name: Display custom properties
  ansible.builtin.debug:
    msg: "{{ item.name }} applies to {{ item.member_types }}"
  loop: "{{ all_properties.custom_properties }}"
'''

RETURN = r'''
custom_properties:
  description: List of custom properties.
  returned: always
  type: list
  elements: dict
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
      returned: always
    member_types:
      description: List of SCVMM object types this custom property applies to.
      type: list
      elements: str
      returned: always
      sample: ["Cloud", "VM"]
'''
