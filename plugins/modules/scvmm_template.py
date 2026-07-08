# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_template
short_description: Manage VM templates in System Center Virtual Machine Manager
description:
  - Create, update, and remove VM templates in SCVMM.
  - Templates can be created from an existing VM, cloned from another template, or created as a blank template.
  - Creating a template from a VM destroys the source VM.
  - Supports check mode for safe testing.
options:
  name:
    description:
      - Name for the VM template.
    type: str
    required: true
  source_vm:
    description:
      - Name of an existing VM to create the template from.
      - The source VM is destroyed during template creation.
      - Mutually exclusive with O(source_template).
    type: str
  source_template:
    description:
      - Name of an existing template to clone from.
      - Mutually exclusive with O(source_vm).
    type: str
  description:
    description:
      - Description for the template.
    type: str
  owner:
    description:
      - Owner of the template in DOMAIN\\User format.
    type: str
  cpu_count:
    description:
      - Number of CPUs for the template.
    type: int
  memory_mb:
    description:
      - Amount of memory in MB for the template.
    type: int
  dynamic_memory:
    description:
      - Whether dynamic memory is enabled.
      - When not specified, dynamic memory settings are not modified.
    type: bool
  generation:
    description:
      - Virtual machine generation for the template.
      - Only used during template creation, cannot be changed on existing templates.
    type: int
    choices: [ 1, 2 ]
  vmm_server:
    description:
      - SCVMM server to connect to.
      - Defaults to localhost if not specified.
    type: str
  state:
    description:
      - Desired state of the template.
      - C(present) ensures the template exists.
      - C(absent) ensures the template is removed.
    type: str
    choices: [ present, absent ]
    default: present
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Create a template from a VM
  microsoft.scvmm.scvmm_template:
    name: WebServer-Template
    source_vm: WebServer-Golden
    description: Standard web server template
    vmm_server: scvmm.example.com
    state: present

- name: Create a blank template
  microsoft.scvmm.scvmm_template:
    name: Blank-Gen2-Template
    generation: 2
    cpu_count: 2
    memory_mb: 4096
    state: present

- name: Update template description
  microsoft.scvmm.scvmm_template:
    name: WebServer-Template
    description: Updated web server template
    state: present

- name: Remove a template
  microsoft.scvmm.scvmm_template:
    name: OldTemplate
    state: absent
'''

RETURN = r'''
template:
  description: Details of the VM template.
  returned: when state is present and template exists
  type: dict
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
'''
