#!/usr/bin/python

# Copyright: (c) 2026, Microsoft Corporation
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

DOCUMENTATION = r'''
---
module: scvmm_vm_migrate
short_description: Live migrate a VM between Hyper-V hosts in SCVMM
description:
  - Live migrates a virtual machine from its current Hyper-V host to a specified destination host.
  - Uses System Center Virtual Machine Manager (SCVMM) to orchestrate the migration.
  - Supports optional storage path specification for the migrated VM.
options:
  name:
    description:
      - The name of the virtual machine to migrate.
    type: str
    required: true
  destination_host:
    description:
      - The fully qualified domain name (FQDN) of the target Hyper-V host.
      - The VM will be migrated to this host.
    type: str
    required: true
  vmm_server:
    description:
      - The SCVMM server to connect to.
      - If not specified, uses the default SCVMM server configuration.
    type: str
    required: false
  path:
    description:
      - The destination storage path on the target host for the VM files.
      - If not specified, SCVMM will use the default path on the destination host.
    type: str
    required: false
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
requirements:
  - System Center Virtual Machine Manager PowerShell module
  - Windows PowerShell 5.1 or later
'''

EXAMPLES = r'''
- name: Migrate VM to a specific host
  microsoft.scvmm.scvmm_vm_migrate:
    name: WebServer01
    destination_host: hyperv-host02.contoso.com

- name: Migrate VM to a specific host with custom storage path
  microsoft.scvmm.scvmm_vm_migrate:
    name: WebServer01
    destination_host: hyperv-host02.contoso.com
    path: 'D:\VirtualMachines'

- name: Migrate VM using a specific SCVMM server
  microsoft.scvmm.scvmm_vm_migrate:
    name: DatabaseServer01
    destination_host: hyperv-host03.contoso.com
    vmm_server: scvmm01.contoso.com
    path: 'E:\VMs\Production'
'''

RETURN = r'''
source_host:
  description: The original Hyper-V host where the VM was located.
  returned: always
  type: str
  sample: hyperv-host01.contoso.com
destination_host:
  description: The target Hyper-V host where the VM was migrated.
  returned: always
  type: str
  sample: hyperv-host02.contoso.com
'''
