# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_mac_address_pool
short_description: Manage MAC address pools in SCVMM
description:
  - Create, update, or remove MAC address pools in System Center Virtual Machine Manager.
  - MAC address pools define ranges of MAC addresses assigned to virtual network adapters.
  - Uses New-SCMACAddressPool to create new pools.
  - Uses Set-SCMACAddressPool to update existing pools.
  - Uses Remove-SCMACAddressPool to delete pools.
options:
  name:
    description:
      - Name of the MAC address pool.
    type: str
    required: true
  description:
    description:
      - Description of the MAC address pool.
    type: str
  mac_address_range_start:
    description:
      - Starting MAC address of the pool range.
      - Required when creating a new pool.
    type: str
  mac_address_range_end:
    description:
      - Ending MAC address of the pool range.
      - Required when creating a new pool.
    type: str
  host_groups:
    description:
      - List of host group names to associate with this pool.
      - Required when creating a new pool.
    type: list
    elements: str
  state:
    description:
      - Desired state of the MAC address pool.
      - C(present) creates or updates a pool.
      - C(absent) removes a pool.
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
- name: Create a MAC address pool
  microsoft.scvmm.scvmm_mac_address_pool:
    name: Default-MAC-Pool
    description: Default MAC address pool
    mac_address_range_start: "00-1D-D8-B7-1C-00"
    mac_address_range_end: "00-1D-D8-F4-1F-FF"
    host_groups:
      - All Hosts
    state: present
    vmm_server: scvmm.example.com

- name: Remove a MAC address pool
  microsoft.scvmm.scvmm_mac_address_pool:
    name: Default-MAC-Pool
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
mac_address_pool:
  description: Details of the MAC address pool.
  returned: when state is present and pool exists
  type: dict
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
