# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_logical_switch_info
short_description: Query logical switches in SCVMM
description:
  - Retrieve information about logical switches in SCVMM.
  - Can query all switches or filter by name.
options:
  name:
    description:
      - Name of the logical switch to query.
    type: str
  vmm_server:
    description:
      - SCVMM server to connect to.
    type: str
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Get all logical switches
  microsoft.scvmm.scvmm_logical_switch_info:
    vmm_server: scvmm.example.com

- name: Get a specific logical switch
  microsoft.scvmm.scvmm_logical_switch_info:
    name: MyLogicalSwitch
    vmm_server: scvmm.example.com
'''

RETURN = r'''
logical_switches:
  description: List of logical switches.
  returned: always
  type: list
  elements: dict
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
