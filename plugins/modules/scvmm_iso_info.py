# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_iso_info
version_added: "1.1.0"
short_description: Query ISO images in the SCVMM library
description:
  - Retrieve information about ISO images in the SCVMM library.
  - Can query all ISOs or filter by name.
options:
  name:
    description:
      - Name of the ISO image to query.
      - If not specified, returns all ISO images.
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
- name: Get all ISO images
  microsoft.scvmm.scvmm_iso_info:
    vmm_server: scvmm.example.com
  register: all_isos

- name: Get a specific ISO by name
  microsoft.scvmm.scvmm_iso_info:
    name: WindowsServer2022.iso
    vmm_server: scvmm.example.com
  register: iso_info

- name: Display ISO details
  ansible.builtin.debug:
    msg: "ISO {{ item.name }} at {{ item.share_path }}"
  loop: "{{ all_isos.isos }}"
'''

RETURN = r'''
isos:
  description: List of ISO images.
  returned: always
  type: list
  elements: dict
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
