# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

import pytest

from ansible.errors import AnsibleParserError
from ansible.inventory.data import InventoryData
from ansible.parsing.dataloader import DataLoader
from ansible.template import Templar

from ansible_collections.microsoft.scvmm.plugins.inventory import scvmm_inventory
from ansible_collections.microsoft.scvmm.plugins.inventory.scvmm_inventory import InventoryModule
from ansible_collections.microsoft.scvmm.plugins.plugin_utils.scvmm_client import SCVMMClientError

try:
    # ansible-core 2.19+ only evaluates template strings that are marked as
    # trusted. In real usage the plugin's config is trusted by
    # _read_config_data(); here we set options directly, so we must trust the
    # template-bearing options ourselves or keyed_groups/groups/compose no-op.
    from ansible.template import trust_as_template
except ImportError:  # older ansible-core has no trust concept
    def trust_as_template(value):
        return value


def _trust(value):
    """Recursively mark all string leaves as trusted templates."""
    if isinstance(value, str):
        return trust_as_template(value)
    if isinstance(value, list):
        return [_trust(v) for v in value]
    if isinstance(value, dict):
        return {k: _trust(v) for k, v in value.items()}
    return value


SAMPLE_DATA = {
    "virtual_machines": [
        {
            "name": "web01",
            "status": "Running",
            "cloud": "ProdCloud",
            "host_group": "All Hosts",
            "operating_system": "Windows Server 2022",
            "ipv4_addresses": ["10.0.0.5"],
            "mac_addresses": ["00:11:22:33:44:55"],
        },
        {
            "name": "db01",
            "status": "PowerOff",
            "cloud": "DevCloud",
            "host_group": "All Hosts",
            "ipv4_addresses": [],
            "mac_addresses": [],
        },
        {
            # no name -> must be skipped
            "name": None,
            "status": "Running",
        },
    ],
    "hosts": [],
}

SAMPLE_WITH_HOSTS = {
    "virtual_machines": [
        {"name": "web01", "status": "Running", "ipv4_addresses": ["10.0.0.5"]},
    ],
    "hosts": [
        {
            "name": "hv01.example.com",
            "computer_name": "hv01",
            "state": "OK",
            "host_group": "All Hosts",
            "cluster": None,
            "virtualization_platform": "HyperV",
            "virtual_machine_count": 12,
        },
    ],
}

SAMPLE_DUPLICATES = {
    "virtual_machines": [
        {"name": "dup", "id": "aaaaaaaa-1111-2222-3333-444444444444", "status": "Running"},
        {"name": "dup", "id": "bbbbbbbb-5555-6666-7777-888888888888", "status": "PowerOff"},
        {"name": "unique", "id": "cccccccc-9999-0000-1111-222222222222", "status": "Running"},
    ],
    "hosts": [],
}


def _make_plugin(options=None):
    plugin = InventoryModule()
    plugin.inventory = InventoryData()
    plugin.templar = Templar(loader=DataLoader())
    base = {
        "strict": False,
        "compose": {},
        "groups": {},
        "keyed_groups": [],
        "include_vms": True,
        "include_hosts": True,
    }
    if options:
        base.update(options)
    # Trust the template-bearing options so ansible-core 2.19+ evaluates them
    # (mirrors what _read_config_data() does for real config files).
    for opt in ("compose", "groups", "keyed_groups"):
        base[opt] = _trust(base[opt])
    plugin._options = base
    return plugin


def test_verify_file_accepts_expected_names(tmp_path):
    plugin = InventoryModule()
    for name in ("scvmm.yml", "scvmm.yaml", "scvmm_inventory.yml", "scvmm_inventory.yaml"):
        f = tmp_path / name
        f.write_text("plugin: microsoft.scvmm.scvmm_inventory\n")
        assert plugin.verify_file(str(f)) is True


def test_verify_file_rejects_other_names(tmp_path):
    plugin = InventoryModule()
    f = tmp_path / "hosts.yml"
    f.write_text("plugin: microsoft.scvmm.scvmm_inventory\n")
    assert plugin.verify_file(str(f)) is False


def test_populate_adds_hosts_and_vars():
    plugin = _make_plugin()
    plugin._populate(SAMPLE_DATA)

    hosts = plugin.inventory.hosts
    assert "web01" in hosts
    assert "db01" in hosts
    # VM with no name is skipped
    assert len(hosts) == 2

    web = plugin.inventory.get_host("web01")
    assert web.get_vars()["scvmm_status"] == "Running"
    assert web.get_vars()["scvmm_cloud"] == "ProdCloud"
    # ansible_host defaulted from first IPv4
    assert web.get_vars()["ansible_host"] == "10.0.0.5"


