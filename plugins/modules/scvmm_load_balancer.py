# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_load_balancer
short_description: Manage load balancers in SCVMM
description:
  - Register, update, or remove load balancers in System Center Virtual Machine Manager.
  - Uses Add-SCLoadBalancer to register a new load balancer appliance.
  - Uses Set-SCLoadBalancer to update settings.
  - Uses Remove-SCLoadBalancer to unregister.
options:
  address:
    description:
      - IP address or FQDN of the load balancer.
    type: str
    required: true
  port:
    description:
      - Management port for the load balancer.
    type: int
    default: 443
  manufacturer:
    description:
      - Manufacturer of the load balancer.
      - Required when registering a new load balancer.
    type: str
  model:
    description:
      - Model of the load balancer.
      - Required when registering a new load balancer.
    type: str
  configuration_provider:
    description:
      - Name of the SCVMM configuration provider for the load balancer.
      - Required when registering a new load balancer.
    type: str
  run_as_account:
    description:
      - Name of the Run As account for load balancer management.
      - Required when registering a new load balancer.
    type: str
  host_groups:
    description:
      - List of host group names to associate with the load balancer.
      - Required when registering a new load balancer.
    type: list
    elements: str
  state:
    description:
      - Desired state of the load balancer.
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
- name: Register a load balancer
  microsoft.scvmm.scvmm_load_balancer:
    address: lb.example.com
    port: 443
    manufacturer: Microsoft
    model: NLB
    configuration_provider: Microsoft Network Load Balancing (NLB)
    run_as_account: LBAdmin
    host_groups:
      - All Hosts
    state: present
    vmm_server: scvmm.example.com

- name: Remove a load balancer
  microsoft.scvmm.scvmm_load_balancer:
    address: lb.example.com
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
load_balancer:
  description: Details of the load balancer.
  returned: when state is present
  type: dict
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
