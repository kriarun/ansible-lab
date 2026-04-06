# Add a Role

Use this guide when you want to add a new Windows role such as `git`, `python`, or `dotnet`.

## 1. Create the role folder

Create a task file for the new role:

```text
roles/windows/<role_name>/tasks/main.yml
```

Example:

```text
roles/windows/git/tasks/main.yml
```

## 2. Define the role logic

Keep the role data-driven. The role should consume package keys from profiles instead of hardcoding installer details.

Example:

```yaml
- name: Initialize resolved list
  ansible.builtin.set_fact:
    resolved_packages: []

- name: Resolve packages
  ansible.builtin.include_tasks: ../../common/tasks/resolve_installer.yml
  loop: "{{ git_packages }}"
  loop_control:
    loop_var: software_key

- name: Execute installation plan
  ansible.builtin.include_tasks: ../../common/tasks/execute_plan.yml
  loop: "{{ resolved_packages }}"
  loop_control:
    loop_var: pkg
```

## 3. Define the role variable in a profile

Add the package list expected by the role in a profile file.

Example:

```yaml
git_packages:
  - git_2_44_0
```

## 4. Attach the role to a profile

Choose the correct profile layer:

- `base_roles` for shared roles used by many machines
- `team_roles` for team-specific roles
- `machine_roles` for machine-specific roles

Examples:

```yaml
base_roles:
  - git
  - vscode
```

```yaml
team_roles:
  - dotnet_hosting
```

```yaml
machine_roles:
  - git
```

## 5. Run the playbook

Run the playbook that targets the machine type:

```powershell
ansible-playbook playbooks/windows_toolbox.yml -i inventories/lab
```

## Notes

- Keep installer source details in the software catalog, not in the role.
- Reuse common tasks such as `resolve_installer.yml`, `execute_plan.yml`, `add_path.yml`, and environment-variable tasks where possible.
- Prefer adding new behavior in reusable common tasks instead of embedding special-case logic in one role.
