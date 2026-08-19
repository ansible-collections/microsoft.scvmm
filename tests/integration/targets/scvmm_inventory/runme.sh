#!/usr/bin/env bash
# Copyright (c) 2026, Ansible Cloud Team (@ansible)
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)
#
# Integration test for the microsoft.scvmm.scvmm_inventory plugin.
# Seeds a fixture VM (via the modules, over WinRM), runs the inventory plugin
# from the controller (over PSRP), asserts discovery, checks caching, and tears
# the fixture down.
#
# Required environment:
#   SCVMM_SERVER          - SCVMM host (also used by the plugin via env fallback)
#   SCVMM_USERNAME        - PSRP username (plugin)
#   SCVMM_PASSWORD        - PSRP password (plugin)
#   SCVMM_AUTH            - PSRP auth (e.g. ntlm, kerberos, negotiate)
#   SCVMM_WINRM_INVENTORY - winrm inventory used to seed/teardown the fixture
#   SCVMM_VM_HOST         - Hyper-V host for the fixture VM
#   SCVMM_VM_TEMPLATE     - template for the fixture VM

set -eux

FIXTURE_VM="${SCVMM_FIXTURE_VM:-AnsibleTest_InvPlugin_VM}"
export SCVMM_FIXTURE_VM="${FIXTURE_VM}"

SEED_VARS="scvmm_server=${SCVMM_SERVER} fixture_vm=${FIXTURE_VM} test_vm_host=${SCVMM_VM_HOST} test_vm_template=${SCVMM_VM_TEMPLATE}"

cleanup() {
    ansible-playbook teardown.yml -i "${SCVMM_WINRM_INVENTORY}" \
        -e "scvmm_server=${SCVMM_SERVER} fixture_vm=${FIXTURE_VM}" || true
}
trap cleanup EXIT

# 1. Seed the fixture VM via the modules (runs on the SCVMM host).
ansible-playbook setup.yml -i "${SCVMM_WINRM_INVENTORY}" -e "${SEED_VARS}" "$@"

# 2. Run the inventory plugin from the controller (over PSRP).
ansible-inventory -i test.scvmm.yml --list "$@"
ansible-inventory -i test.scvmm.yml --graph "$@"

# 3. Assert the plugin discovered the fixture with the expected data/groups.
ansible-playbook test_inventory.yml -i test.scvmm.yml "$@"

# 4. Cache smoke test: a second run must also succeed and see the fixture.
ansible-inventory -i test.scvmm.yml --list "$@"

# 5. Teardown handled by the EXIT trap.
