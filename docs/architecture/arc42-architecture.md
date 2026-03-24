# arc42 Architecture Overview

## 1. Introduction and Goals

This repository provides an Ansible-based automation platform for provisioning and maintaining standardized machines across environments.

The current focus is on:

- Windows toolbox servers
- Windows UiPath-related machines
- Linux GitLab runner machines

The main architectural goal is to keep machine provisioning declarative and data-driven.

Desired outcomes:

- machine definitions live in profiles, not playbooks
- software installation metadata lives in a software catalog
- execution logic stays reusable through shared roles and task fragments
- inventories remain environment-specific
- future CI/CD execution can trigger playbooks consistently from GitLab

## 2. Architecture Constraints

The current implementation shows several practical constraints:

- Ansible is the orchestration engine.
- Windows automation is the most developed path in the repository today.
- Playbooks are organized per machine category, not as a single universal playbook.
- Profiles are layered differently for toolbox and machine-specific flows.
- Software metadata is split into YAML fragments under the Windows software catalog directory.
- The intended future execution path is GitLab CI/CD, currently represented by a starter [`.gitlab-ci.yml`](c:/Arun/Learning/Anisble/ansible-lab/.gitlab-ci.yml).

## 3. System Scope and Context

### Business Context

The platform sits between infrastructure intent and machine execution.

Main actors and systems:

- infrastructure engineers maintaining profiles, roles, and catalog entries
- GitLab CI/CD, expected to trigger playbook execution in future
- target Windows and Linux machines
- artifact sources such as local folders, JFrog, and network shares

### Technical Context

The technical flow for Windows is:

1. inventory selects target hosts
2. playbook loads profile variables
3. playbook computes final roles
4. included roles resolve software metadata from the catalog
5. common tasks resolve installer source details
6. installation tasks execute package installation
7. optional post-install tasks configure PATH, environment variables, registry, and certificates

## 4. Solution Strategy

The central strategy is separation of concerns:

- inventories define where automation runs
- profiles define what a machine should contain
- software catalog entries define how software is sourced and installed
- roles define reusable execution behavior
- common tasks implement shared resolver and configuration logic

A second strategy is progressive abstraction:

- machine and toolbox playbooks compose roles from profile data
- roles consume package keys such as `git_packages` or `python_packages`
- `resolve_installer.yml` converts catalog metadata into normalized `resolved_item` structures
- `execute_plan.yml` performs installation and verification from that normalized structure

## 5. Building Block View

### Level 1

The major building blocks are:

- `inventories/`
- `playbooks/`
- `profiles/`
- `roles/`
- `docs/`
- [`.gitlab-ci.yml`](c:/Arun/Learning/Anisble/ansible-lab/.gitlab-ci.yml)

### Level 2

#### Inventories

Inventories define host groups and environment-specific variables.

Examples:

- [hosts.yml](c:/Arun/Learning/Anisble/ansible-lab/inventories/lab/hosts.yml)
- [all.yml](c:/Arun/Learning/Anisble/ansible-lab/inventories/lab/group_vars/all.yml)
- [toolbox_servers.yml](c:/Arun/Learning/Anisble/ansible-lab/inventories/prd/group_vars/toolbox_servers.yml)

Important current groups include:

- `toolbox_servers`
- `team_toolbox_alpha`
- `uipath_orchestrator`
- `uipath_test_manager`
- `linux_gitlab_runner`

#### Playbooks

Playbooks are the top-level orchestration entry points.

- [windows_toolbox.yml](c:/Arun/Learning/Anisble/ansible-lab/playbooks/windows_toolbox.yml)
- [windows_uipath.yml](c:/Arun/Learning/Anisble/ansible-lab/playbooks/windows_uipath.yml)
- [linux_runner.yml](c:/Arun/Learning/Anisble/ansible-lab/playbooks/linux_runner.yml)

Observed patterns:

- toolbox flow layers `base.yml` plus optional team blueprint variables
- UiPath flow loads a machine profile directly
- Linux flow currently uses a different variable path pattern and appears less aligned with the Windows structure

