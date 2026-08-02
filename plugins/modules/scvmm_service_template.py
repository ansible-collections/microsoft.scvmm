# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_service_template
version_added: "1.0.0"
short_description: Manage service templates in System Center Virtual Machine Manager
description:
  - Create, update, or remove service templates in SCVMM.
  - Service templates define the structure of multi-tier services including VM tiers,
    application hosts, and deployment settings.
  - Use C(release) to version service templates.
options:
  name:
    description:
      - Name of the service template.
    type: str
    required: true
  description:
    description:
      - Description of the service template.
    type: str
  release:
    description:
      - Release version string for the service template.
      - Required when creating a new service template.
      - When multiple releases exist with the same name, this parameter
        identifies the target release for update or delete operations.
    type: str
  service_priority:
    description:
      - Priority level for services deployed from this template.
    type: str
    choices: ['Normal', 'Low', 'High']
  use_as_default_release:
    description:
      - Whether this release should be the default release.
    type: bool
  owner:
    description:
      - Owner of the service template.
    type: str
  published:
    description:
      - Whether the service template is published.
      - Can only be set on update, not during creation.
    type: bool
  state:
    description:
      - Desired state of the service template.
      - C(present) creates or updates a service template.
      - C(absent) removes a service template.
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
- name: Create a service template
  microsoft.scvmm.scvmm_service_template:
    name: WebApp-Template
    description: Three-tier web application
    release: "1.0"
    service_priority: Normal
    state: present
    vmm_server: scvmm.example.com

- name: Update service template description
  microsoft.scvmm.scvmm_service_template:
    name: WebApp-Template
    description: Updated three-tier web application
    state: present
    vmm_server: scvmm.example.com

- name: Publish a service template
  microsoft.scvmm.scvmm_service_template:
    name: WebApp-Template
    published: true
    state: present
    vmm_server: scvmm.example.com

- name: Update a specific release when multiple exist
  microsoft.scvmm.scvmm_service_template:
    name: WebApp-Template
    release: "2.0"
    description: Updated release 2.0
    state: present
    vmm_server: scvmm.example.com

- name: Remove a service template
  microsoft.scvmm.scvmm_service_template:
    name: WebApp-Template
    release: "1.0"
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
service_template:
  description: Details of the service template.
  returned: when state is present and service template exists
  type: dict
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
