# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_inventory_info
version_added: "1.1.0"
short_description: Retrieve SCVMM managed infrastructure inventory
description:
  - Query virtual machines from SCVMM enriched with network adapter data
    including IP addresses, MAC addresses, and VM network associations.
  - Returns VM metadata and network details useful for building inventories
    or performing infrastructure audits.
  - Can filter by VM name, cloud, host group, or VM status.
  - Network adapter data is retrieved per VM; in large environments this
    adds one query per VM.
options:
  name:
    description:
      - Name of the virtual machine to query.
      - If not specified, returns all virtual machines.
    type: str
  cloud:
    description:
      - Filter virtual machines by SCVMM cloud name.
      - Only returns VMs deployed to the specified cloud.
    type: str
  host_group:
    description:
      - Filter virtual machines by host group name.
      - Only returns VMs running on hosts directly within the specified host group.
      - Does not include VMs on hosts in nested child host groups.
    type: str
  status:
    description:
      - Filter virtual machines by status.
    type: str
    choices:
      - Running
      - PowerOff
      - Stopped
      - Paused
      - MissingSharedStorage
      - IncompleteVMConfig
      - UnderCreation
      - CreationFailed
      - Stored
      - UnderTemplateCreation
      - TemplateCreationFailed
      - CustomizationFailed
      - UnderUpdate
      - UpdateFailed
      - UnderMigration
  vmm_server:
    description:
      - SCVMM server to connect to.
      - Defaults to localhost if not specified.
    type: str
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Get full SCVMM inventory
  microsoft.scvmm.scvmm_inventory_info:
    vmm_server: scvmm.example.com
  register: inventory

- name: Get inventory for a specific VM
  microsoft.scvmm.scvmm_inventory_info:
    name: WebServer01
    vmm_server: scvmm.example.com
  register: vm_inventory

- name: Get only running VMs
  microsoft.scvmm.scvmm_inventory_info:
    status: Running
    vmm_server: scvmm.example.com
  register: running_vms

- name: Get VMs in a specific cloud
  microsoft.scvmm.scvmm_inventory_info:
    cloud: Production
    vmm_server: scvmm.example.com
  register: prod_vms

- name: Get VMs in a specific host group
  microsoft.scvmm.scvmm_inventory_info:
    host_group: "All Hosts"
    vmm_server: scvmm.example.com
  register: host_group_vms

- name: Build a simple inventory from SCVMM
  microsoft.scvmm.scvmm_inventory_info:
    status: Running
    vmm_server: scvmm.example.com
  register: scvmm_inv

- name: Display VM connection info
  ansible.builtin.debug:
    msg: >-
      VM {{ item.name }} at {{ item.ipv4_addresses | default([]) | join(', ') }}
      on host {{ item.host_name }}
  loop: "{{ scvmm_inv.virtual_machines }}"
'''

RETURN = r'''
virtual_machines:
  description: List of virtual machines with enriched network adapter data.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: The unique identifier of the virtual machine.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: The name of the virtual machine.
      type: str
      returned: always
      sample: "WebServer01"
    status:
      description: The current status of the virtual machine.
      type: str
      returned: always
      sample: "Running"
    owner:
      description: The owner of the virtual machine.
      type: str
      returned: when available
      sample: "DOMAIN\\username"
    host_name:
      description: The FQDN of the Hyper-V host where the VM resides.
      type: str
      returned: when available
      sample: "hyperv01.example.com"
    host_group:
      description: The name of the host group the VM's host belongs to.
      type: str
      returned: when available
      sample: "All Hosts"
    cloud:
      description: The name of the cloud the VM belongs to.
      type: str
      returned: when available
      sample: "Production"
    cpu_count:
      description: The number of CPUs allocated to the virtual machine.
      type: int
      returned: always
      sample: 4
    memory_mb:
      description: The amount of memory allocated to the VM in megabytes.
      type: int
      returned: always
      sample: 8192
    operating_system:
      description: The operating system name of the virtual machine.
      type: str
      returned: when available
      sample: "Windows Server 2022 Datacenter"
    description:
      description: The description of the virtual machine.
      type: str
      returned: when available
      sample: "Production web server"
    creation_time:
      description: The creation time of the virtual machine in ISO 8601 format.
      type: str
      returned: when available
      sample: "2026-01-15T10:30:00.0000000Z"
    ipv4_addresses:
      description:
        - All IPv4 addresses across all network adapters on the VM.
        - Aggregated from all virtual network adapters for convenience.
      type: list
      elements: str
      returned: always
      sample: ["10.0.0.5", "192.168.1.100"]
    network_adapters:
      description: List of virtual network adapters attached to the VM.
      type: list
      elements: dict
      returned: always
      contains:
        name:
          description: The name of the network adapter.
          type: str
          returned: always
          sample: "Network Adapter"
        vm_network:
          description: The VM network the adapter is connected to.
          type: str
          returned: when available
          sample: "VM-Network"
        mac_address:
          description: The MAC address of the adapter.
          type: str
          returned: when available
          sample: "00:1D:D8:B7:1C:00"
        ipv4_addresses:
          description: IPv4 addresses assigned to this adapter.
          type: list
          elements: str
          returned: always
          sample: ["10.0.0.5"]
'''