#### Profiles

Profiles are the declarative source of desired machine state.

Windows profile areas:

- `profiles/windows/toolbox/`
- `profiles/windows/machines/`
- `profiles/windows/software_catalog/`

Current examples:

- [base.yml](c:/Arun/Learning/Anisble/ansible-lab/profiles/windows/toolbox/base.yml)
- [team_alpha.yml](c:/Arun/Learning/Anisble/ansible-lab/profiles/windows/toolbox/team_alpha.yml)
- [uipath_orchestrator.yml](c:/Arun/Learning/Anisble/ansible-lab/profiles/windows/machines/uipath_orchestrator.yml)
- [uipath_test_manager.yml](c:/Arun/Learning/Anisble/ansible-lab/profiles/windows/machines/uipath_test_manager.yml)
- [misc.yml](c:/Arun/Learning/Anisble/ansible-lab/profiles/windows/software_catalog/misc.yml)

#### Roles

Roles implement machine behavior, mostly through reusable common tasks.

Windows roles:

- `common`
- `git`
- `python`
- `vscode`
- `dotnet`
- `postman`
- `machine_configuration`

Role maturity is uneven:

- `python` is the most complete role pattern today
- `git` and `vscode` currently resolve and debug, but do not yet perform the full install flow
- `dotnet` is still placeholder/debug-oriented
- `postman` is present but currently empty

#### Common Windows Tasks

The key reusable task components are:

- [load_software_catalog.yml](c:/Arun/Learning/Anisble/ansible-lab/roles/windows/common/tasks/load_software_catalog.yml)
- [resolve_installer.yml](c:/Arun/Learning/Anisble/ansible-lab/roles/windows/common/tasks/resolve_installer.yml)
- [resolve_jfrog.yml](c:/Arun/Learning/Anisble/ansible-lab/roles/windows/common/tasks/resolve_jfrog.yml)
- [resolve_local.yml](c:/Arun/Learning/Anisble/ansible-lab/roles/windows/common/tasks/resolve_local.yml)
- [resolve_share.yml](c:/Arun/Learning/Anisble/ansible-lab/roles/windows/common/tasks/resolve_share.yml)
- [resolve_share_copy.yml](c:/Arun/Learning/Anisble/ansible-lab/roles/windows/common/tasks/resolve_share_copy.yml)
- [execute_plan.yml](c:/Arun/Learning/Anisble/ansible-lab/roles/windows/common/tasks/execute_plan.yml)
- [acquire_jfrog.yml](c:/Arun/Learning/Anisble/ansible-lab/roles/windows/common/tasks/acquire_jfrog.yml)
- [add_path.yml](c:/Arun/Learning/Anisble/ansible-lab/roles/windows/common/tasks/add_path.yml)
- [configure_environment_variables.yml](c:/Arun/Learning/Anisble/ansible-lab/roles/windows/common/tasks/configure_environment_variables.yml)
- [add_registry.yml](c:/Arun/Learning/Anisble/ansible-lab/roles/windows/common/tasks/add_registry.yml)

### Level 3: Core Internal Flow

The Windows software flow can be understood as these internal stages:

1. merge software catalog fragments into `software_catalog`
2. validate the requested software key
3. normalize source metadata into `resolved_item`
4. append normalized package data into `resolved_packages`
5. check installation marker
6. download or validate installer location
7. install package
8. verify installation marker
9. apply optional PATH, environment, registry, or certificate configuration

## 6. Runtime View

### Scenario 1: Toolbox Provisioning

Observed from [windows_toolbox.yml](c:/Arun/Learning/Anisble/ansible-lab/playbooks/windows_toolbox.yml):

1. target `toolbox_servers`
2. load `profiles/windows/toolbox/base.yml`
3. optionally load `team_alpha.yml` if the host belongs to `team_toolbox_alpha`
4. compute `final_roles` using `base_roles + team_roles - remove_roles`
5. include each role under `roles/windows/<role>`

