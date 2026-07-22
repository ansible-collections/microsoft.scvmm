# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_logical_switch
short_description: Manage logical switches in SCVMM
description:
  - Create, update, or remove logical switches in System Center Virtual Machine Manager.
  - Logical switches aggregate port profiles, classifications, and bandwidth settings
    for virtual network configuration on Hyper-V hosts.
options:
  name:
    description:
      - Name of the logical switch.
    type: str
    required: true
  description:
    description:
      - Description of the logical switch.
    type: str
  minimum_bandwidth_mode:
    description:
      - Minimum bandwidth allocation mode.
    type: str
    choices: ['Weight', 'Absolute', 'Default', 'None']
  enable_sriov:
    description:
      - Enable SR-IOV on the logical switch.
    type: bool
  enable_packet_direct:
    description:
      - Enable Packet Direct on the logical switch.
    type: bool
  state:
    description:
      - Desired state of the logical switch.
    type: str
    choices: ['present', 'absent']
    default: present
  vmm_server:
    description:
      - SCVMM server to connect to.
    type: str
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Create a logical switch
  microsoft.scvmm.scvmm_logical_switch:
    name: MyLogicalSwitch
    description: Production logical switch
    minimum_bandwidth_mode: Weight
    state: present
    vmm_server: scvmm.example.com

- name: Remove a logical switch
  microsoft.scvmm.scvmm_logical_switch:
    name: MyLogicalSwitch
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
logical_switch:
  description: Details of the logical switch.
  returned: when state is present
  type: dict
  contains:
    id:
      description: Switch ID.
      type: str
    name:
      description: Switch name.
      type: str
    description:
      description: Switch description.
      type: str
    minimum_bandwidth_mode:
      description: Bandwidth allocation mode.
      type: str
    enable_sriov:
      description: Whether SR-IOV is enabled.
      type: bool
    enable_packet_direct:
      description: Whether Packet Direct is enabled.
      type: bool
'''
