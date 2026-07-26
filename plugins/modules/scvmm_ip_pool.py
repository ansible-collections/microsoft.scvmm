# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_ip_pool
short_description: Manage static IP address pools in SCVMM
description:
  - Create, update, or remove static IP address pools in System Center Virtual Machine Manager.
  - IP pools define ranges of IP addresses allocated to VMs from a logical network definition.
options:
  name:
    description:
      - Name of the IP address pool.
    type: str
    required: true
  description:
    description:
      - Description of the IP address pool.
    type: str
  logical_network_definition:
    description:
      - Name of the logical network definition to associate.
      - Required when creating a new pool.
    type: str
  subnet:
    description:
      - Subnet in CIDR notation (e.g. 10.0.0.0/24).
      - Required when creating a new pool.
    type: str
  ip_address_range_start:
    description:
      - Starting IP address of the pool range.
    type: str
  ip_address_range_end:
    description:
      - Ending IP address of the pool range.
    type: str
  default_gateways:
    description:
      - List of default gateway addresses.
    type: list
    elements: str
  dns_servers:
    description:
      - List of DNS server addresses.
    type: list
    elements: str
  dns_suffix:
    description:
      - DNS suffix for the pool.
    type: str
  dns_search_suffixes:
    description:
      - List of DNS search suffixes.
    type: list
    elements: str
  state:
    description:
      - Desired state of the IP address pool.
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
- name: Create an IP address pool
  microsoft.scvmm.scvmm_ip_pool:
    name: MyIPPool
    logical_network_definition: MyLND
    subnet: "10.0.0.0/24"
    ip_address_range_start: "10.0.0.10"
    ip_address_range_end: "10.0.0.200"
    default_gateways:
      - "10.0.0.1"
    dns_servers:
      - "10.0.0.2"
    state: present
    vmm_server: scvmm.example.com

- name: Remove an IP address pool
  microsoft.scvmm.scvmm_ip_pool:
    name: MyIPPool
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
ip_pool:
  description: Details of the IP address pool.
  returned: when state is present
  type: dict
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
      elements: str
    dns_servers:
      description: DNS server addresses.
      type: list
      elements: str
    dns_suffix:
      description: DNS suffix.
      type: str
    dns_search_suffixes:
      description: DNS search suffixes.
      type: list
      elements: str
    logical_network_definition:
      description: Associated logical network definition name.
      type: str
'''
