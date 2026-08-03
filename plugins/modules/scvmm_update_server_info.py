# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_update_server_info
version_added: "1.1.0"
short_description: Query WSUS update servers in System Center Virtual Machine Manager
description:
  - Retrieve information about WSUS update servers registered in SCVMM.
  - Can query a specific server by computer name or return all registered servers.
options:
  computer_name:
    description:
      - FQDN, IP address, or NetBIOS name of the WSUS server to query.
      - If not specified, returns all registered update servers.
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
- name: Get all registered update servers
  microsoft.scvmm.scvmm_update_server_info:
  register: all_servers

- name: Get a specific update server
  microsoft.scvmm.scvmm_update_server_info:
    computer_name: wsus.example.com
  register: wsus_info

- name: Display update server details
  ansible.builtin.debug:
    msg: "WSUS {{ item.name }} on port {{ item.port }}"
  loop: "{{ all_servers.update_servers }}"
'''

RETURN = r'''
update_servers:
  description: List of WSUS update servers.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: Update server ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Name of the update server.
      type: str
      returned: always
      sample: "wsus.example.com"
    fqdn:
      description: Fully qualified domain name of the WSUS server.
      type: str
      returned: when available
      sample: "wsus.example.com"
    port:
      description: TCP port used by the WSUS server.
      type: int
      returned: when available
      sample: 8530
    is_connection_secure:
      description: Whether the WSUS connection uses SSL.
      type: bool
      returned: always
      sample: false
    server_state:
      description: Current operational state of the update server.
      type: str
      returned: when available
      sample: "Available"
    update_categories:
      description: List of product categories configured for synchronisation.
      type: list
      elements: str
      returned: always
      sample: ["Windows Server 2019"]
    update_classifications:
      description: List of update classifications configured for synchronisation.
      type: list
      elements: str
      returned: always
      sample: ["Security Updates", "Critical Updates"]
    update_languages:
      description: List of languages configured for synchronisation.
      type: list
      elements: str
      returned: always
      sample: ["en"]
'''
