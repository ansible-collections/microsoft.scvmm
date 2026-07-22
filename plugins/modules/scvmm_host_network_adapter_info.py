# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_host_network_adapter_info
short_description: Query host network adapter information in System Center Virtual Machine Manager
description:
  - Retrieve information about network adapters on Hyper-V hosts managed by SCVMM.
  - Can query adapters for a specific host or all hosts.
options:
  vm_host:
    description:
      - Computer name or FQDN of the host to query adapters for.
      - If not specified, returns adapters for all hosts.
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
- name: Get all network adapters for a host
  microsoft.scvmm.scvmm_host_network_adapter_info:
    vm_host: hyperv01.example.com
    vmm_server: scvmm.example.com
  register: adapter_info

- name: Display adapter details
  ansible.builtin.debug:
    msg: "Adapter {{ item.name }}: {{ item.connection_name }} ({{ item.mac_address }})"
  loop: "{{ adapter_info.network_adapters }}"
'''

RETURN = r'''
network_adapters:
  description: List of host network adapters.
  returned: always
  type: list
  elements: dict
  contains:
    id:
      description: Adapter ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Adapter name.
      type: str
      returned: always
      sample: "Intel(R) Ethernet Connection I217-LM"
    connection_name:
      description: Network connection name.
      type: str
      returned: when available
      sample: Ethernet0
    mac_address:
      description: MAC address of the adapter.
      type: str
      returned: always
      sample: "00:15:5D:01:02:03"
    ip_addresses:
      description: IP addresses assigned to the adapter.
      type: list
      elements: str
      returned: always
      sample: ["10.0.1.5"]
    max_bandwidth_mbps:
      description: Maximum bandwidth in Mbps.
      type: int
      returned: when available
      sample: 10000
    logical_networks:
      description: List of associated logical network names.
      type: list
      elements: str
      returned: always
      sample: ["Management"]
    vm_host:
      description: Name of the host this adapter belongs to.
      type: str
      returned: always
      sample: hyperv01.example.com
'''
