# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_library_share_info
version_added: "1.1.0"
short_description: Query library shares in System Center Virtual Machine Manager
description:
  - Retrieve information about library shares in SCVMM.
  - Can query all library shares or filter by name.
options:
  name:
    description:
      - Name of the library share to query.
      - If not specified, returns all library shares.
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
- name: Get all library shares
  microsoft.scvmm.scvmm_library_share_info:
    vmm_server: scvmm.example.com
  register: all_shares

- name: Get a specific library share by name
  microsoft.scvmm.scvmm_library_share_info:
    name: MSSCVMMLibrary
    vmm_server: scvmm.example.com
  register: share_info

- name: Display library share details
  ansible.builtin.debug:
    msg: "Share {{ item.name }} at {{ item.share_path }}"
  loop: "{{ all_shares.library_shares }}"
'''

RETURN = r'''
library_shares:
  description: List of library shares.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: Library share ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Library share name.
      type: str
      returned: always
      sample: "MSSCVMMLibrary"
    description:
      description: Library share description.
      type: str
      returned: when available
      sample: "Default VMM library share"
    share_path:
      description: UNC path of the library share.
      type: str
      returned: always
      sample: "\\\\libserver01.contoso.com\\MSSCVMMLibrary"
    library_server:
      description: Name of the library server hosting this share.
      type: str
      returned: always
      sample: "libserver01.contoso.com"
    use_alternate_data_stream:
      description: Whether alternate data stream is enabled.
      type: bool
      returned: always
      sample: true
'''
