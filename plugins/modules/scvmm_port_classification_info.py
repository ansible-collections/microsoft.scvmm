# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_port_classification_info
version_added: "1.0.0"
short_description: Query port classifications in System Center Virtual Machine Manager
description:
  - Retrieve information about port classifications in SCVMM.
  - Can query all port classifications or filter by name.
  - Port classifications are abstraction labels used by logical switches to assign port profiles.
options:
  name:
    description:
      - Name of the port classification to query.
      - If not specified, returns all port classifications.
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
- name: Get all port classifications
  microsoft.scvmm.scvmm_port_classification_info:
    vmm_server: scvmm.example.com
  register: all_classifications

- name: Get a specific port classification
  microsoft.scvmm.scvmm_port_classification_info:
    name: HighBandwidth
    vmm_server: scvmm.example.com
  register: classification_info

- name: Display port classifications
  ansible.builtin.debug:
    msg: "{{ item.name }} - {{ item.description }}"
  loop: "{{ all_classifications.port_classifications }}"
'''

RETURN = r'''
port_classifications:
  description: List of port classifications.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: Port classification ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Port classification name.
      type: str
      returned: always
      sample: "HighBandwidth"
    description:
      description: Port classification description.
      type: str
      returned: always
'''
