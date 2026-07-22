# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_uplink_port_profile_info
short_description: Query native uplink port profiles in SCVMM
description:
  - Retrieve information about native uplink port profiles in SCVMM.
  - Can query all profiles or filter by name.
options:
  name:
    description:
      - Name of the uplink port profile to query.
      - If not specified, returns all profiles.
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
- name: Get all uplink port profiles
  microsoft.scvmm.scvmm_uplink_port_profile_info:
    vmm_server: scvmm.example.com
  register: all_profiles

- name: Get a specific uplink port profile
  microsoft.scvmm.scvmm_uplink_port_profile_info:
    name: HostUplink-Profile
    vmm_server: scvmm.example.com
  register: profile_info
'''

RETURN = r'''
uplink_port_profiles:
  description: List of uplink port profiles.
  returned: always
  type: list
  elements: dict
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
