# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_host_rating_info
short_description: Query host placement ratings in System Center Virtual Machine Manager
description:
  - Retrieve host placement ratings for a virtual machine in SCVMM.
  - Rates hosts for optimal VM placement based on resource availability.
  - Requires a VM name to evaluate which hosts can best accommodate the VM.
  - Ratings are based on the VMM database and do not perform live migration compatibility checks.
options:
  vm_name:
    description:
      - Name of the virtual machine to evaluate host placement for.
    type: str
    required: true
  host_group:
    description:
      - Name of the host group to evaluate hosts within.
      - Defaults to All Hosts if not specified.
    type: str
    default: All Hosts
  vmm_server:
    description:
      - SCVMM server to connect to.
      - Defaults to localhost if not specified.
    type: str
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Get host ratings for a VM
  microsoft.scvmm.scvmm_host_rating_info:
    vm_name: my-vm
    vmm_server: scvmm.example.com
  register: ratings

- name: Get host ratings within a specific host group
  microsoft.scvmm.scvmm_host_rating_info:
    vm_name: my-vm
    host_group: Production Hosts
    vmm_server: scvmm.example.com
  register: ratings

- name: Display highest rated host
  ansible.builtin.debug:
    msg: "Best host: {{ ratings.host_ratings[0].host_name }} (rating: {{ ratings.host_ratings[0].rating }})"
  when: ratings.host_ratings | length > 0
'''

RETURN = r'''
host_ratings:
  description: List of host placement ratings sorted by rating descending.
  returned: always
  type: list
  elements: dict
  contains:
    host_name:
      description: Fully qualified domain name of the rated host.
      type: str
      returned: always
      sample: "host01.example.com"
    rating:
      description: Numeric placement rating for the host.
      type: int
      returned: always
      sample: 5
    description:
      description: Placement description or explanation.
      type: str
      returned: always
      sample: "Host has sufficient resources for placement"
    transfer_type:
      description: Type of transfer for VM placement.
      type: str
      returned: always
      sample: "Network"
    zero_rating_reasons:
      description: List of reasons why the host received a zero rating.
      type: list
      elements: str
      returned: always
      sample: ["Host is not responding"]
    warnings:
      description: List of warnings about placement on this host.
      type: list
      elements: str
      returned: always
      sample: []
    estimated_disk_remaining_mb:
      description: Estimated disk space remaining on the host in MB after placement.
      type: int
      returned: always
      sample: 102400
    estimated_memory_remaining_mb:
      description: Estimated memory remaining on the host in MB after placement.
      type: int
      returned: always
      sample: 4096
'''
