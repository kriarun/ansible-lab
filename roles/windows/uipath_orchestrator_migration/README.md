# UiPath Orchestrator Migration Role

This role installs and configures UiPath Orchestrator on Windows by combining the former orchestrator and migration flows into a single role:

```text
roles/windows/uipath_orchestrator_migration
```

It is designed to run from the `uipath_orchestrator` inventory group through:

```text
playbooks/windows/platform/uipath_orchestrator.yml
```

## Entry Points

- Machine blueprint: [profiles/windows/machines/uipath_orchestrator.yml](/c:/Users/kriar/Downloads/ansible-lab-uipath-skeleton/profiles/windows/machines/uipath_orchestrator.yml:1)
- Inventory variables: [inventories/lab/group_vars/uipath_orchestrator.yml](/c:/Users/kriar/Downloads/ansible-lab-uipath-skeleton/inventories/lab/group_vars/uipath_orchestrator.yml:1)
- Software catalog: [profiles/windows/software_catalog/uipath.yml](/c:/Users/kriar/Downloads/ansible-lab-uipath-skeleton/profiles/windows/software_catalog/uipath.yml:1)
- Playbook: [playbooks/windows/platform/uipath_orchestrator.yml](/c:/Users/kriar/Downloads/ansible-lab-uipath-skeleton/playbooks/windows/platform/uipath_orchestrator.yml:1)

## Role Order

The machine blueprint currently executes these Windows roles in order:

1. `certificate`
2. `microsoft_dotnet_framework`
3. `iis`
4. `dotnet_hosting`
5. `iis_url_rewrite`
6. `microsoft_web_deploy`
7. `uipath_orchestrator_migration`

This means the machine gets the certificate and Windows prerequisites before UiPath installation starts.

## Variables Used

The role expects these top-level inventory variables:

- `uipath_orchestrator_packages`
- `ssl_certificate`
- `uipath_runtime`
- `uipath_orchestrator_install_config`
- `uipath_database_settings`
- `uipath_app_settings`
- `uipath_secure_app_settings`

Inside the role, some values are normalized into compatibility variables such as `uipath_cert`, `uipath_db`, `uipath_ta`, `uipath_apppool`, and `uipath_admin` so the task files and software catalog can share the same data.

## Installation Flow

The main task file is [tasks/main.yml](/c:/Users/kriar/Downloads/ansible-lab-uipath-skeleton/roles/windows/uipath_orchestrator_migration/tasks/main.yml:1).

It currently runs in this order:

1. Validate required inventory variables.
2. Normalize inventory variable names used by the role and software catalog.
3. Include `fetch_certificate.yml`.
4. Include `external_validation.yml`.
5. Include `install_orchestrator.yml`.
6. Stop IIS through `iis.yml`.
7. Include `uipath_orchestrator_dll_configuration.yml`.
8. Include `appsettings_production_configuration.yml`.
9. Include `resourcecatalog_appsettings_production_configuration.yml`.
10. Include `webhooks_appsettings_production_configuration.yml`.
11. Start IIS through `iis.yml`.

## What Each Stage Does

### `fetch_certificate.yml`

- Reads certificates from the configured Windows certificate store.
- Filters certificates by subject.
- Selects a currently valid certificate.
- Extracts the thumbprint.
- Writes the discovered thumbprint back into `ssl_certificate` and `uipath_cert`.

### `external_validation.yml`

- Validates that runtime SQL settings are present.
- Validates that the Elasticsearch URL is present.
- Waits for SQL TCP connectivity.
- Checks Elasticsearch reachability.
- Connects to SQL Server and confirms the expected database exists.

### `install_orchestrator.yml`

- Reloads the software catalog.
- Resolves each key from `uipath_orchestrator_packages`.
- Executes the shared installation plan from the resolved catalog entries.

The actual UiPath MSI arguments are defined in the software catalog entry `uipath_orchestrator_2024.10.1`.

### Configuration Stage

After installation, the role stops IIS, applies UiPath configuration task files, and starts IIS again.

The configuration task files currently present are:

- [tasks/uipath_orchestrator_dll_configuration.yml](/c:/Users/kriar/Downloads/ansible-lab-uipath-skeleton/roles/windows/uipath_orchestrator_migration/tasks/uipath_orchestrator_dll_configuration.yml:1)
- [tasks/appsettings_production_configuration.yml](/c:/Users/kriar/Downloads/ansible-lab-uipath-skeleton/roles/windows/uipath_orchestrator_migration/tasks/appsettings_production_configuration.yml:1)
- [tasks/resourcecatalog_appsettings_production_configuration.yml](/c:/Users/kriar/Downloads/ansible-lab-uipath-skeleton/roles/windows/uipath_orchestrator_migration/tasks/resourcecatalog_appsettings_production_configuration.yml:1)
- [tasks/webhooks_appsettings_production_configuration.yml](/c:/Users/kriar/Downloads/ansible-lab-uipath-skeleton/roles/windows/uipath_orchestrator_migration/tasks/webhooks_appsettings_production_configuration.yml:1)

At the moment, these files are scaffolds and should be filled in with the final configuration logic.

## Running It

```powershell
ansible-playbook playbooks/windows/platform/uipath_orchestrator.yml -i inventories/lab/hosts.yml
```
