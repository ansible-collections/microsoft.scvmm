# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_pxe_server_info
version_added: "1.1.0"
short_description: Query PXE servers in System Center Virtual Machine Manager
description:
  - Retrieve information about PXE servers registered in SCVMM.
  - Can query all PXE servers or filter by computer name.
options:
  computer_name:
    description:
      - Hostname or FQDN of the PXE server to query.
      - If not specified, returns all registered PXE servers.
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
- name: Get all PXE servers
  microsoft.scvmm.scvmm_pxe_server_info:
    vmm_server: scvmm.example.com
  register: all_pxe

- name: Get a specific PXE server by computer name
  microsoft.scvmm.scvmm_pxe_server_info:
    computer_name: wds01.contoso.com
    vmm_server: scvmm.example.com
  register: pxe_info

- name: Display PXE server details
  ansible.builtin.debug:
    msg: "PXE server {{ item.name }}"
  loop: "{{ all_pxe.pxe_servers }}"
'''

RETURN = r'''
pxe_servers:
  description: List of PXE servers.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: PXE server ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Name of the PXE server.
      type: str
      returned: always
      sample: "wds01.contoso.com"
    managed_computer:
      description: FQDN of the managed computer associated with this PXE server.
      type: str
      returned: always
      sample: "wds01.contoso.com"
'''
