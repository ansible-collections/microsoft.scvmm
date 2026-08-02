# Microsoft SCVMM Collection for Ansible

[![CI](https://github.com/ansible-collections/microsoft.scvmm/actions/workflows/ansible-test.yml/badge.svg?event=push)](https://github.com/ansible-collections/microsoft.scvmm/actions/workflows/ansible-test.yml) [![Codecov](https://img.shields.io/codecov/c/github/ansible-collections/microsoft.scvmm)](https://codecov.io/gh/ansible-collections/microsoft.scvmm)

This collection provides comprehensive automation capabilities for Microsoft System Center Virtual Machine Manager (SCVMM) 2022 environments. It enables users to manage virtual machines, networking, storage, clouds, templates, profiles, and services through Ansible playbooks.

## Our mission

At the **Microsoft SCVMM Collection**, our mission is to produce and maintain simple, flexible,
and powerful open-source software tailored to automating and managing Microsoft SCVMM virtualization infrastructure.

We welcome members from all skill levels to participate actively in our open, inclusive, and vibrant community.
Whether you are an expert or just beginning your journey with Ansible and SCVMM automation,
you are encouraged to contribute, share insights, and collaborate with fellow enthusiasts!

## Code of Conduct

We follow the [Ansible Code of Conduct](https://docs.ansible.com/projects/ansible/devel/community/code_of_conduct.html) in all our interactions within this project.

If you encounter abusive behavior, please refer to the [policy violations](https://docs.ansible.com/projects/ansible/devel/community/code_of_conduct.html#policy-violations) section of the Code for information on how to raise a complaint.

## Communication

* Join the Ansible forum:
  * [Get Help](https://forum.ansible.com/c/help/6): get help or help others. Please add the `scvmm` tag if you start new discussions.
  * [Posts tagged with 'scvmm'](https://forum.ansible.com/tag/scvmm): subscribe to participate in SCVMM-related conversations.
  * [Social Spaces](https://forum.ansible.com/c/chat/4): gather and interact with fellow enthusiasts.
  * [News & Announcements](https://forum.ansible.com/c/news/5): track project-wide announcements including social events. The [Bullhorn newsletter](https://docs.ansible.com/projects/ansible/devel/community/communication.html#the-bullhorn), which is used to announce releases and important changes, can also be found here.

For more information about communication, see the [Ansible communication guide](https://docs.ansible.com/projects/ansible/devel/community/communication.html).

## Contributing to this collection

The content of this collection is made by people like you, a community of individuals collaborating on making the world better through developing automation software.

We are actively accepting new contributors and all types of contributions are very welcome.

Don't know how to start? Refer to the [Ansible community guide](https://docs.ansible.com/projects/ansible/devel/community/index.html)!

Want to submit code changes? Take a look at the [Quick-start development guide](https://docs.ansible.com/projects/ansible/devel/community/create_pr_quick_start.html).

We also use the following guidelines:

* [Collection review checklist](https://docs.ansible.com/projects/ansible/devel/community/collection_contributors/collection_reviewing.html)
* [Ansible development guide](https://docs.ansible.com/projects/ansible/devel/dev_guide/index.html)
* [Ansible collection development guide](https://docs.ansible.com/projects/ansible/devel/dev_guide/developing_collections.html#contributing-to-collections)

## Collection maintenance

The current maintainers are listed in the [MAINTAINERS](https://github.com/ansible-collections/microsoft.scvmm/blob/main/MAINTAINERS) file. If you have questions or need help, feel free to mention them in the proposals.

To learn how to maintain/become a maintainer of this collection, refer to the [Maintainer guidelines](https://docs.ansible.com/projects/ansible/devel/community/maintainers.html).

It is necessary for maintainers of this collection to be subscribed to:

* The collection itself (the `Watch` button -> `All Activity` in the upper right corner of the repository's homepage).
* The [news-for-maintainers repository](https://github.com/ansible-collections/news-for-maintainers).

They also should be subscribed to Ansible's [The Bullhorn newsletter](https://docs.ansible.com/projects/ansible/devel/community/communication.html#the-bullhorn).

## Governance

The process of decision making in this collection is based on discussing and finding consensus among participants.

Every voice is important. If you have something on your mind, create an issue or dedicated discussion and let's discuss it!

## Tested with Ansible

This collection is tested with the most current Ansible releases.

## External requirements

### Platform Requirements
- **Operating System**: Windows Server 2016 or later with SCVMM 2022 Management Server installed
- **PowerShell**: PowerShell 5.1 or later
- **SCVMM**: System Center Virtual Machine Manager 2022 with the VirtualMachineManager PowerShell module

### Dependencies
- `ansible.windows` collection >= 2.0.0

### Supported connections
This collection uses the `winrm` or `psrp` connection plugins to communicate with Windows hosts running SCVMM.

## Available Modules

### Virtual Machine Management
- `scvmm_vm` - Create, update, or delete virtual machines
- `scvmm_vm_info` - Retrieve information about virtual machines
- `scvmm_vm_state` - Manage VM power state (start/stop/suspend/resume)
- `scvmm_vm_checkpoint` - Manage VM checkpoints (snapshots)
- `scvmm_vm_checkpoint_info` - Retrieve checkpoint information
- `scvmm_vm_clone` - Clone existing virtual machines
- `scvmm_vm_migrate` - Live migrate VMs between Hyper-V hosts

### VM Hardware Configuration
- `scvmm_vm_disk` - Manage virtual disk drives
- `scvmm_vm_disk_info` - Query virtual disk drives
- `scvmm_vm_dvd_drive` - Manage virtual DVD drives
- `scvmm_vm_dvd_drive_info` - Retrieve DVD drive information
- `scvmm_vm_scsi_adapter` - Manage virtual SCSI adapters
- `scvmm_vm_scsi_adapter_info` - Retrieve SCSI adapter information
- `scvmm_vm_nic` - Configure virtual network adapter settings
- `scvmm_network_adapter` - Manage virtual network adapters
- `scvmm_network_adapter_info` - Query virtual network adapters

### Cloud Management
- `scvmm_cloud` - Manage private clouds
- `scvmm_cloud_info` - Query private cloud information
- `scvmm_cloud_capacity` - Manage cloud capacity limits
- `scvmm_cloud_capacity_info` - Query cloud capacity information

### Networking
- `scvmm_logical_network` - Manage logical networks
- `scvmm_logical_network_info` - Query logical networks
- `scvmm_logical_network_definition` - Manage logical network definitions (network sites)
- `scvmm_logical_network_definition_info` - Query logical network definitions
- `scvmm_logical_switch` - Manage logical switches
- `scvmm_logical_switch_info` - Query logical switches
- `scvmm_vm_network` - Manage VM networks
- `scvmm_vm_network_info` - Query VM networks
- `scvmm_vm_subnet` - Manage VM subnets
- `scvmm_vm_subnet_info` - Query VM subnets
- `scvmm_ip_pool` - Manage static IP address pools
- `scvmm_ip_pool_info` - Query static IP address pools
- `scvmm_mac_address_pool` - Manage MAC address pools
- `scvmm_mac_address_pool_info` - Query MAC address pools
- `scvmm_port_classification` - Manage port classifications
- `scvmm_port_classification_info` - Query port classifications
- `scvmm_uplink_port_profile` - Manage native uplink port profiles
- `scvmm_uplink_port_profile_info` - Query native uplink port profiles
- `scvmm_load_balancer` - Manage load balancers
- `scvmm_load_balancer_info` - Query load balancers

### Host Management
- `scvmm_host` - Manage Hyper-V hosts
- `scvmm_host_info` - Query Hyper-V host information
- `scvmm_host_group` - Manage host groups
- `scvmm_host_group_info` - Query host groups
- `scvmm_host_cluster` - Manage Hyper-V failover clusters
- `scvmm_host_cluster_info` - Query host cluster information
- `scvmm_host_network_adapter` - Manage host network adapter configuration
- `scvmm_host_network_adapter_info` - Query host network adapter information
- `scvmm_host_rating_info` - Query host placement ratings

### Storage
- `scvmm_storage_classification` - Manage storage classifications
- `scvmm_storage_classification_info` - Query storage classifications
- `scvmm_storage_pool` - Manage storage pools
- `scvmm_storage_pool_info` - Query storage pools
- `scvmm_storage_provider` - Manage storage providers
- `scvmm_storage_provider_info` - Query storage providers
- `scvmm_storage_file_share_info` - Query storage file shares
- `scvmm_virtual_hard_disk` - Manage virtual hard disks
- `scvmm_virtual_hard_disk_info` - Query virtual hard disks

### Templates and Profiles
- `scvmm_template` - Manage VM templates
- `scvmm_template_info` - Query VM templates
- `scvmm_hardware_profile` - Manage hardware profiles
- `scvmm_hardware_profile_info` - Query hardware profiles
- `scvmm_guest_os_profile` - Manage guest OS profiles
- `scvmm_guest_os_profile_info` - Query guest OS profiles
- `scvmm_application_profile` - Manage application profiles
- `scvmm_application_profile_info` - Query application profiles
- `scvmm_capability_profile` - Manage capability profiles
- `scvmm_capability_profile_info` - Query capability profiles

### Services
- `scvmm_service` - Manage services (multi-tier applications)
- `scvmm_service_info` - Query service information

### Access Control
- `scvmm_run_as_account` - Manage Run As accounts
- `scvmm_run_as_account_info` - Query Run As accounts
- `scvmm_user_role` - Manage user roles
- `scvmm_user_role_info` - Query user roles
- `scvmm_user_role_quota` - Manage user role quotas
- `scvmm_user_role_quota_info` - Query user role quotas

## Support

As Red Hat Ansible Certified Content, this collection is entitled to support through the Ansible Automation Platform (AAP).

*   **Certified Support:** If you have an active Red Hat subscription, you can open a support case via the [Red Hat Customer Portal](https://access.redhat.com/support/cases/#/case/combine) or by using the **Create issue** button on the top right corner of the collection page in Automation Hub.
*   **Community Support:** If this collection was obtained via Ansible Galaxy or GitHub and a Red Hat support case cannot be opened, community assistance is available on the [Ansible Forum](https://forum.ansible.com/).
*   **Supported Versions:** Support is provided for the current major version and the previous major version of this collection.

## Using this collection

### Installing the Collection from Ansible Galaxy

Before using this collection, you need to install it with the Ansible Galaxy command-line tool:
```bash
ansible-galaxy collection install microsoft.scvmm
```

You can also include it in a `requirements.yml` file and install it with `ansible-galaxy collection install -r requirements.yml`, using the format:
```yaml
---
collections:
  - name: microsoft.scvmm
```

Note that if you install the collection from Ansible Galaxy, it will not be upgraded automatically when you upgrade the `ansible` package. To upgrade the collection to the latest available version, run the following command:
```bash
ansible-galaxy collection install microsoft.scvmm --upgrade
```

You can also install a specific version of the collection, for example, if you need to downgrade when something is broken in the latest version (please report an issue in this repository). Use the following syntax to install version `1.0.0`:

```bash
ansible-galaxy collection install microsoft.scvmm:==1.0.0
```

See [using Ansible collections](https://docs.ansible.com/projects/ansible/devel/user_guide/collections_using.html) for more details.

### Example Playbook

Here's a simple example of using this collection to manage SCVMM resources:

```yaml
---
- name: Manage SCVMM Virtual Machines
  hosts: scvmm_server
  gather_facts: false

  tasks:
    - name: Get all VMs
      microsoft.scvmm.scvmm_vm_info:
        vmm_server: "{{ scvmm_server }}"
      register: vms

    - name: Create a VM from template
      microsoft.scvmm.scvmm_vm:
        name: my-new-vm
        template: BlankVM-Gen2
        vm_host: my-hyperv-host.domain.local
        vmm_server: "{{ scvmm_server }}"
        state: present

    - name: Start the VM
      microsoft.scvmm.scvmm_vm_state:
        name: my-new-vm
        state: running
        vmm_server: "{{ scvmm_server }}"
```

## Release notes

See the [changelog](https://github.com/ansible-collections/microsoft.scvmm/blob/main/CHANGELOG.rst).

## More information

### Collection Documentation
- [Changelog](https://github.com/ansible-collections/microsoft.scvmm/blob/main/CHANGELOG.rst) - Release notes and version history

### Microsoft SCVMM Resources
- [System Center Virtual Machine Manager Documentation](https://learn.microsoft.com/en-us/system-center/vmm/)
- [SCVMM PowerShell Reference](https://learn.microsoft.com/en-us/powershell/module/virtualmachinemanager/)

### Ansible Resources
- [Ansible user guide](https://docs.ansible.com/projects/ansible/devel/user_guide/index.html)
- [Ansible developer guide](https://docs.ansible.com/projects/ansible/devel/dev_guide/index.html)
- [Ansible collections requirements](https://docs.ansible.com/projects/ansible/devel/community/collection_contributors/collection_requirements.html)
- [Ansible community Code of Conduct](https://docs.ansible.com/projects/ansible/devel/community/code_of_conduct.html)
- [The Bullhorn (the Ansible contributor newsletter)](https://docs.ansible.com/projects/ansible/devel/community/communication.html#the-bullhorn)
- [Important announcements for maintainers](https://github.com/ansible-collections/news-for-maintainers)

## Licensing

GNU General Public License v3.0 or later.

See [LICENSE](https://www.gnu.org/licenses/gpl-3.0.txt) to see the full text.
