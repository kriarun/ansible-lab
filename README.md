# Infrastructure Automation Platform

This repository contains an Ansible-based automation platform for provisioning and maintaining standardized Windows and Linux machines across multiple environments.

The current codebase is centered around:

- Windows toolbox machines composed from shared and team-specific profiles
- Windows UiPath platform machines composed from machine profiles
- Linux GitLab runner machines
- Environment-specific inventory and override layers
- A parameterized GitLab CI pipeline for syntax-check and deployment entry points

## How The Repository Is Organized

The automation model is intentionally data-driven:

1. Inventories decide where automation runs.
2. Profiles decide what a machine should contain.
3. Software catalog entries define how packages are sourced and installed.
4. Roles implement reusable execution logic.
5. Playbooks compose profiles and roles into runnable entry points.

## Repository Layout

```text
inventories/
  dev/
  lab/
  prd/
  sandbox/
  tst/
  group_vars/

playbooks/
  linux/
    gitlab_runner.yml
  windows/
    platform/
      uipath_orchestrator.yml
      uipath_test_manager.yml
    toolbox/
      team_alpha.yml
      team_beta.yml
      team_gamma.yml
      team_neon.yml

profiles/
  linux/
    machines/
    software_catalog.yml
  windows/
    machines/
    software_catalog/
    toolbox/

roles/
  linux/
  windows/

docs/
  architecture/
  how-to/
  reference/
```

## Inventory Model

Environment inventories live under `inventories/<environment>/`.

Current environments in the repo:

- `lab`
- `dev`
- `tst`
- `prd`
- `sandbox`

Environment intent at a high level:

- `sandbox` is the safe development inventory for Ansible work. It exists so playbooks, role composition, and changes can be developed and executed without using `lab`.
- `lab` is not treated as the primary development space for Ansible changes. It serves a different operational purpose and should not be the default place for day-to-day automation development.
- `dev`, `tst`, and `prd` represent the more standard progression toward validated and production usage.

Common patterns:

- `hosts.yml` defines the inventory structure for that environment.
- `group_vars/windows.yml` carries shared Windows connection settings.
- Group-specific files such as `group_vars/uipath_orchestrator.yml` or `group_vars/team_neon.yml` provide targeted overrides.
- `inventories/group_vars/` holds cross-environment defaults.

## Profile Model

The repository currently uses two main Windows composition styles.

### Toolbox Profiles

Toolbox playbooks combine:

- `profiles/windows/toolbox/base.yml`
- one team profile such as `profiles/windows/toolbox/team_alpha.yml`
- optional environment additions and removals from inventory vars

The resulting role set is derived from:

```text
base_roles + team_roles + env_add_roles - remove_roles - env_remove_roles
```

Role-layer intent:

- `base_roles` is used for toolbox machines to define the baseline software set that should normally exist everywhere for that toolbox type.
- `team_roles` adds team-specific software on top of the toolbox baseline.
- `env_add_roles` is used when a role should exist only in one environment such as `sandbox`, `dev`, or `lab`, which makes controlled rollout easier.
- `env_remove_roles` is used when a role should be excluded only in one environment, again to support safer staged rollout and environment-specific exceptions.
- `remove_roles` is used to remove a role for a more specific target such as a machine or group, without changing the broader shared profile intent.

### Platform Machine Profiles

UiPath playbooks load a machine profile directly from:

```text
profiles/windows/machines/
```

Each machine profile defines:

- `machine_roles`
- package lists consumed by those roles
- optional machine-level environment variables via `machine_env`

### Linux Profiles

Linux currently uses:

- `profiles/linux/machines/gitlab_runner.yml`
- `profiles/linux/software_catalog.yml`

This path is present but still much lighter than the Windows implementation.

## Software Catalog Model

Windows software metadata is split into catalog fragments under:

```text
profiles/windows/software_catalog/
```

Examples currently in the repo include:

- `git.yml`
- `python.yml`
- `vscode.yml`
- `dotnet_hosting.yml`
- `uipath_orchestrator_migration.yml`

Catalog entries describe package metadata such as:

- source type
- installer file details
- installation arguments
- verification checks
- optional PATH, environment, registry, or certificate configuration

Windows roles generally resolve and install packages through the shared helper:

```text
roles/windows/common/tasks/install_from_catalog.yml
```

## Playbook Entry Points

Current playbooks:

### Windows toolbox

- `playbooks/windows/toolbox/team_alpha.yml`
- `playbooks/windows/toolbox/team_beta.yml`
- `playbooks/windows/toolbox/team_gamma.yml`
- `playbooks/windows/toolbox/team_neon.yml`

These playbooks compute a final role set from toolbox profile layers. They are currently written in a debug/composition-first style and gate role execution behind `execute_roles`.

### Windows platform

- `playbooks/windows/platform/uipath_orchestrator.yml`
- `playbooks/windows/platform/uipath_test_manager.yml`

These playbooks load a machine profile, compute `final_roles`, and execute the matching Windows roles.

### Linux

- `playbooks/linux/gitlab_runner.yml`

This playbook loads the Linux profile and executes the `linux/gitlab_runner` role.

## Running Playbooks

Use an explicit environment inventory when invoking Ansible.

Examples:

```powershell
ansible-playbook -i inventories/lab/hosts.yml playbooks/windows/platform/uipath_orchestrator.yml
ansible-playbook -i inventories/dev/hosts.yml playbooks/windows/platform/uipath_test_manager.yml
ansible-playbook -i inventories/prd/hosts.yml playbooks/linux/gitlab_runner.yml
```

For toolbox playbooks, the current pattern is team-specific. If you want role execution rather than composition/debug output, pass `execute_roles=true`.

In practice, the recommended development path is to validate new toolbox changes in `sandbox` first, then promote them through the other environments as needed.

Example:

```powershell
ansible-playbook -i inventories/sandbox/hosts.yml playbooks/windows/toolbox/team_neon.yml -e "execute_roles=true"
```

## CI/CD Pipeline

The starter GitLab pipeline is defined in [`.gitlab-ci.yml`](.gitlab-ci.yml).

It currently exposes three key inputs:

- `environment`: `lab`, `dev`, `tst`, `prd`, or `sandbox`
- `domain`: `toolbox` or `platform`
- `target`: playbook target inside that domain

Current stages:

- `codestyle`
- `verify`
- `fetch-secrets`
- `deploy`

The `verify-roles` job performs a syntax check using:

```text
ansible-playbook -i inventories/<environment>/hosts.yml playbooks/windows/<domain>/<target>.yml --syntax-check
```

The deploy job runs the same playbook as a manual step.

## Contribution Guidelines

- Keep machine intent in profiles, not in playbooks.
- Keep package metadata in the software catalog, not in role task files.
- Prefer shared logic under `roles/windows/common/tasks/` when adding Windows install behavior.
- Validate changes in non-production inventories before using `prd`.
- Do not store secrets in the repository.

## Documentation Map

For deeper guidance, use:

- [Architecture overview](docs/architecture/arc42-architecture.md)
- [How to add a role](docs/how-to/add-a-role.md)
- [How to add a software catalog entry](docs/how-to/add-a-software-catalog-entry.md)
- [Machine profile examples](docs/reference/machine-profile-examples.md)
- [Software catalog examples](docs/reference/software-catalog-examples.md)
- [Future considerations](docs/reference/future-considerations.md)

## Current State Notes

- Windows is the most developed automation path in this repo today.
- Toolbox and platform playbooks follow different composition patterns.
- Linux is present but still more lightweight and debug-oriented.
- The GitLab pipeline is a solid starter, but the full operational workflow is still evolving.
