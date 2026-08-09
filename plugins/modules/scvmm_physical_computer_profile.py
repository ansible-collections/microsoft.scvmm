# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_physical_computer_profile
version_added: "1.1.0"
short_description: Manage physical computer profiles in System Center Virtual Machine Manager
description:
  - Create, update, or remove physical computer profiles in SCVMM.
  - Physical computer profiles define the configuration for bare metal deployments of
    Hyper-V hosts or file servers.
  - Profiles include OS disk, network adapter, domain/workgroup membership, and
    administrator credentials.
  - When creating a profile, a virtual hard disk and local administrator password
    are required.
options:
  name:
    description:
      - Name of the physical computer profile.
    type: str
    required: true
  new_name:
    description:
      - New name for the profile when renaming.
      - Only used when updating an existing profile.
    type: str
  description:
    description:
      - Description of the physical computer profile.
    type: str
  owner:
    description:
      - Owner of the physical computer profile.
      - This value is passed during creation but VMM may not honor it.
      - Returned as read-only in query results; cannot be updated.
    type: str
  virtual_hard_disk:
    description:
      - Name of the virtual hard disk to use as the OS boot disk.
      - Required when I(state=present) and creating a new profile.
      - Must be in VHD format. VHDX format is not supported and causes VMM Error 21552.
    type: str
  local_admin_password:
    description:
      - Password for the local administrator account on deployed servers.
      - Required when I(state=present) and creating a new profile.
    type: str
  domain:
    description:
      - Domain to join when deploying the server.
      - Mutually exclusive with I(join_workgroup).
      - Requires I(domain_join_run_as_account) when specified.
      - This is a create-only parameter and cannot be changed after profile creation.
    type: str
  domain_join_run_as_account:
    description:
      - Name of the RunAs account used to join the domain.
      - Required when I(domain) is specified.
    type: str
  join_workgroup:
    description:
      - Whether the deployed server should join a workgroup instead of a domain.
      - When C(true), the server joins the default WORKGROUP.
      - Mutually exclusive with I(domain).
      - This is a create-only parameter and cannot be changed after profile creation.
    type: bool
    default: false
  use_as_vm_host:
    description:
      - Whether the profile deploys the server as a Hyper-V host.
      - Mutually exclusive with I(use_as_file_server).
      - This is a create-only parameter and cannot be changed after profile creation.
    type: bool
    default: true
  use_as_file_server:
    description:
      - Whether the profile deploys the server as a file server.
      - Mutually exclusive with I(use_as_vm_host).
      - This is a create-only parameter and cannot be changed after profile creation.
    type: bool
    default: false
  full_name:
    description:
      - Full name for the OS setup.
    type: str
  organization_name:
    description:
      - Organization name for the OS setup.
    type: str
  time_zone:
    description:
      - Time zone index for the deployed server.
    type: int
  bypass_vhd_conversion:
    description:
      - Whether to bypass VHD conversion during deployment.
    type: bool
  is_guarded:
    description:
      - Whether the profile is for guarded host deployment.
    type: bool
  vm_paths:
    description:
      - Default path for VM storage on the deployed host.
    type: str
  driver_matching_tag:
    description:
      - List of driver matching tags for the profile.
      - This value is passed during creation but VMM may not persist it.
      - Returned as read-only in query results; cannot be updated.
    type: list
    elements: str
  state:
    description:
      - Desired state of the physical computer profile.
      - C(present) creates or updates a profile.
      - C(absent) removes a profile.
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
- name: Create a workgroup physical computer profile
  microsoft.scvmm.scvmm_physical_computer_profile:
    name: WorkgroupHost
    description: Profile for workgroup Hyper-V hosts
    virtual_hard_disk: "Blank Disk - Small.vhd"
    local_admin_password: "SecurePass123!"
    join_workgroup: true
    use_as_vm_host: true
    full_name: "Admin User"
    organization_name: "Contoso"
    state: present
    vmm_server: scvmm.example.com

- name: Create a domain-joined physical computer profile
  microsoft.scvmm.scvmm_physical_computer_profile:
    name: DomainHost
    description: Profile for domain-joined Hyper-V hosts
    virtual_hard_disk: "Blank Disk - Small.vhd"
    local_admin_password: "SecurePass123!"
    domain: contoso.local
    domain_join_run_as_account: "Domain Join Account"
    use_as_vm_host: true
    state: present
    vmm_server: scvmm.example.com

- name: Update a physical computer profile
  microsoft.scvmm.scvmm_physical_computer_profile:
    name: WorkgroupHost
    description: Updated description
    full_name: "New Admin"
    state: present
    vmm_server: scvmm.example.com

- name: Remove a physical computer profile
  microsoft.scvmm.scvmm_physical_computer_profile:
    name: WorkgroupHost
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
physical_computer_profile:
  description: Details of the physical computer profile.
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
      sample: "WorkgroupHost"
    description:
      description: Profile description.
      type: str
      returned: when available
      sample: "Profile for workgroup Hyper-V hosts"
    owner:
      description: Profile owner.
      type: str
      returned: when available
      sample: "contoso\\admin"
    full_name:
      description: Full name for OS setup.
      type: str
      returned: when available
    organization_name:
      description: Organization name for OS setup.
      type: str
      returned: when available
    join_domain:
      description: Domain the profile is configured to join.
      type: str
      returned: when available
    join_workgroup:
      description:
        - Workgroup name if configured for workgroup membership.
        - Returns the workgroup name string (e.g. C(WORKGROUP)), not a boolean.
      type: str
      returned: when available
      sample: "WORKGROUP"
    time_zone:
      description: Time zone index for the deployed server.
      type: int
      returned: when available
      sample: 35
    bypass_vhd_conversion:
      description: Whether VHD conversion is bypassed.
      type: bool
      returned: always
    is_guarded:
      description: Whether the profile is for guarded host deployment.
      type: bool
      returned: always
    vm_paths:
      description: Default VM storage path.
      type: str
      returned: when available
    enabled:
      description: Whether the profile is enabled.
      type: bool
      returned: always
    os_boot_vhd:
      description: Name of the OS boot virtual hard disk.
      type: str
      returned: when available
    driver_matching_tag:
      description: List of driver matching tags for the profile.
      type: list
      elements: str
      returned: always
'''
