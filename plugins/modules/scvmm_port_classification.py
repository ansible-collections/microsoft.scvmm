# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_port_classification
version_added: "1.0.0"
short_description: Manage port classifications in System Center Virtual Machine Manager
description:
  - Create, update, or remove port classifications in SCVMM.
  - Port classifications are abstraction labels that map to virtual network adapter port profiles.
  - They are used when configuring logical switches to assign port profiles to virtual network adapters.
options:
  name:
    description:
      - Name of the port classification.
    type: str
    required: true
  description:
    description:
      - Description of the port classification.
    type: str
  state:
    description:
      - Desired state of the port classification.
      - C(present) creates or updates a port classification.
      - C(absent) removes a port classification.
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
- name: Create a port classification
  microsoft.scvmm.scvmm_port_classification:
    name: HighBandwidth
    description: High bandwidth port classification
    state: present
    vmm_server: scvmm.example.com

- name: Update port classification description
  microsoft.scvmm.scvmm_port_classification:
    name: HighBandwidth
    description: Updated high bandwidth classification
    state: present
    vmm_server: scvmm.example.com

- name: Remove a port classification
  microsoft.scvmm.scvmm_port_classification:
    name: HighBandwidth
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
port_classification:
  description: Details of the port classification.
  returned: when state is present and port classification exists
  type: dict
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
      sample: HighBandwidth
    description:
      description: Port classification description.
      type: str
      returned: when available
      sample: High bandwidth port classification
'''
