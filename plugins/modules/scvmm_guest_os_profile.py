# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_guest_os_profile
short_description: Manage guest OS profiles in System Center Virtual Machine Manager
description:
  - Create, update, and remove guest OS profiles in SCVMM.
  - Guest OS profiles define OS customization settings applied during VM deployment.
  - Supports check mode for safe testing.
options:
  name:
    description:
      - Name for the guest OS profile.
    type: str
    required: true
  description:
    description:
      - Description for the guest OS profile.
    type: str
  owner:
    description:
      - Owner of the profile in DOMAIN\\User format.
    type: str
  computer_name:
    description:
      - Computer name to assign to VMs deployed with this profile.
    type: str
  full_name:
    description:
      - Full name of the registered user.
    type: str
  organization_name:
    description:
      - Organization name for the registered user.
    type: str
  time_zone:
    description:
      - Time zone index number.
      - For example, 35 is Eastern Standard Time.
    type: int
  domain:
    description:
      - Domain to join the VM to.
      - Mutually exclusive with O(workgroup).
    type: str
  domain_join_organizational_unit:
    description:
      - Organizational unit (OU) for domain join.
    type: str
  workgroup:
    description:
      - Workgroup to join.
      - Mutually exclusive with O(domain).
    type: str
  operating_system:
    description:
      - Name of the operating system.
      - Required when creating a new profile.
      - Must match an OS name known to SCVMM.
    type: str
  auto_logon_count:
    description:
      - Number of times to auto-logon after deployment.
    type: int
  shielded:
    description:
      - Whether the profile is shielded.
    type: bool
  linux_domain_name:
    description:
      - DNS domain name for Linux VMs.
    type: str
  gui_run_once_commands:
    description:
      - List of commands to run once at first logon.
    type: list
    elements: str
  vmm_server:
    description:
      - SCVMM server to connect to.
      - Defaults to localhost if not specified.
    type: str
  state:
    description:
      - Desired state of the guest OS profile.
      - C(present) ensures the profile exists.
      - C(absent) ensures the profile is removed.
    type: str
    choices: [ present, absent ]
    default: present
author:
  - Ansible Ecosystem Engineering team (@eco-ansible-content)
'''

EXAMPLES = r'''
- name: Create a guest OS profile
  microsoft.scvmm.scvmm_guest_os_profile:
    name: Win2022-Profile
    operating_system: "Windows Server 2022 Datacenter"
    computer_name: WebServer
    full_name: Admin User
    organization_name: Contoso
    time_zone: 35
    description: Windows Server 2022 guest OS profile
    vmm_server: scvmm.example.com
    state: present

- name: Create a domain-joined profile
  microsoft.scvmm.scvmm_guest_os_profile:
    name: DomainJoin-Profile
    operating_system: "Windows Server 2022 Datacenter"
    computer_name: DC-Server
    domain: contoso.local
    domain_join_organizational_unit: "OU=Servers,DC=contoso,DC=local"
    state: present

- name: Update profile description
  microsoft.scvmm.scvmm_guest_os_profile:
    name: Win2022-Profile
    description: Updated description
    state: present

- name: Remove a guest OS profile
  microsoft.scvmm.scvmm_guest_os_profile:
    name: Win2022-Profile
    state: absent
'''

RETURN = r'''
guest_os_profile:
  description: Details of the guest OS profile.
  returned: when state is present and profile exists
  type: dict
  contains:
    id:
      description: Profile ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Profile name.
      type: str
      returned: always
      sample: Win2022-Profile
    description:
      description: Profile description.
      type: str
      returned: when available
    owner:
      description: Profile owner.
      type: str
      returned: when available
      sample: "DOMAIN\\Admin"
    computer_name:
      description: Computer name assigned to VMs.
      type: str
      returned: when available
      sample: WebServer
    full_name:
      description: Registered user full name.
      type: str
      returned: when available
      sample: Admin User
    organization_name:
      description: Registered organization name.
      type: str
      returned: when available
      sample: Contoso
    time_zone:
      description: Time zone index.
      type: int
      returned: when available
      sample: 35
    domain:
      description: Domain the VM will join.
      type: str
      returned: when available
      sample: contoso.local
    domain_join_organizational_unit:
      description: OU for domain join.
      type: str
      returned: when available
    workgroup:
      description: Workgroup name.
      type: str
      returned: when available
      sample: WORKGROUP
    operating_system:
      description: Operating system name.
      type: str
      returned: always
      sample: "Windows Server 2022 Datacenter"
    auto_logon_count:
      description: Auto-logon count.
      type: int
      returned: when available
    shielded:
      description: Whether the profile is shielded.
      type: bool
      returned: always
      sample: false
    linux_domain_name:
      description: DNS domain name for Linux VMs.
      type: str
      returned: when available
    gui_run_once_commands:
      description: Commands to run at first logon.
      type: list
      elements: str
      returned: always
    creation_time:
      description: When the profile was created.
      type: str
      returned: always
'''
