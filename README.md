# Ansible Lab

Phase 1 – Debug Implementation

## Architecture Layers

1. Inventory Layer – Environment & machine grouping
2. Blueprint Layer – Role definitions (base, team, machine)
3. Role Layer – Execution logic (debug-only for now)

## Run

ansible-playbook playbooks/windows_toolbox.yml
ansible-playbook playbooks/windows_uipath.yml
ansible-playbook playbooks/linux_runner.yml
