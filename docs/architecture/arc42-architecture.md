# arc42 Architecture Overview

## 1. Introduction And Goals

This repository provides an Ansible-based automation platform for provisioning and maintaining standardized machines across environments.

The current implementation focuses on:

- Windows toolbox machines
- Windows UiPath platform machines
- Linux GitLab runner machines

Primary goals:

- keep machine intent in profiles instead of playbooks
- keep software metadata in a catalog instead of roles
- reuse installation logic through shared task fragments
- preserve environment isolation through dedicated inventories
- support repeatable execution from GitLab CI/CD

## 2. Constraints

The codebase currently reflects these constraints:

- Ansible is the orchestration engine.
- Windows automation is the most mature path.
- Toolbox and platform playbooks use different profile-composition patterns.
- Linux exists, but is still lighter and more debug-oriented than Windows.
- GitLab CI/CD is modeled through a starter pipeline in [`.gitlab-ci.yml`](../../.gitlab-ci.yml).

## 3. Scope And Context

### Business Context

The platform sits between infrastructure intent and machine execution.

Key actors and systems:

- infrastructure engineers maintaining inventories, profiles, roles, and catalog entries
- GitLab CI/CD jobs invoking playbooks
- Windows and Linux target hosts
- software sources such as local paths, JFrog, and file shares

### Technical Context

The common Windows flow is:

1. select hosts from an environment inventory
2. load profile data
3. compute `final_roles`
4. resolve software metadata from catalog fragments
5. normalize installer details
6. execute installation tasks
7. apply optional post-install configuration such as PATH, env vars, registry, or certificates

## 4. Solution Strategy

The design is based on separation of concerns:

- inventories define where automation runs
- profiles define what a machine should contain
- software catalog entries define how packages are installed
- roles define reusable behavior
- common task files implement shared resolution and execution logic

Another important strategy is progressive composition:

- toolbox playbooks combine base, team, and environment layers
- platform playbooks load one machine profile directly
- common Windows helpers turn heterogeneous package definitions into a normalized install plan

## 5. Building Block View

### Level 1

The top-level building blocks are:

- `inventories/`
- `playbooks/`
- `profiles/`
- `roles/`
- `docs/`
- [`.gitlab-ci.yml`](../../.gitlab-ci.yml)

### Level 2

#### Inventories

Inventories define host groups and environment-specific settings.

Current environment directories:

- `inventories/dev/`
- `inventories/lab/`
- `inventories/prd/`
- `inventories/sandbox/`
- `inventories/tst/`

Current environment intent:

- `sandbox` is the primary safe environment for Ansible development and execution during change development.
- `lab` exists for a different purpose and is not the preferred place to develop and trial normal Ansible changes.
- other environments support the broader promotion path toward validated and production rollout.

Common files:

- [inventories/group_vars/all.yml](../../inventories/group_vars/all.yml)
- [inventories/lab/hosts.yml](../../inventories/lab/hosts.yml)
- [inventories/dev/hosts.yml](../../inventories/dev/hosts.yml)
- [inventories/prd/hosts.yml](../../inventories/prd/hosts.yml)
- [inventories/lab/group_vars/windows.yml](../../inventories/lab/group_vars/windows.yml)

Important current groups include:

- `team_alpha`
- `team_beta`
- `team_gamma`
- `team_neon`
- `uipath_orchestrator`
- `uipath_test_manager`
- `linux_gitlab_runner`

#### Playbooks

Playbooks are the top-level entry points.

Current playbooks:

- [playbooks/windows/toolbox/team_alpha.yml](../../playbooks/windows/toolbox/team_alpha.yml)
- [playbooks/windows/toolbox/team_beta.yml](../../playbooks/windows/toolbox/team_beta.yml)
- [playbooks/windows/toolbox/team_gamma.yml](../../playbooks/windows/toolbox/team_gamma.yml)
- [playbooks/windows/toolbox/team_neon.yml](../../playbooks/windows/toolbox/team_neon.yml)
- [playbooks/windows/platform/uipath_orchestrator.yml](../../playbooks/windows/platform/uipath_orchestrator.yml)
- [playbooks/windows/platform/uipath_test_manager.yml](../../playbooks/windows/platform/uipath_test_manager.yml)
- [playbooks/linux/gitlab_runner.yml](../../playbooks/linux/gitlab_runner.yml)

Observed patterns:

- toolbox playbooks load `base.yml` plus one team profile and compute a merged role list
- platform playbooks load one machine profile and execute its `machine_roles`
- Linux currently uses a direct vars-file pattern

#### Profiles

Profiles are the declarative source of desired state.

Windows profile areas:

- `profiles/windows/toolbox/`
- `profiles/windows/machines/`
- `profiles/windows/software_catalog/`

Linux profile areas:

- `profiles/linux/machines/`
- `profiles/linux/software_catalog.yml`

Representative files:

- [profiles/windows/toolbox/base.yml](../../profiles/windows/toolbox/base.yml)
- [profiles/windows/toolbox/team_alpha.yml](../../profiles/windows/toolbox/team_alpha.yml)
- [profiles/windows/machines/uipath_orchestrator.yml](../../profiles/windows/machines/uipath_orchestrator.yml)
- [profiles/windows/machines/uipath_test_manager.yml](../../profiles/windows/machines/uipath_test_manager.yml)
- [profiles/linux/machines/gitlab_runner.yml](../../profiles/linux/machines/gitlab_runner.yml)

#### Roles

Roles implement execution behavior.

Windows roles currently present include:

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

Linux roles currently present include:

- `gitlab_runner`

#### Common Windows Tasks

The most important shared Windows task fragments are:

