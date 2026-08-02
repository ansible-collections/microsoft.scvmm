# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_service_info
version_added: "1.0.0"
short_description: Get service information from System Center Virtual Machine Manager
description:
  - Retrieves information about services in SCVMM.
  - Can return details of a specific service or list all services.
options:
  name:
    description:
      - Name of the service to retrieve.
      - If not specified, returns all services.
    type: str
  cloud:
    description:
      - Filter services by cloud name.
      - Only returns services deployed in the specified cloud.
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
- name: Get all services
  microsoft.scvmm.scvmm_service_info:
    vmm_server: scvmm.example.com
  register: all_services

- name: Get a specific service
  microsoft.scvmm.scvmm_service_info:
    name: WebApp-Prod
    vmm_server: scvmm.example.com
  register: service_info

- name: Get a specific service in a specific cloud
  microsoft.scvmm.scvmm_service_info:
    name: WebApp-Prod
    cloud: Production-Cloud
    vmm_server: scvmm.example.com
  register: service_in_cloud

- name: Get all services in a specific cloud
  microsoft.scvmm.scvmm_service_info:
    cloud: Production-Cloud
    vmm_server: scvmm.example.com
  register: cloud_services
'''

RETURN = r'''
services:
  description: List of services.
  returned: always
  type: list
  elements: dict
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
