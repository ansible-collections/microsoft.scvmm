# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_service_template_info
version_added: "1.0.0"
short_description: Get service template information from System Center Virtual Machine Manager
description:
  - Retrieves information about service templates in SCVMM.
  - Can return details of a specific service template or list all service templates.
options:
  name:
    description:
      - Name of the service template to retrieve.
      - If not specified, returns all service templates.
      - When a name has multiple releases, all releases are returned
        unless O(release) is also specified.
    type: str
  release:
    description:
      - Filter results to a specific release version.
      - Use with O(name) to select a single release when multiple exist.
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
- name: Get all service templates
  microsoft.scvmm.scvmm_service_template_info:
    vmm_server: scvmm.example.com
  register: all_templates

- name: Get all releases of a service template
  microsoft.scvmm.scvmm_service_template_info:
    name: WebApp-Template
    vmm_server: scvmm.example.com
  register: template_info

- name: Get a specific release of a service template
  microsoft.scvmm.scvmm_service_template_info:
    name: WebApp-Template
    release: "2.0"
    vmm_server: scvmm.example.com
  register: template_release
'''

RETURN = r'''
service_templates:
  description: List of service templates.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: Service template ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Service template name.
      type: str
      returned: always
      sample: WebApp-Template
    description:
      description: Service template description.
      type: str
      returned: always
      sample: Three-tier web application
    release:
      description: Release version of the service template.
      type: str
      returned: always
      sample: "1.0"
    service_priority:
      description: Priority level for deployed services.
      type: str
      returned: always
      sample: Normal
    use_as_default_release:
      description: Whether this is the default release.
      type: bool
      returned: always
      sample: false
    is_published:
      description: Whether the service template is published.
      type: bool
      returned: always
      sample: false
    owner:
      description: Owner of the service template.
      type: str
      returned: always
      sample: SCVMM\Administrator
    enabled:
      description: Whether the service template is enabled.
      type: bool
      returned: always
      sample: true
    creation_time:
      description: When the service template was created.
      type: str
      returned: always
      sample: "2026-01-15T10:30:00Z"
    modified_time:
      description: When the service template was last modified.
      type: str
      returned: always
      sample: "2026-01-15T10:30:00Z"
'''