- [roles/windows/common/tasks/load_software_catalog.yml](../../roles/windows/common/tasks/load_software_catalog.yml)
- [roles/windows/common/tasks/install_from_catalog.yml](../../roles/windows/common/tasks/install_from_catalog.yml)
- [roles/windows/common/tasks/resolve_installer.yml](../../roles/windows/common/tasks/resolve_installer.yml)
- [roles/windows/common/tasks/resolve_jfrog.yml](../../roles/windows/common/tasks/resolve_jfrog.yml)
- [roles/windows/common/tasks/resolve_local.yml](../../roles/windows/common/tasks/resolve_local.yml)
- [roles/windows/common/tasks/resolve_share.yml](../../roles/windows/common/tasks/resolve_share.yml)
- [roles/windows/common/tasks/resolve_share_copy.yml](../../roles/windows/common/tasks/resolve_share_copy.yml)
- [roles/windows/common/tasks/execute_plan.yml](../../roles/windows/common/tasks/execute_plan.yml)
- [roles/windows/common/tasks/add_path.yml](../../roles/windows/common/tasks/add_path.yml)
- [roles/windows/common/tasks/add_env.yml](../../roles/windows/common/tasks/add_env.yml)
- [roles/windows/common/tasks/add_registry.yml](../../roles/windows/common/tasks/add_registry.yml)
- [roles/windows/common/tasks/add_certificate.yml](../../roles/windows/common/tasks/add_certificate.yml)
- [roles/windows/common/tasks/set_windows_env.yml](../../roles/windows/common/tasks/set_windows_env.yml)

### Level 3: Core Internal Flow

The shared Windows package-install path is:

1. load or merge the catalog fragment
2. validate the requested package key
3. normalize source metadata into `resolved_item`
4. collect normalized entries into `resolved_packages`
5. acquire or validate installer location
6. run the package installation
7. verify installation markers
8. apply optional post-install configuration

## 6. Runtime View

### Scenario 1: Toolbox Composition

Observed from the toolbox playbooks:

1. target one team group such as `team_alpha`
2. load [profiles/windows/toolbox/base.yml](../../profiles/windows/toolbox/base.yml)
3. load a team profile such as [profiles/windows/toolbox/team_alpha.yml](../../profiles/windows/toolbox/team_alpha.yml)
4. merge `base_roles`, `team_roles`, and `env_add_roles`
5. subtract `remove_roles` and `env_remove_roles`
6. expose the result as `final_roles`
7. optionally execute those roles when `execute_roles=true`

Meaning of the layering:

- `base_roles` carries the baseline toolbox software set
- `team_roles` carries team-specific additions
- `env_add_roles` supports environment-specific rollout or experimentation
- `env_remove_roles` supports environment-specific exclusion
- `remove_roles` supports more targeted removal for a machine or group

### Scenario 2: UiPath Platform Machine Provisioning

Observed from the platform playbooks:

1. target `uipath_orchestrator` or `uipath_test_manager`
2. load one machine profile from `profiles/windows/machines/`
3. compute `final_roles` from `machine_roles`
4. include the corresponding Windows roles
5. allow machine-level environment settings through `machine_configuration`

### Scenario 3: Catalog-Driven Package Installation

Observed mainly from [install_from_catalog.yml](../../roles/windows/common/tasks/install_from_catalog.yml):

1. validate `software_catalog_entry` and `software_package_list`
2. initialize `resolved_packages`
3. resolve each requested package key through the catalog
4. execute the installation plan for each resolved package
5. emit debug information when `debug_mode=true`

### Scenario 4: GitLab Pipeline Execution

The current pipeline model is:

1. choose `environment`
2. choose `domain`
3. choose `target`
4. run syntax-check for the selected Windows playbook
5. manually deploy the same playbook

## 7. Deployment View

The current deployment model is straightforward:

- repository content is version-controlled in Git
- Ansible runs from an operator workstation or CI runner
- target hosts are selected by inventory
- installer binaries are resolved from supported source types

The starter pipeline suggests a staged model with:

- `codestyle`
- `verify`
- `fetch-secrets`
- `deploy`

## 8. Crosscutting Concepts

### Declarative Configuration

Profiles and catalog entries describe desired state rather than hardcoding workflow details in playbooks.

### Reuse Through Shared Tasks

Windows package handling is centralized through reusable helpers instead of repeated role-specific logic.

### Normalized Package Model

Resolvers convert different source definitions into a normalized structure consumed by `execute_plan.yml`.

### Verification By Marker

Install success is typically checked through `install.check.path_exists`.

### Environment Layering

Inventories carry environment-specific overrides, while profiles carry machine intent.

## 9. Architecture Decisions

Important visible decisions include:

- use multiple playbooks instead of one monolithic entry point
- split toolbox and platform composition styles
- store Windows software metadata in catalog fragments
- centralize installation flow in `install_from_catalog.yml`
- keep the CI model parameterized but simple

## 10. Quality Goals

The main quality goals are:

- maintainability through reuse
- extensibility through catalog-driven package definitions
- traceability through explicit role composition
- environment isolation through inventory separation
- operational clarity through playbook-level entry points

## 11. Risks And Technical Debt

Current gaps visible in the repo:

- Windows roles are at different maturity levels.
- Toolbox playbooks and platform playbooks are not yet fully unified.
- Linux automation is still much less developed than Windows.
- The CI/CD pipeline is a starter implementation, not a finished operating model.
- Some docs and code paths still reflect an earlier debug-focused phase of the project.

## 12. Glossary

- inventory: environment and host definition used by Ansible
- profile: declarative machine intent stored in YAML
- software catalog: installation metadata for packages
- resolver: logic that turns source metadata into executable installer details
- resolved package: normalized structure used by the execution layer
- role: reusable Ansible unit that applies part of the machine configuration