### Scenario 2: UiPath Machine Provisioning

Observed from [windows_uipath.yml](c:/Arun/Learning/Anisble/ansible-lab/playbooks/windows_uipath.yml):

1. target `uipath_orchestrator`
2. load machine profile variables
3. compute `final_roles` from `machine_roles`
4. include each role
5. optionally apply machine-level environment variables through `machine_configuration`

### Scenario 3: Package Resolution and Install

Observed mainly from [resolve_installer.yml](c:/Arun/Learning/Anisble/ansible-lab/roles/windows/common/tasks/resolve_installer.yml) and [execute_plan.yml](c:/Arun/Learning/Anisble/ansible-lab/roles/windows/common/tasks/execute_plan.yml):

1. ensure the software catalog is loaded
2. assert that the catalog entry exists and is structurally valid
3. route to a resolver based on `source.type`
4. produce a normalized `resolved_item`
5. check the install marker
6. acquire or validate the installer
7. install with `ansible.windows.win_package`
8. verify using `path_exists`

### Scenario 4: Future Pipeline Execution

Planned operational flow:

1. GitLab pipeline triggers a job
2. job selects one playbook
3. job selects one inventory target
4. Ansible executes the chosen playbook
5. results are reviewed per playbook/job

## 7. Deployment View

The current deployment view is simple:

- repository content is version-controlled in Git
- Ansible runs from a control environment or future GitLab runner
- target hosts are organized in inventory groups
- installer binaries come from one of several supported source types

Likely deployment units:

- GitLab runner or operator workstation
- Windows managed nodes
- Linux managed nodes
- JFrog or network share artifact source

The starter pipeline in [`.gitlab-ci.yml`](c:/Arun/Learning/Anisble/ansible-lab/.gitlab-ci.yml) suggests a two-stage model:

- `validate`
- `deploy`

with one manual deploy job per playbook.

## 8. Crosscutting Concepts

### Declarative Configuration

Profiles and catalog entries describe desired state and installation metadata.

### Reuse Through Task Fragments

Common task files centralize repeated behaviors such as:

- source resolution
- installation execution
- PATH configuration
- environment-variable configuration
- registry changes

### Normalized Package Model

Resolvers convert heterogeneous catalog entries into a normalized `resolved_item` structure used by executors.

### Verification by Marker

Installation success is currently validated through `install.check.path_exists`.

### Environment Layering

Environment-specific variables come from inventories, while machine intent comes from profiles.

## 9. Architecture Decisions

Important decisions visible in the codebase today:

- use multiple top-level playbooks instead of one monolithic playbook
- compose machine behavior from profile-defined role lists
- keep software source metadata outside roles
- merge software catalog fragments at runtime
- route installer handling by `source.type`
- keep the GitLab CI model simple at first with one job per playbook

## 10. Quality Requirements

Key quality goals inferred from the repository:

- maintainability through role and task reuse
- extensibility through catalog-driven package definitions
- traceability through explicit profile composition and debug output
- safety through pre-validation and post-install verification
- operational clarity through playbook-level separation

## 11. Risks and Technical Debt

The codebase also shows several current risks and transitional areas:

- Windows roles are at different maturity levels.
- The Linux path currently uses a different variable structure than the Windows profile model.
- `windows_uipath.yml` currently targets only `uipath_orchestrator`, while another machine profile is present but commented out.
- `resolve_share.yml` and `resolve_share_copy.yml` do not yet align fully with the normalized install structure used elsewhere.
- Side-by-side installation conflicts are not yet modeled for software such as Git or Chrome.
- The current installation verification uses only file-path markers and may need richer checks later.
- CI/CD integration is currently a draft and not yet validated in a real GitLab environment.

## 12. Glossary

- inventory: Ansible host and environment definition
- profile: YAML-based machine intent definition
- software catalog: package metadata and install-source definition
- resolver: logic that converts source metadata into executable installer details
- resolved item: normalized package structure consumed by the installer execution flow
- role: reusable Ansible unit that applies part of the machine configuration
