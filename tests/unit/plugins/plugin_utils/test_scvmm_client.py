# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

import json

import pytest

from ansible_collections.microsoft.scvmm.plugins.plugin_utils import scvmm_client
from ansible_collections.microsoft.scvmm.plugins.plugin_utils.scvmm_client import (
    SCVMMClient,
    SCVMMClientError,
)


@pytest.fixture
def with_pypsrp(monkeypatch):
    """Pretend pypsrp is importable so SCVMMClient can be constructed."""
    monkeypatch.setattr(scvmm_client, "HAS_PYPSRP", True)


BASE_OPTS = {
    "vmm_server": "scvmm.example.com",
    "username": "admin",
    "password": "secret",
    "auth": "negotiate",
    "port": None,
    "use_ssl": False,
    "validate_certs": True,
    "ca_cert": None,
    "connection_timeout": 30,
    "message_encryption": "auto",
}


def test_init_without_pypsrp_raises(monkeypatch):
    monkeypatch.setattr(scvmm_client, "HAS_PYPSRP", False)
    with pytest.raises(SCVMMClientError) as exc:
        SCVMMClient(dict(BASE_OPTS))
    assert "pypsrp" in str(exc.value)


def test_wsman_kwargs_http_defaults(with_pypsrp):
    client = SCVMMClient(dict(BASE_OPTS))
    kwargs = client._wsman_kwargs()
    assert kwargs["server"] == "scvmm.example.com"
    assert kwargs["port"] == 5985
    assert kwargs["ssl"] is False
    assert kwargs["auth"] == "negotiate"
    assert kwargs["cert_validation"] is True
    assert kwargs["connection_timeout"] == 30
    assert kwargs["encryption"] == "auto"


def test_wsman_kwargs_ssl_default_port(with_pypsrp):
    opts = dict(BASE_OPTS, use_ssl=True)
    client = SCVMMClient(opts)
    kwargs = client._wsman_kwargs()
    assert kwargs["ssl"] is True
    assert kwargs["port"] == 5986


def test_wsman_kwargs_explicit_port(with_pypsrp):
    opts = dict(BASE_OPTS, port=15986, use_ssl=True)
    client = SCVMMClient(opts)
    assert client._wsman_kwargs()["port"] == 15986


def test_wsman_kwargs_requires_server(with_pypsrp):
    opts = dict(BASE_OPTS, vmm_server=None)
    client = SCVMMClient(opts)
    with pytest.raises(SCVMMClientError):
        client._wsman_kwargs()


def test_cert_validation_disabled(with_pypsrp):
    client = SCVMMClient(dict(BASE_OPTS, validate_certs=False))
    assert client._cert_validation() is False


def test_cert_validation_ca_cert_path(with_pypsrp):
    client = SCVMMClient(dict(BASE_OPTS, ca_cert="/etc/pki/ca.pem"))
    assert client._cert_validation() == "/etc/pki/ca.pem"


def test_fetch_inventory_parses(with_pypsrp, monkeypatch):
    payload = {"virtual_machines": [{"name": "vm1", "status": "Running"}]}
    client = SCVMMClient(dict(BASE_OPTS))
    monkeypatch.setattr(client, "run_powershell", lambda script: json.dumps(payload))
    result = client.fetch_inventory()
    assert result["virtual_machines"][0]["name"] == "vm1"


def test_fetch_inventory_single_vm_normalised(with_pypsrp, monkeypatch):
    # ConvertTo-Json returns a bare object for a single VM.
    payload = {"virtual_machines": {"name": "solo"}}
    client = SCVMMClient(dict(BASE_OPTS))
    monkeypatch.setattr(client, "run_powershell", lambda script: json.dumps(payload))
    result = client.fetch_inventory()
    assert isinstance(result["virtual_machines"], list)
    assert result["virtual_machines"][0]["name"] == "solo"


def test_fetch_inventory_normalises_hosts(with_pypsrp, monkeypatch):
    # hosts: single object -> list; also parses the vms alongside.
    payload = {
        "virtual_machines": [{"name": "vm1"}],
        "hosts": {"name": "hv01"},
    }
    client = SCVMMClient(dict(BASE_OPTS))
    monkeypatch.setattr(client, "run_powershell", lambda script: json.dumps(payload))
    result = client.fetch_inventory()
    assert isinstance(result["hosts"], list)
    assert result["hosts"][0]["name"] == "hv01"


def test_fetch_inventory_missing_hosts_defaults_empty(with_pypsrp, monkeypatch):
    # Older payloads without a hosts key must default to an empty list.
    payload = {"virtual_machines": [{"name": "vm1"}]}
    client = SCVMMClient(dict(BASE_OPTS))
    monkeypatch.setattr(client, "run_powershell", lambda script: json.dumps(payload))
    result = client.fetch_inventory()
    assert result["hosts"] == []


def test_fetch_inventory_error_key_raises(with_pypsrp, monkeypatch):
    client = SCVMMClient(dict(BASE_OPTS))
    monkeypatch.setattr(client, "run_powershell", lambda script: json.dumps({"error": "boom"}))
    with pytest.raises(SCVMMClientError) as exc:
        client.fetch_inventory()
    assert "boom" in str(exc.value)


def test_fetch_inventory_bad_json_raises(with_pypsrp, monkeypatch):
    client = SCVMMClient(dict(BASE_OPTS))
    monkeypatch.setattr(client, "run_powershell", lambda script: "not json")
    with pytest.raises(SCVMMClientError):
        client.fetch_inventory()


def test_fetch_inventory_empty_raises(with_pypsrp, monkeypatch):
    client = SCVMMClient(dict(BASE_OPTS))
    monkeypatch.setattr(client, "run_powershell", lambda script: "   ")
    with pytest.raises(SCVMMClientError):
        client.fetch_inventory()


def test_fetch_inventory_missing_key_raises(with_pypsrp, monkeypatch):
    client = SCVMMClient(dict(BASE_OPTS))
    monkeypatch.setattr(client, "run_powershell", lambda script: json.dumps({"other": 1}))
    with pytest.raises(SCVMMClientError):
        client.fetch_inventory()
