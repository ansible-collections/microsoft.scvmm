# Prerequisites for SCVMM VM Lifecycle Management Collection

## Primary Platform

**System Center Virtual Machine Manager (SCVMM) 2022**
- PowerShell module: VirtualMachineManager
- All modules wrap SCVMM cmdlets prefixed with SC (e.g., New-SCVirtualMachine)

## Overview

This collection provides Ansible modules for complete SCVMM virtual machine lifecycle management including creating, modifying, cloning, migrating, and controlling VM power state, checkpoints, and hardware peripherals.

**Platform Name**: System Center Virtual Machine Manager (SCVMM) 2022
**Module Language**: PowerShell
**Connection Method**: winrm
