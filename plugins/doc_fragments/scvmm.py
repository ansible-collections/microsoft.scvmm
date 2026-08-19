# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type


class ModuleDocFragment(object):

    # Shared connection/authentication options for controller-side SCVMM
    # plugins that reach the SCVMM server over PowerShell Remoting (PSRP).
    DOCUMENTATION = r'''
options:
  vmm_server:
    description:
      - Hostname or IP address of the SCVMM server to connect to over PSRP
        (PowerShell Remoting).
      - The SCVMM PowerShell cmdlets are executed on this host against the
        local VMM instance.
    type: str
    required: true
    env:
      - name: SCVMM_SERVER
  username:
    description:
      - Username used to authenticate to the SCVMM server.
      - For O(auth=kerberos) this is typically C(user@DOMAIN.COM).
    type: str
    env:
      - name: SCVMM_USERNAME
  password:
    description:
      - Password used to authenticate to the SCVMM server.
    type: str
    env:
      - name: SCVMM_PASSWORD
  auth:
    description:
      - Authentication mechanism used for the PSRP connection.
      - V(kerberos) requires the C(pypsrp[kerberos]) extra and the system
        Kerberos libraries; V(negotiate) works with no additional binary
        dependencies and is the safe default for Execution Environments.
    type: str
    default: negotiate
    choices:
      - negotiate
      - kerberos
      - ntlm
      - credssp
      - basic
      - certificate
    env:
      - name: SCVMM_AUTH
  port:
    description:
      - Port used for the PSRP/WinRM connection.
      - Defaults to V(5985) for HTTP and V(5986) for HTTPS when not set.
    type: int
  use_ssl:
    description:
      - Whether to connect over HTTPS (WinRM over TLS) instead of HTTP.
    type: bool
    default: false
  validate_certs:
    description:
      - Whether to validate the SCVMM server's TLS certificate when
        O(use_ssl=true).
    type: bool
    default: true
  ca_cert:
    description:
      - Path to a CA certificate bundle used to validate the server
        certificate when O(use_ssl=true).
    type: path
  connection_timeout:
    description:
      - Timeout, in seconds, for the PSRP connection and operations.
    type: int
    default: 30
  message_encryption:
    description:
      - Controls PSRP message encryption over HTTP.
    type: str
    default: auto
    choices:
      - auto
      - always
      - never
'''
