# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_uplink_port_profile
short_description: Manage native uplink port profiles in SCVMM
description:
  - Create, update, or remove native uplink port profiles in System Center Virtual Machine Manager.
  - Uplink port profiles define how a host connects to logical networks.
  - Uses New-SCNativeUplinkPortProfile to create new profiles.
  - Uses Set-SCNativeUplinkPortProfile to update existing profiles.
  - Uses Remove-SCNativeUplinkPortProfile to delete profiles.
options:
  name:
    description:
      - Name of the uplink port profile.
    type: str
    required: true
  description:
    description:
      - Description of the uplink port profile.
    type: str
  enable_network_virtualization:
    description:
      - Whether network virtualization is enabled for this profile.
    type: bool
  logical_network_definitions:
    description:
      - List of logical network definition names to associate with this profile.
    type: list
    elements: str
  state:
    description:
      - Desired state of the uplink port profile.
      - C(present) creates or updates a profile.
      - C(absent) removes a profile.
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
- name: Create an uplink port profile
  microsoft.scvmm.scvmm_uplink_port_profile:
    name: HostUplink-Profile
    description: Host uplink port profile
    state: present
    vmm_server: scvmm.example.com

- name: Update profile description
  microsoft.scvmm.scvmm_uplink_port_profile:
    name: HostUplink-Profile
    description: Updated host uplink profile
    state: present
    vmm_server: scvmm.example.com

- name: Remove an uplink port profile
  microsoft.scvmm.scvmm_uplink_port_profile:
    name: HostUplink-Profile
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
uplink_port_profile:
  description: Details of the uplink port profile.
  returned: when state is present and profile exists
  type: dict
  contains:
    id:
      description: Profile ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Profile name.
      type: str
      returned: always
      sample: HostUplink-Profile
    description:
      description: Profile description.
      type: str
      returned: when available
      sample: Host uplink port profile
    enable_network_virtualization:
      description: Whether network virtualization is enabled.
      type: bool
      returned: always
      sample: false
    logical_network_definitions:
      description: List of associated logical network definition names.
      type: list
      elements: str
      returned: always
      sample: []
'''
