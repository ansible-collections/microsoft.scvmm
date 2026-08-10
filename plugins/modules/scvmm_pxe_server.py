# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_pxe_server
version_added: "1.1.0"
short_description: Manage PXE servers in System Center Virtual Machine Manager
description:
  - Register or unregister PXE servers in SCVMM.
  - Uses Add-SCPXEServer to install a VMM agent on a Windows Deployment Services
    computer and register it as a PXE server.
  - Uses Remove-SCPXEServer to uninstall the VMM agent and unregister the PXE server.
  - This module does not support updating PXE server properties because SCVMM does
    not provide a Set-SCPXEServer cmdlet.
  - The target computer must have the Windows Deployment Services role installed
    before it can be registered as a PXE server.
options:
  computer_name:
    description:
      - Hostname or FQDN of the Windows Deployment Services computer to register
        as a PXE server.
      - Used to look up existing PXE servers and to specify the target for registration.
    type: str
    required: true
  run_as_account:
    description:
      - Name of the VMM Run As account to use for credentials when registering
        or unregistering the PXE server.
      - The account must have administrative privileges on the target computer.
      - The account must not be the same as the VMM service account.
      - Required when C(state=present).
      - Optional when C(state=absent); if provided, credentials are passed to
        the removal cmdlet.
    type: str
  state:
    description:
      - Desired state of the PXE server.
      - C(present) registers the computer as a PXE server in VMM.
      - C(absent) unregisters the PXE server and uninstalls the VMM agent.
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
- name: Register a PXE server
  microsoft.scvmm.scvmm_pxe_server:
    computer_name: wds01.contoso.com
    run_as_account: "VMM Host RunAs"
    state: present
    vmm_server: scvmm.example.com

- name: Unregister a PXE server
  microsoft.scvmm.scvmm_pxe_server:
    computer_name: wds01.contoso.com
    state: absent
    vmm_server: scvmm.example.com
'''

RETURN = r'''
pxe_server:
  description: Details of the PXE server.
  returned: when state is present and PXE server is registered
  type: dict
  contains:
    id:
      description: PXE server ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Name of the PXE server.
      type: str
      returned: always
      sample: "wds01.contoso.com"
    managed_computer:
      description: FQDN of the managed computer associated with this PXE server.
      type: str
      returned: always
      sample: "wds01.contoso.com"
'''
