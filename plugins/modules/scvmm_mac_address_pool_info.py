# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_mac_address_pool_info
short_description: Query MAC address pools in SCVMM
description:
  - Retrieve information about MAC address pools in SCVMM.
  - Can query all pools or filter by name.
options:
  name:
    description:
      - Name of the MAC address pool to query.
      - If not specified, returns all pools.
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
- name: Get all MAC address pools
  microsoft.scvmm.scvmm_mac_address_pool_info:
    vmm_server: scvmm.example.com
  register: all_pools

- name: Get a specific MAC address pool
  microsoft.scvmm.scvmm_mac_address_pool_info:
    name: Default-MAC-Pool
    vmm_server: scvmm.example.com
  register: pool_info
'''

RETURN = r'''
mac_address_pools:
  description: List of MAC address pools.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: Pool ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Pool name.
      type: str
      returned: always
      sample: Default-MAC-Pool
    description:
      description: Pool description.
      type: str
      returned: always
      sample: Default MAC address pool
    mac_address_range_start:
      description: Starting MAC address.
      type: str
      returned: always
      sample: "00-1D-D8-B7-1C-00"
    mac_address_range_end:
      description: Ending MAC address.
      type: str
      returned: always
      sample: "00-1D-D8-F4-1F-FF"
    host_groups:
      description: List of associated host group names.
      type: list
      elements: str
      returned: always
      sample: ["All Hosts"]
'''
