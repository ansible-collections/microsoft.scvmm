# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
name: scvmm_inventory
short_description: SCVMM dynamic inventory source
description:
  - Discovers virtual machines and Hyper-V hosts managed by Microsoft System
    Center Virtual Machine Manager (SCVMM) and returns them as an Ansible
    inventory.
  - Connects to the SCVMM server from the controller over PowerShell Remoting
    (PSRP) using the C(pypsrp) library and runs the SCVMM PowerShell cmdlets on
    the server.
  - Each virtual machine is exposed with metadata (status, cloud, host, host
    group, operating system, CPU/memory) and network details (IPv4 and MAC
    addresses) as host variables prefixed with C(scvmm_).
  - Each Hyper-V host is exposed with metadata (state, host group, cluster,
    virtualization platform, VM count) as host variables prefixed with
    C(scvmm_).
  - Every inventory host carries a C(scvmm_object_type) variable set to
    C(vm) or C(host). Virtual machines are placed in the C(virtual_machines)
    group and Hyper-V hosts in the C(hyperv_hosts) group.
  - SCVMM virtual-machine names are not guaranteed to be unique. When two
    objects share a name, the inventory hostname is disambiguated by appending
    a short object-ID suffix and a warning is emitted; the original name is
    always preserved in C(scvmm_name).
version_added: "1.2.0"
author:
  - Ansible Cloud Team (@ansible)
requirements:
  - pypsrp
extends_documentation_fragment:
  - microsoft.scvmm.scvmm
  - constructed
  - inventory_cache
options:
  plugin:
    description:
      - Token that ensures this is a source file for the
        C(microsoft.scvmm.scvmm_inventory) plugin.
    type: str
    required: true
    choices:
      - microsoft.scvmm.scvmm_inventory
  include_vms:
    description:
      - Whether to include SCVMM virtual machines in the inventory.
    type: bool
    default: true
  include_hosts:
    description:
      - Whether to include SCVMM-managed Hyper-V hosts in the inventory.
    type: bool
    default: true
'''

EXAMPLES = r'''
# scvmm.yml — full example with grouping, composed address, and caching.
#
# The two commented variants below show simpler configurations; a source file
# holds a single configuration, so use only one of them at a time.
#
# Minimal (credentials from environment):
#   plugin: microsoft.scvmm.scvmm_inventory
#   vmm_server: scvmm.example.com
#
# Virtual machines only (skip Hyper-V hosts):
#   plugin: microsoft.scvmm.scvmm_inventory
#   vmm_server: scvmm.example.com
#   include_hosts: false
plugin: microsoft.scvmm.scvmm_inventory
vmm_server: scvmm.example.com
auth: kerberos
keyed_groups:
  - key: scvmm_object_type
    prefix: type
  - key: scvmm_cloud
    prefix: cloud
  - key: scvmm_status
    prefix: status
  - key: scvmm_host_group
    prefix: hostgroup
compose:
  ansible_host: scvmm_ipv4_addresses[0]
groups:
  running: scvmm_object_type == 'vm' and scvmm_status == 'Running'
