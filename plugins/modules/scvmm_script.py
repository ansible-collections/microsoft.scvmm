# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_script
version_added: "1.1.0"
short_description: Manage scripts in the SCVMM library
description:
  - Update properties or remove scripts in the SCVMM library.
  - Uses Set-SCScript to update existing script properties.
  - Uses Remove-SCScript to delete a script from the library and file system.
  - Scripts cannot be created by this module. They are discovered automatically
    when placed on a library share and the share is refreshed.
options:
  name:
    description:
      - Name of the script.
      - Used to look up the script in the VMM library.
    type: str
    required: true
  description:
    description:
      - Description of the script.
    type: str
  family_name:
    description:
      - Family name for the script.
    type: str
  release:
    description:
      - Release identifier for the script.
    type: str
  enabled:
    description:
      - Whether the script is enabled in the library.
    type: bool
  owner:
    description:
      - Owner of the script.
      - Typically a domain account in C(DOMAIN\\username) format.
    type: str
  state:
    description:
      - Desired state of the script.
      - C(present) updates the properties of an existing script.
      - C(absent) removes the script from the library and deletes the file.
      - This module cannot create new scripts. Use C(state=present) only with
        scripts that already exist in the library.
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
- name: Update script description
  microsoft.scvmm.scvmm_script:
    name: deploy.ps1
    description: "Deployment automation script"
    state: present
    vmm_server: scvmm.example.com

- name: Set script family name and release
  microsoft.scvmm.scvmm_script:
    name: deploy.ps1
    family_name: "Deployment Scripts"
    release: "2.0"
    state: present
    vmm_server: scvmm.example.com

- name: Remove a script from the library
  microsoft.scvmm.scvmm_script:
    name: old_script.ps1
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
script:
  description: Details of the script.
  returned: when state is present and script exists
  type: dict
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
