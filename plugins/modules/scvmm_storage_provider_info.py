# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_storage_provider_info
short_description: Query storage providers in System Center Virtual Machine Manager
description:
  - Retrieve information about storage providers in SCVMM.
  - Can query all providers or filter by name.
options:
  name:
    description:
      - Name of the storage provider to query.
      - If not specified, returns all storage providers.
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
- name: Get all storage providers
  microsoft.scvmm.scvmm_storage_provider_info:
    vmm_server: scvmm.example.com
  register: all_providers

- name: Get a specific storage provider
  microsoft.scvmm.scvmm_storage_provider_info:
    name: SAN-Provider
    vmm_server: scvmm.example.com
  register: provider_info

- name: Display provider details
  ansible.builtin.debug:
    msg: "Provider {{ item.name }} ({{ item.provider_type }}) has {{ item.storage_arrays | length }} arrays"
  loop: "{{ all_providers.storage_providers }}"
'''

RETURN = r'''
storage_providers:
  description: List of storage providers.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: Storage provider ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Storage provider name.
      type: str
      returned: always
      sample: SAN-Provider
    description:
      description: Storage provider description.
      type: str
      returned: when available
      sample: Primary SAN provider
    network_address:
      description: Network address of the provider.
      type: str
      returned: when available
      sample: "192.168.1.100"
    provider_type:
      description: Type of storage provider.
      type: str
      returned: when available
      sample: SMI-S
    status:
      description: Current status of the provider.
      type: str
      returned: when available
      sample: Online
    enabled:
      description: Whether the provider is enabled.
      type: bool
      returned: always
      sample: true
    storage_arrays:
      description: Names of storage arrays discovered by this provider.
      type: list
      elements: str
      returned: always
      sample: ["Array1", "Array2"]
'''
