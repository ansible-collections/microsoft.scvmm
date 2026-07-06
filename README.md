# Microsoft SCVMM Collection for Ansible

This collection provides modules for managing System Center Virtual Machine Manager (SCVMM) 2022 resources using Ansible.

## Requirements

- Ansible >= 2.15.0
- `ansible.windows` collection >= 2.0.0
- SCVMM 2022 Management Server with VirtualMachineManager PowerShell module
- WinRM connectivity to the SCVMM Management Server

## Installation

```bash
ansible-galaxy collection install microsoft.scvmm
```

## Usage

All modules connect to the SCVMM Management Server via WinRM and execute PowerShell cmdlets. The `vmm_server` parameter defaults to `localhost` if not specified.

```yaml
- hosts: scvmm_server
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
```

## Modules

### VM Lifecycle (ACA-5512)

| Module | Description |
|--------|-------------|
| `scvmm_vm` | Create, update, or delete virtual machines |
| `scvmm_vm_info` | Retrieve information about virtual machines |
| `scvmm_vm_state` | Manage VM power state (start/stop/suspend/resume) |
| `scvmm_vm_checkpoint` | Manage VM checkpoints (snapshots) |
| `scvmm_vm_migrate` | Live migrate VMs between Hyper-V hosts |
| `scvmm_vm_clone` | Clone existing virtual machines |
| `scvmm_vm_dvd_drive` | Manage virtual DVD drives |
| `scvmm_vm_scsi_adapter` | Manage virtual SCSI adapters |

## License

GPL-3.0-or-later
