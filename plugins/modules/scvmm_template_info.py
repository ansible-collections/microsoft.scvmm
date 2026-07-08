# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_template_info
short_description: Query VM templates in System Center Virtual Machine Manager
description:
  - Retrieve information about VM templates in SCVMM.
  - Can query all templates or filter by name.
options:
  name:
    description:
      - Name of the template to query.
      - If not specified, returns all templates.
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
- name: Get all templates
  microsoft.scvmm.scvmm_template_info:
    vmm_server: scvmm.example.com
  register: all_templates

- name: Get a specific template
  microsoft.scvmm.scvmm_template_info:
    name: WebServer-Template
    vmm_server: scvmm.example.com
  register: template_info

- name: Display template details
  microsoft.scvmm.scvmm_template_info:
    name: WebServer-Template
  register: template_result
- debug:
    msg: "Template {{ item.name }} has {{ item.cpu_count }} CPUs and {{ item.memory_mb }}MB memory"
  loop: "{{ template_result.templates }}"
'''

RETURN = r'''
templates:
  description: List of VM templates.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: Template ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Template name.
      type: str
      returned: always
      sample: WebServer-Template
    description:
      description: Template description.
      type: str
      returned: when available
      sample: Standard web server template
    owner:
      description: Template owner.
      type: str
      returned: when available
      sample: "DOMAIN\\Admin"
    cpu_count:
      description: Number of CPUs.
      type: int
      returned: always
      sample: 2
    memory_mb:
      description: Memory in MB.
      type: int
      returned: always
      sample: 4096
    generation:
      description: VM generation.
      type: int
      returned: always
      sample: 2
    dynamic_memory:
      description: Whether dynamic memory is enabled.
      type: bool
      returned: always
      sample: false
    operating_system:
      description: Operating system name.
      type: str
      returned: when available
      sample: Windows Server 2022
    status:
      description: Template status.
      type: str
      returned: always
      sample: Normal
    creation_time:
      description: When the template was created in ISO 8601 format.
      type: str
      returned: when available
      sample: "2025-01-15T10:30:00.0000000Z"
    enabled:
      description: Whether the template is enabled.
      type: bool
      returned: always
      sample: true
'''
