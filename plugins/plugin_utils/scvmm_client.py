# -*- coding: utf-8 -*-
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

"""Controller-side PSRP client for the microsoft.scvmm inventory plugin.

This module runs on the Ansible controller (not the SCVMM host). It opens a
PowerShell Remoting (PSRP) session to the SCVMM server using pypsrp, runs the
bundled ``scvmm_inventory.ps1`` query, and returns the parsed result.
"""

from __future__ import absolute_import, division, print_function
__metaclass__ = type

import json
import os

try:
    from pypsrp.wsman import WSMan
    from pypsrp.powershell import PowerShell, RunspacePool
    HAS_PYPSRP = True
    PYPSRP_IMPORT_ERROR = None
except ImportError as exc:  # pragma: no cover - exercised via HAS_PYPSRP
    HAS_PYPSRP = False
    PYPSRP_IMPORT_ERROR = exc

QUERY_SCRIPT = os.path.join(os.path.dirname(__file__), "scvmm_inventory.ps1")


class SCVMMClientError(Exception):
    """Raised for any SCVMM PSRP connection or query failure."""


class SCVMMClient(object):
    """Thin pypsrp wrapper that fetches SCVMM inventory data.

    :param options: mapping of the connection options declared in the
        ``microsoft.scvmm.scvmm`` doc fragment (vmm_server, username, password,
        auth, port, use_ssl, validate_certs, ca_cert, connection_timeout,
        message_encryption).
    """

    def __init__(self, options):
        if not HAS_PYPSRP:
            raise SCVMMClientError(
                "The 'pypsrp' Python library is required by the "
                "microsoft.scvmm.scvmm_inventory plugin. Install it with "
                "'pip install pypsrp' (or 'pip install pypsrp[kerberos]' for "
                "Kerberos authentication). Import error: %s" % PYPSRP_IMPORT_ERROR
            )
        self.options = options

    def _cert_validation(self):
        """Translate validate_certs/ca_cert into the pypsrp cert_validation arg."""
        if not self.options.get("validate_certs", True):
            return False
        ca_cert = self.options.get("ca_cert")
        if ca_cert:
            return ca_cert
        return True

    def _wsman_kwargs(self):
        server = self.options.get("vmm_server")
        if not server:
            raise SCVMMClientError("The 'vmm_server' option is required.")

        use_ssl = bool(self.options.get("use_ssl", False))
        port = self.options.get("port")
        if not port:
            port = 5986 if use_ssl else 5985

        return {
            "server": server,
            "port": int(port),
            "username": self.options.get("username"),
            "password": self.options.get("password"),
            "ssl": use_ssl,
            "auth": self.options.get("auth", "negotiate"),
            "cert_validation": self._cert_validation(),
            "connection_timeout": int(self.options.get("connection_timeout", 30)),
            "encryption": self.options.get("message_encryption", "auto"),
        }

    def _read_script(self):
        try:
            with open(QUERY_SCRIPT, "r") as handle:
                return handle.read()
        except (IOError, OSError) as exc:
            raise SCVMMClientError("Unable to read query script %s: %s" % (QUERY_SCRIPT, exc))

    def run_powershell(self, script):
        """Run a PowerShell script over PSRP and return its stdout as text."""
        try:
            wsman = WSMan(**self._wsman_kwargs())
            with RunspacePool(wsman) as pool:
                shell = PowerShell(pool)
                shell.add_script(script)
                output = shell.invoke()
                if shell.had_errors:
                    errors = "; ".join(str(err) for err in shell.streams.error)
                    raise SCVMMClientError(
                        "PowerShell execution on '%s' reported errors: %s"
                        % (self.options.get("vmm_server"), errors or "unknown error")
                    )
        except SCVMMClientError:
            raise
        except Exception as exc:  # noqa: BLE001 - surface any pypsrp/transport error
            raise SCVMMClientError(
                "Failed to connect to SCVMM server '%s' over PSRP: %s"
                % (self.options.get("vmm_server"), exc)
            )
        return "".join(str(item) for item in output if item is not None)

    @staticmethod
    def _as_list(value):
        """Normalise a ConvertTo-Json field to a list.

        PowerShell ``ConvertTo-Json`` emits a bare object (not an array) for a
        single element and omits/None for an empty collection.
        """
        if value is None:
            return []
        if isinstance(value, dict):
            return [value]
        return value

    def fetch_inventory(self):
        """Run the bundled query and return the parsed inventory dict.

        :returns: dict with ``virtual_machines`` and ``hosts`` lists.
        :raises SCVMMClientError: on connection, execution, or parse failure,
            or when the query itself reports an error.
        """
        raw = self.run_powershell(self._read_script())
        if not raw.strip():
            raise SCVMMClientError(
                "SCVMM inventory query returned no data from '%s'."
                % self.options.get("vmm_server")
            )
        try:
            data = json.loads(raw)
        except ValueError as exc:
            raise SCVMMClientError(
                "Failed to parse SCVMM inventory JSON from '%s': %s"
                % (self.options.get("vmm_server"), exc)
            )

        if isinstance(data, dict) and data.get("error"):
            raise SCVMMClientError(data["error"])

        if not isinstance(data, dict) or "virtual_machines" not in data:
            raise SCVMMClientError(
                "Unexpected SCVMM inventory payload from '%s'."
                % self.options.get("vmm_server")
            )

        # Normalise both collections to lists for consistent downstream handling.
        data["virtual_machines"] = self._as_list(data.get("virtual_machines"))
        data["hosts"] = self._as_list(data.get("hosts"))
        return data
