# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_iso
version_added: "1.1.0"
short_description: Manage ISO images in the SCVMM library
description:
  - Update properties or remove ISO images in the SCVMM library.
  - Uses Set-SCISO to update existing ISO properties.
  - Uses Remove-SCISO to delete an ISO from the library and file system.
  - ISOs cannot be created by this module. They are discovered automatically
    when placed on a library share and the share is refreshed.
options:
  name:
    description:
      - Name of the ISO image.
      - Used to look up the ISO in the VMM library.
    type: str
    required: true
  description:
    description:
      - Description of the ISO image.
    type: str
  family_name:
    description:
      - Family name for the ISO image.
    type: str
  release:
    description:
      - Release identifier for the ISO image.
    type: str
  enabled:
    description:
      - Whether the ISO image is enabled in the library.
      - Disabled ISOs cannot be used in templates or VM deployments.
    type: bool
  owner:
    description:
      - Owner of the ISO image.
      - Typically a domain account in C(DOMAIN\\username) format.
      - This is a read-only property. The value is returned in query results
        but cannot be changed via this module because C(Set-SCISO -Owner) is
        silently ignored by VMM.
    type: str
  state:
    description:
      - Desired state of the ISO image.
      - C(present) updates the properties of an existing ISO.
      - C(absent) removes the ISO from the library and deletes the file.
      - This module cannot create new ISOs. Use C(state=present) only with
        ISOs that already exist in the library.
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
- name: Update ISO description
  microsoft.scvmm.scvmm_iso:
    name: WindowsServer2022.iso
    description: "Windows Server 2022 evaluation ISO"
    state: present
    vmm_server: scvmm.example.com

- name: Set ISO family name and release
  microsoft.scvmm.scvmm_iso:
    name: WindowsServer2022.iso
    family_name: "Windows Server"
    release: "2022"
    state: present
    vmm_server: scvmm.example.com

- name: Remove an ISO from the library
  microsoft.scvmm.scvmm_iso:
    name: OldImage.iso
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
iso:
  description: Details of the ISO image.
  returned: when state is present and ISO exists
  type: dict
  contains:
    id:
      description: ISO ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: ISO file name.
      type: str
      returned: always
      sample: "WindowsServer2022.iso"
    description:
      description: ISO description.
      type: str
      returned: when available
      sample: "Windows Server 2022 evaluation ISO"
    share_path:
      description: Library share path where the ISO is stored.
      type: str
      returned: always
      sample: "\\\\libserver01\\MSSCVMMLibrary\\ISOs\\WindowsServer2022.iso"
    library_server:
      description: Name of the library server hosting this ISO.
      type: str
      returned: always
      sample: "libserver01.contoso.com"
    family_name:
      description: Family name of the ISO.
      type: str
      returned: when available
      sample: "Windows Server"
    release:
      description: Release identifier.
      type: str
      returned: when available
      sample: "2022"
    owner:
      description: Owner of the ISO.
      type: str
      returned: when available
      sample: "CONTOSO\\admin"
    enabled:
      description: Whether the ISO is enabled.
      type: bool
      returned: always
      sample: true
    is_orphaned:
      description: Whether the ISO file is orphaned (missing from disk).
      type: bool
      returned: always
      sample: false
'''
