# Machine Profile Examples

This document shows common profile patterns used in the repository today.

There are two main Windows profile areas:

```text
profiles/windows/toolbox/
profiles/windows/machines/
```

## Toolbox Base Profile

Use `base_roles` for roles that should apply to most toolbox machines.
This is the normal place for baseline toolbox software that should be present broadly across that toolbox type.

Example:

```yaml
base_roles:
  - git
  - vscode
  - postman

vscode_packages:
  - vscode_1_87_0
```

## Toolbox Team Profile

Use `team_roles` and package variables for team-specific additions.

Example:

```yaml
team_roles:
  - dotnet_hosting

dotnet_hosting_packages:
  - dotnet-hosting-8.0.13-win

debug_mode: true
installer_cache_dir: "C:\\Temp\\ansible\\installers"
```

## Inventory-Driven Toolbox Overrides

Environment inventory vars can extend or trim toolbox composition.

Example:

```yaml
env_add_roles:
  - iis_url_rewrite

iis_url_rewrite_packages:
  - iis-url-rewrite-v2
```

The toolbox playbooks combine:

```text
base_roles + team_roles + env_add_roles - remove_roles - env_remove_roles
```

Practical meaning of these variables:

- `base_roles`: baseline toolbox software that should usually be present everywhere for that toolbox profile
- `team_roles`: extra roles needed only by a specific team profile
- `env_add_roles`: roles added only in a specific environment such as `sandbox`, `dev`, or `lab` to make rollout easier and safer
- `env_remove_roles`: roles removed only in a specific environment when that environment should temporarily or permanently exclude them
- `remove_roles`: roles removed for a narrower target such as a specific machine or host group without changing shared profile files

This layering makes it easier to promote changes gradually. A role can be introduced first in `sandbox`, later added in `dev` or `tst`, and only then become part of the broader default model.

## Machine Profile

Use `machine_roles` for platform machines that are defined directly by one machine profile.

Example:

```yaml
machine_roles:
  - certificate
  - microsoft_dotnet_framework
  - iis
  - dotnet_hosting
  - iis_url_rewrite
  - microsoft_web_deploy
  - uipath_orchestrator_migration

dotnet_hosting_packages:
  - dotnet-hosting-8.0.13-win

iis_url_rewrite_packages:
  - iis-url-rewrite-v2
```

## Machine-Level Environment Variables

Use `machine_env` when environment variables belong to the machine profile rather than to one software package.

Example:

```yaml
machine_env:
  enabled: true
  variables:
    APP_MODE: production
    API_URL: https://alpha
```

This is applied through the `machine_configuration` role.

## Minimal Platform Machine Example

```yaml
machine_roles:
  - git

git_packages:
  - git_2_44_0

machine_env:
  enabled: true
  variables:
    APP_MODE: production
    API_URL: https://alpha
```

## Notes

- Keep package version selection in the profile, not in the role.
- Use toolbox profiles for shared and team-composed machines.
- Use machine profiles for platform machines with a direct role list.
- Use inventory `group_vars` only for environment-specific overrides, not as the main source of machine intent.
- Treat `sandbox` as the preferred Ansible development environment when changes need to be executed safely before wider rollout.
