# Infrastructure Automation Platform (Ansible)

## Purpose

This repository contains the **infrastructure automation framework** used to provision and maintain standardized machines across environments using **Ansible**.

The platform provides a structured way to manage:

* Windows toolbox servers
* UiPath automation servers
* Linux GitLab runners
* Standardized developer environments
* Environment-specific infrastructure configuration

The repository follows a **profile-driven automation model**, where machines are defined declaratively using profiles and software catalogs instead of hardcoded playbooks.

The goal is to ensure **consistent, reproducible, and maintainable infrastructure provisioning** across environments.

---

# Platform Architecture

The automation framework is organized around several core layers.

```id="arch-flow"
Inventory
   ↓
Machine Profiles
   ↓
Software Catalog
   ↓
Resolver Layer
   ↓
Execution Plan
   ↓
Reusable Roles
```

### Inventory

Defines **where automation runs**.

Inventories represent environments such as:

* Lab
* Test
* Production

Each inventory contains:

* host definitions
* environment variables
* environment overrides

---

### Machine Profiles

Profiles define **what a machine should contain**.

A machine configuration can be composed from multiple layers:

```id="profile-model"
Base Profile
   + Team Profile
   + Machine Profile
   = Final Machine Configuration
```

This allows different teams to extend shared machine definitions while keeping a common baseline.

---

### Software Catalog

The software catalog defines **software packages and installation metadata**.

Each catalog entry contains:

* installer source
* installation type
* installation arguments
* validation checks

This design separates **software metadata** from **installation logic**.

---

### Resolver Layer

Resolvers determine **how installers are obtained**.

Supported installer sources may include:

* network shares
* artifact repositories
* local installer caches
* copied artifacts

Resolvers allow installation sources to evolve without modifying role logic.

---

### Execution Plan

The execution plan translates the desired machine configuration into installation steps.

```id="execution-flow"
software list
   ↓
resolve installer
   ↓
build execution plan
   ↓
install software
   ↓
verify installation
```

This keeps installation workflows generic and reusable.

---

### Roles

Roles implement the actual configuration logic.

Roles are designed to be **reusable and data-driven**, relying on profile and catalog definitions rather than hardcoded installation steps.

---

# Repository Structure

```id="repo-structure"
inventories/
  lab/                     Lab environment inventory
  prd/                     Production environment structure

playbooks/
  linux_runner.yml         Linux runner provisioning
  windows_toolbox.yml      Windows toolbox server setup
  windows_uipath.yml       UiPath server provisioning

profiles/
  linux/                   Linux machine profiles
  windows/                 Windows machine profiles
  */software_catalog/      Software metadata definitions

roles/
  linux/                   Linux automation roles
  windows/                 Windows automation roles

ansible.cfg                Global Ansible configuration
README.md                  Repository documentation
```

---

# Environments

Automation is executed against environment-specific inventories.

Typical environments include:

| Environment | Purpose                         |
| ----------- | ------------------------------- |
| **lab**     | experimentation and development |
| **test**    | validation before production    |
| **prd**     | production infrastructure       |

Environment configuration is defined under:

```id="env-path"
inventories/<environment>/
```

---

# Running Automation

Automation is executed using standard Ansible commands.

Example:

```id="run-toolbox"
ansible-playbook playbooks/windows_toolbox.yml -i inventories/lab
```

Example for production:

```id="run-prd"
ansible-playbook playbooks/linux_runner.yml -i inventories/prd
```

Execution should always target the appropriate inventory.

---

# Adding a New Machine

To provision a new machine type:

1. Create a **machine profile** under `profiles/<os>/machines/`
2. Define required software packages
3. Reference the profile in a playbook or host group
4. Add the host to the appropriate inventory

---

# Adding New Software

To introduce a new software package:

1. Add an entry to the **software catalog**

Example location:

```id="catalog-path"
profiles/windows/software_catalog/
profiles/linux/software_catalog/
```

2. Define:

* installer source
* installation type
* installation arguments
* validation checks

3. Reference the software key in the relevant machine profile.

---

# Design Principles

The automation framework follows several guiding principles.

### Declarative Configuration

Machines should describe **desired state**, not imperative steps.

---

### Reusable Roles

Roles should remain **generic and reusable**, relying on configuration data instead of embedded logic.

---

### Separation of Concerns

Infrastructure definition, software metadata, and installation logic should remain independent layers.

---

### Environment Isolation

Each environment must remain isolated through dedicated inventories and variables.

---

# Safety Guidelines

To ensure platform stability and security:

* Secrets must **never be stored in the repository**
* Installer sources must come from **approved internal locations**
* Production inventory changes require **peer review**
* New software definitions must include **verification checks**

---

# Contribution Guidelines

When contributing changes:

1. Follow the existing repository structure
2. Avoid hardcoding installation logic inside playbooks
3. Prefer catalog-driven software definitions
4. Validate changes in **lab or test environments** before production usage
5. Submit changes through the standard review process

---

# Status

This repository represents the **automation platform used to standardize machine provisioning** across environments.

The platform will continue evolving to support:

* additional machine types
* improved software catalog models
* enhanced installer resolution mechanisms
* CI/CD integration for automation workflows


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