cache: true
cache_plugin: jsonfile
cache_timeout: 300
'''

from ansible.errors import AnsibleParserError
from ansible.plugins.inventory import BaseInventoryPlugin, Constructable, Cacheable

from ansible_collections.microsoft.scvmm.plugins.plugin_utils.scvmm_client import (
    SCVMMClient,
    SCVMMClientError,
)

# SCVMM query keys (from scvmm_inventory.ps1) exposed as scvmm_<key> hostvars.
_VM_HOSTVAR_KEYS = (
    "id",
    "name",
    "status",
    "owner",
    "host_name",
    "host_group",
    "cloud",
    "cpu_count",
    "memory_mb",
    "operating_system",
    "description",
    "creation_time",
    "ipv4_addresses",
    "mac_addresses",
    "network_adapters",
)

_HOST_HOSTVAR_KEYS = (
    "id",
    "name",
    "computer_name",
    "state",
    "host_group",
    "cluster",
    "virtualization_platform",
    "virtual_machine_count",
)

# Groups every object is placed in, keyed by scvmm_object_type.
_GROUP_FOR_TYPE = {
    "vm": "virtual_machines",
    "host": "hyperv_hosts",
}


class InventoryModule(BaseInventoryPlugin, Constructable, Cacheable):

    NAME = "microsoft.scvmm.scvmm_inventory"

    def verify_file(self, path):
        """Cheap filename check before Ansible parses the source."""
        if super(InventoryModule, self).verify_file(path):
            return path.endswith((
                "scvmm.yml", "scvmm.yaml",
                "scvmm_inventory.yml", "scvmm_inventory.yaml",
            ))
        return False

    def _connection_options(self):
        return {
            "vmm_server": self.get_option("vmm_server"),
            "username": self.get_option("username"),
            "password": self.get_option("password"),
            "auth": self.get_option("auth"),
            "port": self.get_option("port"),
            "use_ssl": self.get_option("use_ssl"),
            "validate_certs": self.get_option("validate_certs"),
            "ca_cert": self.get_option("ca_cert"),
            "connection_timeout": self.get_option("connection_timeout"),
            "message_encryption": self.get_option("message_encryption"),
        }

    def _query(self):
        """Fetch inventory data from SCVMM. Returns a JSON-serialisable dict."""
        try:
            client = SCVMMClient(self._connection_options())
            return client.fetch_inventory()
        except SCVMMClientError as exc:
            raise AnsibleParserError(str(exc))

    @staticmethod
    def _short_id(value):
        """Return a short, filename-safe suffix derived from an SCVMM object ID."""
        if not value:
            return None
        return str(value).replace("-", "")[:8]

    def _collect_entries(self, data):
        """Flatten the query payload into ``(object_type, keys, item)`` tuples.

        Respects the ``include_vms`` / ``include_hosts`` options.
        """
        entries = []
        if self.get_option("include_vms"):
            for vm in data.get("virtual_machines") or []:
                if vm.get("name"):
                    entries.append(("vm", _VM_HOSTVAR_KEYS, vm))
        if self.get_option("include_hosts"):
            for host in data.get("hosts") or []:
                if host.get("name"):
                    entries.append(("host", _HOST_HOSTVAR_KEYS, host))
        return entries

    def _resolve_hostnames(self, entries):
        """Map each entry to a unique inventory hostname.

        SCVMM object names are not unique. When a name is shared, every colliding
        entry gets a short object-ID suffix so no host is silently overwritten,
        and a single warning lists the affected names.
        """
        name_counts = {}
        for _object_type, _keys, item in entries:
            name = item.get("name")
            name_counts[name] = name_counts.get(name, 0) + 1

        duplicated = sorted(name for name, count in name_counts.items() if count > 1)
        if duplicated:
            self.display.warning(
                "microsoft.scvmm.scvmm_inventory: duplicate SCVMM object names "
                "detected; appending a short ID suffix to keep inventory "
                "hostnames unique. Affected names: %s" % ", ".join(duplicated)
            )

        hostnames = []
        used = set()
        for index, (_object_type, _keys, item) in enumerate(entries):
            name = item.get("name")
            if name_counts[name] > 1:
                suffix = self._short_id(item.get("id")) or str(index)
                hostname = "%s_%s" % (name, suffix)
                # Guard against the unlikely case the disambiguated name repeats.
                while hostname in used:
                    hostname = "%s_%s_%d" % (name, suffix, index)
            else:
                hostname = name
            used.add(hostname)
            hostnames.append(hostname)
        return hostnames

    def _populate(self, data):
        strict = self.get_option("strict")
        compose = self.get_option("compose")
        groups = self.get_option("groups")
        keyed_groups = self.get_option("keyed_groups")

        entries = self._collect_entries(data)
        hostnames = self._resolve_hostnames(entries)

        for hostname, (object_type, keys, item) in zip(hostnames, entries):
            self.inventory.add_host(hostname)

            group = _GROUP_FOR_TYPE[object_type]
            self.inventory.add_group(group)
            self.inventory.add_child(group, hostname)

            host_vars = {"scvmm_object_type": object_type}
            self.inventory.set_variable(hostname, "scvmm_object_type", object_type)
            for key in keys:
                value = item.get(key)
                host_vars["scvmm_" + key] = value
                self.inventory.set_variable(hostname, "scvmm_" + key, value)

            # Sensible default so discovered VMs are addressable; a user
            # 'compose: ansible_host: ...' still overrides this afterwards.
            ipv4 = item.get("ipv4_addresses") or []
            if object_type == "vm" and ipv4:
                host_vars["ansible_host"] = ipv4[0]
                self.inventory.set_variable(hostname, "ansible_host", ipv4[0])

            self._set_composite_vars(compose, host_vars, hostname, strict=strict)
            self._add_host_to_composed_groups(groups, host_vars, hostname, strict=strict)
            self._add_host_to_keyed_groups(keyed_groups, host_vars, hostname, strict=strict)

    def parse(self, inventory, loader, path, cache=True):
        super(InventoryModule, self).parse(inventory, loader, path, cache)
        self._read_config_data(path)

        self.load_cache_plugin()
        cache_key = self.get_cache_key(path)

        user_cache_setting = self.get_option("cache")
        attempt_to_read_cache = user_cache_setting and cache
        cache_needs_update = user_cache_setting and not cache

        data = None
        if attempt_to_read_cache:
            try:
                data = self._cache[cache_key]
            except KeyError:
                cache_needs_update = True

        if data is None:
            data = self._query()

        if cache_needs_update:
            self._cache[cache_key] = data

        self._populate(data)
