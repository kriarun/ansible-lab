# Machine Profile Examples

This document shows common patterns for machine-specific configuration under:

```text
profiles/windows/machines/
```

## Machine Roles

Use `machine_roles` when a role should apply only to one machine profile.

```yaml
machine_roles:
  - git
  - python
```

## Package Lists

Machine profiles can define the package versions consumed by roles.

```yaml
git_packages:
  - git_2_44_0

python_packages:
  - python_3_13_2
```

## Machine-Level Environment Variables

Use `machine_env` when you want to configure Windows machine-level environment variables from the profile.

```yaml
machine_env:
  enabled: true
  variables:
    APP_MODE: production
    API_URL: https://alpha
```

This is useful for values that belong to the machine profile rather than a single software package.

Examples:

- application mode
- endpoint URLs
- organization-specific machine settings

## Complete Example

```yaml
machine_roles:
  - git
  - python

git_packages:
  - git_2_44_0

python_packages:
  - python_3_13_2

machine_env:
  enabled: true
  variables:
    APP_MODE: production
    GIT_HOME: "C:\\Program Files\\Git"
    API_URL: https://alpha

debug_mode: true
installer_cache_dir: "C:\\Temp\\ansible\\installers"
```
