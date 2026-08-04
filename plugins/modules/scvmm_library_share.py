# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_library_share
version_added: "1.1.0"
short_description: Manage library shares in System Center Virtual Machine Manager
description:
  - Add, update, or remove library shares in SCVMM.
  - Uses Add-SCLibraryShare to register a new Windows share as a VMM library share.
  - Uses Set-SCLibraryShare to update existing library share properties.
  - Uses Remove-SCLibraryShare to unregister a library share from VMM.
  - Removing a library share from VMM does not delete the underlying Windows share or its files.
options:
  name:
    description:
      - Name of the library share.
      - Used to look up existing library shares.
    type: str
    required: true
  share_path:
    description:
      - UNC path to the Windows share to register as a VMM library share.
      - "Example: C(\\\\libserver01\\MSSCVMMLibrary)."
      - Required when adding a new library share (C(state=present) and the share does not exist).
      - The share must already exist in the Windows file system before it can be added.
    type: str
  description:
    description:
      - Description of the library share.
    type: str
  add_default_resources:
    description:
      - Whether to add default resources to the library share.
    type: bool
  use_alternate_data_stream:
    description:
      - Whether to use the alternate data stream for the library share.
    type: bool
  state:
    description:
      - Desired state of the library share.
      - C(present) adds or updates a library share.
      - C(absent) removes a library share from VMM without deleting the underlying share.
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
- name: Add a library share
  microsoft.scvmm.scvmm_library_share:
    name: MyLibrary
    share_path: "\\\\libserver01\\MyLibrary"
    description: "Custom library share for templates"
    state: present
    vmm_server: scvmm.example.com

- name: Update library share description
  microsoft.scvmm.scvmm_library_share:
    name: MyLibrary
    description: "Updated description"
    state: present
    vmm_server: scvmm.example.com

- name: Remove a library share from VMM
  microsoft.scvmm.scvmm_library_share:
    name: MyLibrary
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
library_share:
  description: Details of the library share.
  returned: when state is present and share exists
  type: dict
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
