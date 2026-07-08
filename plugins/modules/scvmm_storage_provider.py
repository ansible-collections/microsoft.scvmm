# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_storage_provider
short_description: Manage storage providers in System Center Virtual Machine Manager
description:
  - Add, update, or remove Windows Native WMI storage providers in SCVMM.
  - Uses Add-SCStorageProvider with -AddWindowsNativeWmiProvider to register new providers.
  - Uses Set-SCStorageProvider to update existing provider properties.
  - Uses Remove-SCStorageProvider to unregister providers.
  - SMI-S CIM-XML and SMI-S WMI provider types are not supported by this module.
options:
  name:
    description:
      - Name of the storage provider.
    type: str
    required: true
  computer_name:
    description:
      - FQDN or IP of the host running the storage provider agent.
      - Required when O(state=present).
    type: str
  run_as_account:
    description:
      - Name of the RunAs account to use for connecting to the provider.
      - Required when O(state=present).
    type: str
  description:
    description:
      - Description of the storage provider.
    type: str
  state:
    description:
      - Desired state of the storage provider.
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
- name: Add a storage provider
  microsoft.scvmm.scvmm_storage_provider:
    name: SAN-Provider
    computer_name: san-host.example.com
    run_as_account: SAN-RunAs
    state: present
    vmm_server: scvmm.example.com

- name: Update storage provider description
  microsoft.scvmm.scvmm_storage_provider:
    name: SAN-Provider
    computer_name: san-host.example.com
    description: Updated SAN provider
    state: present
    vmm_server: scvmm.example.com

- name: Remove a storage provider
  microsoft.scvmm.scvmm_storage_provider:
    name: SAN-Provider
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
storage_provider:
  description: Details of the storage provider.
  returned: when state is present and provider exists
  type: dict
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
