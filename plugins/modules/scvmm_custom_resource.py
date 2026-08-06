# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_custom_resource
version_added: "1.1.0"
short_description: Manage custom resources in the SCVMM library
description:
  - Update properties or remove custom resources in the SCVMM library.
  - Uses Set-SCCustomResource to update existing custom resource properties.
  - Uses Remove-SCCustomResource to delete a custom resource from the library.
  - Custom resources cannot be created by this module. They are C(.cr) folders
    discovered automatically when placed on a library share and the share is refreshed.
options:
  name:
    description:
      - Name of the custom resource.
      - Used to look up the custom resource in the VMM library.
    type: str
    required: true
  description:
    description:
      - Description of the custom resource.
    type: str
  family_name:
    description:
      - Family name for the custom resource.
    type: str
  release:
    description:
      - Release identifier for the custom resource.
    type: str
  enabled:
    description:
      - Whether the custom resource is enabled in the library.
    type: bool
  owner:
    description:
      - Owner of the custom resource.
      - Typically a domain account in C(DOMAIN\\username) format.
    type: str
  state:
    description:
      - Desired state of the custom resource.
      - C(present) updates the properties of an existing custom resource.
      - C(absent) removes the custom resource from the VMM library. The on-disk C(.cr) folder is not deleted.
      - This module cannot create new custom resources. Use C(state=present) only with
        custom resources that already exist in the library.
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
- name: Update custom resource description
  microsoft.scvmm.scvmm_custom_resource:
    name: MyApp.cr
    description: "Application deployment package"
    state: present
    vmm_server: scvmm.example.com

- name: Set custom resource family name and release
  microsoft.scvmm.scvmm_custom_resource:
    name: MyApp.cr
    family_name: "Application Packages"
    release: "2.0"
    state: present
    vmm_server: scvmm.example.com

- name: Remove a custom resource from the library
  microsoft.scvmm.scvmm_custom_resource:
    name: OldPackage.cr
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
custom_resource:
  description: Details of the custom resource.
  returned: when state is present and custom resource exists
  type: dict
  contains:
    id:
      description: Custom resource ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Custom resource name.
      type: str
      returned: always
      sample: "MyApp.cr"
    description:
      description: Custom resource description.
      type: str
      returned: when available
      sample: "Application deployment package"
    share_path:
      description: Library share path where the custom resource is stored.
      type: str
      returned: always
      sample: "\\\\libserver01\\MSSCVMMLibrary\\CustomResources\\MyApp.cr"
    library_server:
      description: Name of the library server hosting this custom resource.
      type: str
      returned: always
      sample: "libserver01.contoso.com"
    family_name:
      description: Family name of the custom resource.
      type: str
      returned: when available
      sample: "Application Packages"
    release:
      description: Release identifier.
      type: str
      returned: when available
      sample: "2.0"
    owner:
      description: Owner of the custom resource.
      type: str
      returned: when available
      sample: "contoso\\administrator"
    enabled:
      description: Whether the custom resource is enabled.
      type: bool
      returned: always
      sample: true
    is_orphaned:
      description: Whether the custom resource is orphaned (missing from disk).
      type: bool
      returned: always
      sample: false
'''
