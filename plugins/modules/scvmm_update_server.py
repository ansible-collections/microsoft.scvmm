# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: scvmm_update_server
version_added: "1.1.0"
short_description: Manage WSUS update servers in System Center Virtual Machine Manager
description:
  - Add, update, or remove Windows Server Update Services (WSUS) integration in SCVMM.
  - Uses Add-SCUpdateServer to register a WSUS server with VMM.
  - Uses Set-SCUpdateServer to configure update categories, classifications, and languages.
  - Uses Remove-SCUpdateServer to remove WSUS integration from VMM.
options:
  computer_name:
    description:
      - FQDN, IP address, or NetBIOS name of the WSUS server.
      - This is the primary identifier for the update server.
    type: str
    required: true
  tcp_port:
    description:
      - TCP port used to communicate with the WSUS server.
      - Required when O(state=present) and the update server does not yet exist.
    type: int
  credential:
    description:
      - Name of the Run As account to authenticate with the WSUS server.
      - Required when O(state=present) and the update server does not yet exist, or when O(state=absent).
    type: str
  use_ssl:
    description:
      - Whether the connection to the WSUS server uses SSL.
    type: bool
  start_sync:
    description:
      - Whether to immediately start synchronising updates after adding the server.
    type: bool
  update_categories:
    description:
      - List of product categories for the update server to synchronise.
    type: list
    elements: str
  update_classifications:
    description:
      - List of update classifications for the update server to synchronise.
      - 'Valid values include: Applications, Critical Updates, Definition Updates,
        Drivers, Feature Packs, Security Updates, Service Packs, Tools, Update Rollups, Updates.'
    type: list
    elements: str
  update_languages:
    description:
      - List of languages for the update server to synchronise.
    type: list
    elements: str
  enable_proxy:
    description:
      - Whether to enable a proxy server for WSUS synchronisation.
      - Set to V(true) to enable proxy, V(false) to disable.
    type: bool
  proxy_server_name:
    description:
      - Hostname of the proxy server.
      - Only used when O(enable_proxy=true).
    type: str
  proxy_server_port:
    description:
      - Port of the proxy server.
      - Only used when O(enable_proxy=true).
    type: int
  state:
    description:
      - Desired state of the WSUS update server integration.
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
- name: Add a WSUS update server
  microsoft.scvmm.scvmm_update_server:
    computer_name: wsus.example.com
    tcp_port: 8530
    credential: WSUS-RunAs
    state: present

- name: Add a WSUS server with SSL and start sync
  microsoft.scvmm.scvmm_update_server:
    computer_name: wsus.example.com
    tcp_port: 8531
    credential: WSUS-RunAs
    use_ssl: true
    start_sync: true
    state: present

- name: Configure update classifications
  microsoft.scvmm.scvmm_update_server:
    computer_name: wsus.example.com
    update_classifications:
      - Security Updates
      - Critical Updates
      - Service Packs
    state: present

- name: Enable proxy for WSUS sync
  microsoft.scvmm.scvmm_update_server:
    computer_name: wsus.example.com
    enable_proxy: true
    proxy_server_name: proxy.example.com
    proxy_server_port: 8080
    state: present

- name: Remove a WSUS update server
  microsoft.scvmm.scvmm_update_server:
    computer_name: wsus.example.com
    credential: WSUS-RunAs
    state: absent
'''

RETURN = r'''
update_server:
  description: Details of the WSUS update server.
  returned: when state is present and server exists
  type: dict
  contains:
    id:
      description: Update server ID in SCVMM.
      type: str
      returned: always
      sample: "12345678-1234-1234-1234-123456789012"
    name:
      description: Name of the update server.
      type: str
      returned: always
      sample: "wsus.example.com"
    fqdn:
      description: Fully qualified domain name of the WSUS server.
      type: str
      returned: when available
      sample: "wsus.example.com"
    port:
      description: TCP port used by the WSUS server.
      type: int
      returned: when available
      sample: 8530
    is_connection_secure:
      description: Whether the WSUS connection uses SSL.
      type: bool
      returned: always
      sample: false
    server_state:
      description: Current operational state of the update server.
      type: str
      returned: when available
      sample: "Available"
    update_categories:
      description: List of product categories configured for synchronisation.
      type: list
      elements: str
      returned: always
      sample: ["Windows Server 2019"]
    update_classifications:
      description: List of update classifications configured for synchronisation.
      type: list
      elements: str
      returned: always
      sample: ["Security Updates", "Critical Updates"]
    update_languages:
      description: List of languages configured for synchronisation.
      type: list
      elements: str
      returned: always
      sample: ["en"]
    proxy_server_name:
      description: Hostname of the configured proxy server.
      type: str
      returned: always
      sample: "proxy.example.com"
    proxy_server_port:
      description: Port of the configured proxy server.
      type: int
      returned: always
      sample: 8080
'''