def test_populate_no_ip_leaves_ansible_host_unset():
    plugin = _make_plugin()
    plugin._populate(SAMPLE_DATA)
    db = plugin.inventory.get_host("db01")
    assert "ansible_host" not in db.get_vars()


def test_populate_keyed_groups_by_cloud():
    plugin = _make_plugin({
        "keyed_groups": [{"key": "scvmm_cloud", "prefix": "cloud", "separator": "_"}],
    })
    plugin._populate(SAMPLE_DATA)
    groups = plugin.inventory.groups
    assert "cloud_ProdCloud" in groups
    assert "cloud_DevCloud" in groups
    assert "web01" in [h.name for h in groups["cloud_ProdCloud"].hosts]


def test_populate_conditional_groups():
    plugin = _make_plugin({
        "groups": {"running": "scvmm_status == 'Running'"},
    })
    plugin._populate(SAMPLE_DATA)
    groups = plugin.inventory.groups
    assert "running" in groups
    running_hosts = [h.name for h in groups["running"].hosts]
    assert "web01" in running_hosts
    assert "db01" not in running_hosts


def test_populate_object_type_and_group_for_vm():
    plugin = _make_plugin()
    plugin._populate(SAMPLE_DATA)
    web = plugin.inventory.get_host("web01")
    assert web.get_vars()["scvmm_object_type"] == "vm"
    assert "web01" in [h.name for h in plugin.inventory.groups["virtual_machines"].hosts]


def test_populate_includes_hosts():
    plugin = _make_plugin()
    plugin._populate(SAMPLE_WITH_HOSTS)

    assert "hv01.example.com" in plugin.inventory.hosts
    hv = plugin.inventory.get_host("hv01.example.com")
    assert hv.get_vars()["scvmm_object_type"] == "host"
    assert hv.get_vars()["scvmm_state"] == "OK"
    assert hv.get_vars()["scvmm_virtual_machine_count"] == 12
    # host must not get a defaulted ansible_host
    assert "ansible_host" not in hv.get_vars()

    groups = plugin.inventory.groups
    assert "hv01.example.com" in [h.name for h in groups["hyperv_hosts"].hosts]
    assert "web01" in [h.name for h in groups["virtual_machines"].hosts]


def test_include_hosts_false_skips_hosts():
    plugin = _make_plugin({"include_hosts": False})
    plugin._populate(SAMPLE_WITH_HOSTS)
    assert "hv01.example.com" not in plugin.inventory.hosts
    assert "web01" in plugin.inventory.hosts


def test_include_vms_false_skips_vms():
    plugin = _make_plugin({"include_vms": False})
    plugin._populate(SAMPLE_WITH_HOSTS)
    assert "web01" not in plugin.inventory.hosts
    assert "hv01.example.com" in plugin.inventory.hosts


def test_duplicate_names_are_disambiguated_with_warning():
    plugin = _make_plugin()
    warnings = []
    plugin.display.warning = lambda msg, *a, **k: warnings.append(msg)

    plugin._populate(SAMPLE_DUPLICATES)

    hosts = set(plugin.inventory.hosts)
    # both duplicates kept, disambiguated by short id; unique one keeps its name
    assert "dup_aaaaaaaa" in hosts
    assert "dup_bbbbbbbb" in hosts
    assert "unique" in hosts
    assert "dup" not in hosts
    # original name preserved in scvmm_name
    assert plugin.inventory.get_host("dup_aaaaaaaa").get_vars()["scvmm_name"] == "dup"
    # a single warning naming the collision
    assert len(warnings) == 1
    assert "dup" in warnings[0]


def test_no_duplicate_warning_when_names_unique():
    plugin = _make_plugin()
    warnings = []
    plugin.display.warning = lambda msg, *a, **k: warnings.append(msg)
    plugin._populate(SAMPLE_DATA)
    assert warnings == []


def test_query_wraps_client_error(monkeypatch):
    plugin = _make_plugin({
        "vmm_server": "scvmm.example.com",
        "username": None, "password": None, "auth": "negotiate",
        "port": None, "use_ssl": False, "validate_certs": True,
        "ca_cert": None, "connection_timeout": 30, "message_encryption": "auto",
    })

    class _Boom:
        def __init__(self, *a, **k):
            pass

        def fetch_inventory(self):
            raise SCVMMClientError("connect failed")

    monkeypatch.setattr(scvmm_inventory, "SCVMMClient", _Boom)
    with pytest.raises(AnsibleParserError) as exc:
        plugin._query()
    assert "connect failed" in str(exc.value)
