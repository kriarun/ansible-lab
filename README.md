# Infrastructure Automation Platform

This repository contains an Ansible-based automation platform for provisioning and maintaining standardized Windows and Linux machines across multiple environments.

The current codebase is centered around:

- Windows toolbox machines composed from shared and team-specific profiles
- Windows UiPath platform machines composed from machine profiles
- Linux GitLab runner machines
- Environment-specific inventory and override layers
- A parameterized GitLab CI pipeline for syntax-check and deployment entry points

## Purpose

The repository follows a profile-driven automation model:

- inventories decide where automation runs
- profiles decide what a machine should contain
- software catalog entries define how packages are sourced and installed
- shared resolver and execution tasks normalize installation behavior
- roles apply reusable machine configuration
- playbooks compose those layers into runnable entry points

The goal is to keep machine intent declarative, reusable, and environment-aware instead of hardcoding installation behavior directly in playbooks.

## Architecture Flow

The high-level model is:

```text
Inventory
   ->
Profiles
   ->
Software Catalog
   ->
Resolver Layer
   ->
Execution Plan
   ->
Reusable Roles
   ->
Playbooks
```

This is not just a documentation diagram. It reflects the actual direction of the current Windows implementation, where playbooks compose profile data, shared tasks normalize package metadata, and roles execute reusable behavior.

## Core Layers

### Inventory

Inventories define where automation runs.

Environment inventories live under `inventories/<environment>/`.

Current environments in the repo:

- `sandbox`
- `lab`
- `dev`
- `tst`
- `prd`

Environment intent at a high level:

- `sandbox` is the preferred safe environment for Ansible development and execution during change development.
- `lab` exists for a different operational purpose and is not the default place for day-to-day Ansible change development.
- `dev`, `tst`, and `prd` represent the broader promotion path toward validated and production rollout.

Common patterns:

- `hosts.yml` defines the inventory structure for that environment.
- `group_vars/windows.yml` carries shared Windows connection settings.
- Group-specific files such as `group_vars/uipath_orchestrator.yml` or `group_vars/team_neon.yml` provide targeted overrides.
- `inventories/group_vars/` holds cross-environment defaults.

### Profiles

Profiles define what a machine should contain.

The repository currently uses two main Windows composition styles:

- toolbox playbooks combine a shared base profile, one team profile, and optional inventory-driven overrides
- platform playbooks load one machine profile directly

For toolbox playbooks, the resulting role set is derived from:

```text
base_roles + team_roles + env_add_roles - remove_roles - env_remove_roles
```

Role-layer intent:

- `base_roles` defines the normal baseline software set for that toolbox profile
- `team_roles` adds team-specific software on top of that baseline
- `env_add_roles` supports environment-specific rollout or experimentation
- `env_remove_roles` supports environment-specific exclusion
- `remove_roles` supports narrower removal for a specific machine or host group

For platform playbooks, machine profiles define:

- `machine_roles`
- package lists consumed by those roles
- optional machine-level environment variables via `machine_env`

### Software Catalog

The software catalog defines package metadata independently from role logic.

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

### Resolver Layer

Resolvers determine how installers are obtained and normalized before execution.

The shared Windows resolver path currently centers on:

- `roles/windows/common/tasks/load_software_catalog.yml`
- `roles/windows/common/tasks/resolve_installer.yml`
- `roles/windows/common/tasks/resolve_jfrog.yml`
- `roles/windows/common/tasks/resolve_local.yml`
- `roles/windows/common/tasks/resolve_share.yml`
- `roles/windows/common/tasks/resolve_share_copy.yml`

These helpers let the repository support different source types without forcing each role to embed its own installer-resolution logic.

### Execution Plan

The execution plan turns desired package definitions into normalized installation steps.

In the current Windows path, the common flow is:

```text
requested package keys
   ->
load catalog fragment
   ->
resolve installer metadata
   ->
build normalized package list
   ->
execute installation
   ->
verify installation markers
   ->
apply optional post-install configuration
```

The most important shared execution helpers are:

- `roles/windows/common/tasks/install_from_catalog.yml`
- `roles/windows/common/tasks/execute_plan.yml`
- `roles/windows/common/tasks/add_path.yml`
- `roles/windows/common/tasks/add_env.yml`
- `roles/windows/common/tasks/add_registry.yml`
- `roles/windows/common/tasks/add_certificate.yml`
- `roles/windows/common/tasks/set_windows_env.yml`

### Roles

Roles implement reusable execution behavior.

Representative Windows roles currently present include:

- `certificate`
- `dotnet_hosting`
- `git`
- `iis`
- `iis_url_rewrite`
- `machine_configuration`
- `microsoft_dotnet_framework`
- `microsoft_web_deploy`
- `postman`
- `python`
- `uipath_orchestrator_migration`
- `vscode`

Linux currently includes:

- `gitlab_runner`

Windows roles generally rely on shared resolver and execution helpers instead of duplicating installation logic inside each role.

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

## Playbook Entry Points

Current playbooks:

### Windows toolbox

- `playbooks/windows/toolbox/team_alpha.yml`
- `playbooks/windows/toolbox/team_beta.yml`
- `playbooks/windows/toolbox/team_gamma.yml`
- `playbooks/windows/toolbox/team_neon.yml`

These playbooks compute a final role set from toolbox profile layers. They are currently written in a composition-first style and gate role execution behind `execute_roles`.

Before role execution, they also print the computed composition so an operator can verify the final role set that would be applied. The debug output includes:

- `base_roles`
- `team_roles`
- `env_add_roles`
- `remove_roles`
- `env_remove_roles`
- `final_roles`

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

For toolbox playbooks, the default behavior is useful for verification because it prints the merged composition and the resulting `final_roles`. Pass `execute_roles=true` when you want the playbook to move from composition/debug output into actual role execution.

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

The `verify-roles` job runs the selected playbook in verification mode using:

```text
ansible-playbook -i inventories/<environment>/hosts.yml playbooks/windows/<domain>/<target>.yml
```

For toolbox targets, that verification run also prints the composition debug output, including the computed `final_roles`, so operators can confirm which roles would be applied before enabling execution.

The deploy job runs the same playbook as a manual step, typically with execution enabled where needed.

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
