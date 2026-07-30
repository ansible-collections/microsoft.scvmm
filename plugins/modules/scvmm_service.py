# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_service
version_added: "1.0.0"
short_description: Manage services in System Center Virtual Machine Manager
description:
  - Create, update, or remove services in SCVMM.
  - Services are deployed instances of service templates that represent multi-tier applications.
  - Creation requires a service template and a cloud to deploy into.
options:
  name:
    description:
      - Name of the service.
    type: str
    required: true
  service_template:
    description:
      - Name of the service template to deploy from.
      - Required when creating a new service.
      - This is a create-only parameter and is ignored when updating an existing service.
    type: str
  cloud:
    description:
      - Name of the cloud to deploy the service into.
      - Required when creating a new service.
      - When multiple services share the same name across different clouds,
        this parameter identifies the target service for update or delete operations.
    type: str
  description:
    description:
      - Description of the service.
    type: str
  service_priority:
    description:
      - Priority level for the service.
    type: str
    choices: ['Normal', 'Low', 'High']
  cost_center:
    description:
      - Cost center for the service.
    type: str
  owner:
    description:
      - Owner of the service.
    type: str
  state:
    description:
      - Desired state of the service.
      - C(present) creates or updates a service.
      - C(absent) removes a service.
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
- name: Create a service from a template
  microsoft.scvmm.scvmm_service:
    name: WebApp-Prod
    service_template: WebApp-Template
    cloud: Production-Cloud
    description: Production web application
    service_priority: High
    state: present
    vmm_server: scvmm.example.com

- name: Update service description
  microsoft.scvmm.scvmm_service:
    name: WebApp-Prod
    description: Updated production web application
    state: present
    vmm_server: scvmm.example.com

- name: Update a service in a specific cloud when names overlap
  microsoft.scvmm.scvmm_service:
    name: WebApp-Prod
    cloud: Production-Cloud
    description: Updated via cloud disambiguation
    state: present
    vmm_server: scvmm.example.com

- name: Remove a service
  microsoft.scvmm.scvmm_service:
    name: WebApp-Prod
    cloud: Production-Cloud
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
service:
  description: Details of the service.
  returned: when state is present and service exists
  type: dict
  contains:
    id:
      description: Service ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Service name.
      type: str
      returned: always
      sample: WebApp-Prod
    description:
      description: Service description.
      type: str
      returned: always
      sample: Production web application
    service_priority:
      description: Priority level of the service.
      type: str
      returned: always
      sample: Normal
    cost_center:
      description: Cost center for the service.
      type: str
      returned: always
      sample: IT-Ops
    owner:
      description: Owner of the service.
      type: str
      returned: always
      sample: SCVMM\Administrator
    cloud_name:
      description: Name of the cloud the service is deployed in.
      type: str
      returned: always
      sample: Production-Cloud
    service_template_name:
      description: Name of the service template used.
      type: str
      returned: always
      sample: WebApp-Template
    service_template_release:
      description: Release version of the service template.
      type: str
      returned: always
      sample: "1.0"
    deployment_state:
      description: Current deployment state of the service.
      type: str
      returned: always
      sample: Deployed
    enabled:
      description: Whether the service is enabled.
      type: bool
      returned: always
      sample: true
    creation_time:
      description: When the service was created.
      type: str
      returned: always
      sample: "2026-01-15T09:00:00Z"
    modified_time:
      description: When the service was last modified.
      type: str
      returned: always
      sample: "2026-01-15T10:30:00Z"
'''
