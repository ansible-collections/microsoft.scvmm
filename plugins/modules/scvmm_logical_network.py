# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_logical_network
short_description: Manage logical networks in System Center Virtual Machine Manager
description:
  - Create, update, or remove logical networks in SCVMM.
  - Uses New-SCLogicalNetwork to create new logical networks.
  - Uses Set-SCLogicalNetwork to update existing logical networks.
  - Uses Remove-SCLogicalNetwork to delete logical networks.
options:
  name:
    description:
      - Name of the logical network.
    type: str
    required: true
  description:
    description:
      - Description of the logical network.
    type: str
  network_virtualization_enabled:
    description:
      - Whether network virtualization is enabled for this logical network.
    type: bool
  use_gre:
    description:
      - Whether to use Generic Routing Encapsulation (GRE) for network virtualization.
    type: bool
  is_pvlan:
    description:
      - Whether this logical network uses Private VLAN (PVLAN).
      - This property can only be set at creation time.
    type: bool
  definition_isolation:
    description:
      - Whether logical network definition isolation is enabled.
    type: bool
  allow_dynamic_vlan_on_vnic:
    description:
      - Whether to allow dynamic VLAN on virtual network adapters.
    type: bool
  state:
    description:
      - Desired state of the logical network.
      - C(present) creates or updates a logical network.
      - C(absent) removes a logical network.
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
- name: Create a logical network
  microsoft.scvmm.scvmm_logical_network:
    name: Management-LN
    description: Management logical network
    state: present
    vmm_server: scvmm.example.com

- name: Create a logical network with network virtualization
  microsoft.scvmm.scvmm_logical_network:
    name: Tenant-LN
    description: Tenant isolation network
    network_virtualization_enabled: true
    state: present
    vmm_server: scvmm.example.com

- name: Update logical network description
  microsoft.scvmm.scvmm_logical_network:
    name: Management-LN
    description: Updated management network
    state: present
    vmm_server: scvmm.example.com

- name: Remove a logical network
  microsoft.scvmm.scvmm_logical_network:
    name: Management-LN
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
logical_network:
  description: Details of the logical network.
  returned: when state is present and logical network exists
  type: dict
  contains:
    id:
      description: Logical network ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Logical network name.
      type: str
      returned: always
      sample: Management-LN
    description:
      description: Logical network description.
      type: str
      returned: when available
      sample: Management logical network
    network_virtualization_enabled:
      description: Whether network virtualization is enabled.
      type: bool
      returned: always
      sample: false
    use_gre:
      description: Whether GRE is enabled.
      type: bool
      returned: always
      sample: false
    is_pvlan:
      description: Whether PVLAN is enabled.
      type: bool
      returned: always
      sample: false
    definition_isolation:
      description: Whether logical network definition isolation is enabled.
      type: bool
      returned: always
      sample: false
    allow_dynamic_vlan_on_vnic:
      description: Whether dynamic VLAN on vNIC is allowed.
      type: bool
      returned: always
      sample: false
'''
