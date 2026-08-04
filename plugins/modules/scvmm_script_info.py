# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_script_info
version_added: "1.1.0"
short_description: Query scripts in the SCVMM library
description:
  - Retrieve information about scripts in the SCVMM library.
  - Can query all scripts or filter by name.
options:
  name:
    description:
      - Name of the script to query.
      - If not specified, returns all scripts.
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
- name: Get all scripts
  microsoft.scvmm.scvmm_script_info:
    vmm_server: scvmm.example.com
  register: all_scripts

- name: Get a specific script by name
  microsoft.scvmm.scvmm_script_info:
    name: deploy.ps1
    vmm_server: scvmm.example.com
  register: script_info

- name: Display script details
  ansible.builtin.debug:
    msg: "Script {{ item.name }} at {{ item.share_path }}"
  loop: "{{ all_scripts.scripts }}"
'''

RETURN = r'''
scripts:
  description: List of scripts.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: Script ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Script file name.
      type: str
      returned: always
      sample: "deploy.ps1"
    description:
      description: Script description.
      type: str
      returned: when available
      sample: "Deployment automation script"
    share_path:
      description: Library share path where the script is stored.
      type: str
      returned: always
      sample: "\\\\libserver01\\MSSCVMMLibrary\\Scripts\\deploy.ps1"
    library_server:
      description: Name of the library server hosting this script.
      type: str
      returned: always
      sample: "libserver01.contoso.com"
    family_name:
      description: Family name of the script.
      type: str
      returned: when available
      sample: "Deployment Scripts"
    release:
      description: Release identifier.
      type: str
      returned: when available
      sample: "2.0"
    owner:
      description: Owner of the script.
      type: str
      returned: when available
      sample: "contoso\\administrator"
    enabled:
      description: Whether the script is enabled.
      type: bool
      returned: always
      sample: true
    is_orphaned:
      description: Whether the script file is orphaned (missing from disk).
      type: bool
      returned: always
      sample: false
'''
