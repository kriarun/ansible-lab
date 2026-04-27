# Add A Role

Use this guide when you want to add a new role to the automation platform.

The current repository has two different role patterns:

- Windows roles usually install catalog-defined packages through shared common tasks.
- Linux roles are currently much lighter and may still be debug-oriented.

## 1. Choose The Role Scope

Decide whether the role belongs under:

- `roles/windows/<role_name>/`
- `roles/linux/<role_name>/`

Most new install-oriented work in this repo will currently be a Windows role.

## 2. Create The Role Task File

Create:

```text
roles/windows/<role_name>/tasks/main.yml
```

Example:

```text
roles/windows/git/tasks/main.yml
```

## 3. Follow The Current Windows Pattern

Most Windows roles call the shared installer helper rather than duplicating resolver logic.

Example:

```yaml
- name: Install Git packages
  ansible.builtin.include_tasks: ../../common/tasks/install_from_catalog.yml
  vars:
    software_catalog_entry: git.yml
    software_package_list: "{{ git_packages | default([]) }}"
    software_role_name: git
```

This keeps package resolution and installation behavior consistent across roles.

## 4. Add The Matching Software Catalog Fragment

If the role installs software, create or update the catalog fragment under:

```text
profiles/windows/software_catalog/
```

Example:

```text
profiles/windows/software_catalog/git.yml
```

The file should contain the package keys referenced by the role.

## 5. Define The Package List In A Profile

Profiles provide the package list consumed by the role.

Examples:

```yaml
git_packages:
  - git_2_44_0
```

Depending on the use case, define that variable in:

- `profiles/windows/toolbox/base.yml`
- `profiles/windows/toolbox/team_<name>.yml`
- `profiles/windows/machines/<machine>.yml`

## 6. Attach The Role To The Right Profile Layer

Choose the profile variable that matches the composition style.

For toolbox:

```yaml
base_roles:
  - git
  - vscode
```

or:

```yaml
team_roles:
  - dotnet_hosting
```

For platform machines:

```yaml
machine_roles:
  - git
```

## 7. Reuse Common Tasks For Extra Configuration

If the software needs PATH entries, environment variables, registry values, or certificates, prefer the shared helpers already used by the execution layer instead of adding special-case task logic inside the role.

Relevant helpers live under:

```text
roles/windows/common/tasks/
```

## 8. Run A Relevant Playbook

Examples:

```powershell
ansible-playbook -i inventories/lab/hosts.yml playbooks/windows/platform/uipath_test_manager.yml
ansible-playbook -i inventories/sandbox/hosts.yml playbooks/windows/toolbox/team_neon.yml -e "execute_roles=true"
```

Pick the playbook that actually consumes the profile layer you changed.

## Notes

- Keep installer source details in the software catalog, not in the role.
- Prefer `install_from_catalog.yml` unless there is a clear reason not to.
- Keep role names aligned with the package variable they consume, for example `git` and `git_packages`.
- If you add a Windows role with machine-level environment settings, consider whether `machine_configuration` should remain separate from the software-install role.
