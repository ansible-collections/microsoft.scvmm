# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_load_balancer_info
short_description: Query load balancers in SCVMM
description:
  - Retrieve information about load balancers registered in SCVMM.
  - Can filter by address or manufacturer.
options:
  address:
    description:
      - Filter by load balancer address.
    type: str
  manufacturer:
    description:
      - Filter by manufacturer.
    type: str
  vmm_server:
    description:
      - SCVMM server to connect to.
    type: str
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Get all load balancers
  microsoft.scvmm.scvmm_load_balancer_info:
    vmm_server: scvmm.example.com

- name: Get load balancer by address
  microsoft.scvmm.scvmm_load_balancer_info:
    address: lb.example.com
    vmm_server: scvmm.example.com
'''

RETURN = r'''
load_balancers:
  description: List of load balancers.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: Load balancer ID.
      type: str
    address:
      description: Load balancer address.
      type: str
    port:
      description: Management port.
      type: int
    manufacturer:
      description: Manufacturer.
      type: str
    model:
      description: Model.
      type: str
    configuration_provider:
      description: Configuration provider name.
      type: str
    host_groups:
      description: Associated host group names.
      type: list
      elements: str
'''
