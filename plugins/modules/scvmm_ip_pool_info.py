# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_ip_pool_info
short_description: Query static IP address pools in SCVMM
description:
  - Retrieve information about static IP address pools in SCVMM.
  - Can filter by name or logical network definition.
options:
  name:
    description:
      - Name of the IP address pool to query.
    type: str
  logical_network_definition:
    description:
      - Filter pools by logical network definition name.
    type: str
  vmm_server:
    description:
      - SCVMM server to connect to.
    type: str
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Get all IP address pools
  microsoft.scvmm.scvmm_ip_pool_info:
    vmm_server: scvmm.example.com

- name: Get pools for a specific logical network definition
  microsoft.scvmm.scvmm_ip_pool_info:
    logical_network_definition: MyLND
    vmm_server: scvmm.example.com
'''

RETURN = r'''
ip_pools:
  description: List of IP address pools.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: Pool ID.
      type: str
    name:
      description: Pool name.
      type: str
    description:
      description: Pool description.
      type: str
    subnet:
      description: Subnet in CIDR notation.
      type: str
    ip_address_range_start:
      description: Starting IP address.
      type: str
    ip_address_range_end:
      description: Ending IP address.
      type: str
    default_gateways:
      description: Default gateway addresses.
      type: list
    dns_servers:
      description: DNS server addresses.
      type: list
    dns_suffix:
      description: DNS suffix.
      type: str
    logical_network_definition:
      description: Associated logical network definition name.
      type: str
'''
