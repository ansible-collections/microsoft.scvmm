# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_custom_resource_info
version_added: "1.1.0"
short_description: Query custom resources in the SCVMM library
description:
  - Retrieve information about custom resources in the SCVMM library.
  - Can query all custom resources or filter by name.
options:
  name:
    description:
      - Name of the custom resource to query.
      - If not specified, returns all custom resources.
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
- name: Get all custom resources
  microsoft.scvmm.scvmm_custom_resource_info:
    vmm_server: scvmm.example.com
  register: all_resources

- name: Get a specific custom resource by name
  microsoft.scvmm.scvmm_custom_resource_info:
    name: MyApp.cr
    vmm_server: scvmm.example.com
  register: resource_info

- name: Display custom resource details
  ansible.builtin.debug:
    msg: "Resource {{ item.name }} at {{ item.share_path }}"
  loop: "{{ all_resources.custom_resources }}"
'''

RETURN = r'''
custom_resources:
  description: List of custom resources.
  returned: always
  type: list
  elements: dict
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
