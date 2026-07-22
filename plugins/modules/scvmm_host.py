# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_host
short_description: Manage Hyper-V hosts in System Center Virtual Machine Manager
description:
  - Add, update, or remove Hyper-V hosts from SCVMM management.
  - Can onboard hosts to SCVMM, configure host properties, and toggle maintenance mode.
  - Can remove hosts from SCVMM management.
options:
  name:
    description:
      - FQDN of the Hyper-V host to manage.
    type: str
    required: true
  state:
    description:
      - Desired state of the host in SCVMM.
      - C(present) adds or updates the host.
      - C(absent) removes the host from SCVMM management.
    type: str
    choices: [present, absent]
    default: present
  host_group:
    description:
      - Name of the host group to place the host in.
      - Required when adding a new host to SCVMM.
    type: str
  description:
    description:
      - Description for the host.
    type: str
  maintenance_mode:
    description:
      - Whether to place the host in maintenance mode.
    type: bool
  available_for_placement:
    description:
      - Whether the host is available for VM placement.
    type: bool
  credential_username:
    description:
      - Username for host management operations.
      - Required when adding a new host.
    type: str
  credential_password:
    description:
      - Password for host management operations.
      - Required when adding a new host.
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
- name: Add a host to SCVMM
  microsoft.scvmm.scvmm_host:
    name: host01.example.com
    state: present
    host_group: All Hosts
    credential_username: admin@example.com
    credential_password: secret
    vmm_server: scvmm.example.com

- name: Update host description
  microsoft.scvmm.scvmm_host:
    name: host01.example.com
    description: Production Hyper-V host
    vmm_server: scvmm.example.com

- name: Place host in maintenance mode
  microsoft.scvmm.scvmm_host:
    name: host01.example.com
    maintenance_mode: true
    vmm_server: scvmm.example.com

- name: Remove host from SCVMM
  microsoft.scvmm.scvmm_host:
    name: host01.example.com
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
host:
  description: The managed host details.
  returned: when state is present
  type: dict
  contains:
    id:
      description: Host ID in SCVMM.
      type: str
      returned: always
    name:
      description: Host FQDN.
      type: str
      returned: always
    description:
      description: Host description.
      type: str
      returned: always
    host_group:
      description: Name of the host group.
      type: str
      returned: always
    maintenance_mode:
      description: Whether the host is in maintenance mode.
      type: bool
      returned: always
    available_for_placement:
      description: Whether available for VM placement.
      type: bool
      returned: always
    overall_state:
      description: Overall state of the host.
      type: str
      returned: always
      sample: "Ok"
'''
