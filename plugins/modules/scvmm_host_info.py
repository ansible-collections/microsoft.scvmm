# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_host_info
short_description: Query Hyper-V host information in System Center Virtual Machine Manager
description:
  - Retrieve information about Hyper-V hosts managed by SCVMM.
  - Can query all hosts or filter by name or host group.
options:
  name:
    description:
      - Computer name or FQDN of the host to query.
      - If not specified, returns all hosts.
    type: str
  host_group:
    description:
      - Name of the host group to filter hosts by.
      - Returns only hosts belonging to this host group.
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
- name: Get all Hyper-V hosts
  microsoft.scvmm.scvmm_host_info:
    vmm_server: scvmm.example.com
  register: all_hosts

- name: Get a specific host by name
  microsoft.scvmm.scvmm_host_info:
    name: hyperv01.example.com
    vmm_server: scvmm.example.com
  register: host_info

- name: Get hosts in a specific host group
  microsoft.scvmm.scvmm_host_info:
    host_group: Production
    vmm_server: scvmm.example.com
  register: prod_hosts

- name: Display host details
  ansible.builtin.debug:
    msg: "Host {{ item.name }} has {{ item.cpu_count }} CPUs and {{ item.total_memory_gb }} GB RAM"
  loop: "{{ all_hosts.hosts }}"
'''

RETURN = r'''
hosts:
  description: List of Hyper-V hosts.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: Host ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Computer name of the host.
      type: str
      returned: always
      sample: hyperv01.example.com
    host_group:
      description: Name of the host group this host belongs to.
      type: str
      returned: always
      sample: Production
    status:
      description: Overall state of the host.
      type: str
      returned: always
      sample: Responding
    cpu_count:
      description: Number of logical CPUs on the host.
      type: int
      returned: always
      sample: 8
    total_memory_gb:
      description: Total memory in GB.
      type: float
      returned: always
      sample: 64.0
    available_memory_gb:
      description: Available memory in GB.
      type: float
      returned: always
      sample: 32.5
    vm_count:
      description: Number of virtual machines on this host.
      type: int
      returned: always
      sample: 12
    os_version:
      description: Operating system of the host.
      type: str
      returned: when available
      sample: "Windows Server 2022 Datacenter"
    cluster_name:
      description: Name of the host cluster, if the host is part of one.
      type: str
      returned: when available
      sample: HyperV-Cluster01
'''
