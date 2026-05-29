# Web API Machine

## Purpose
Hosts .NET applications deployed from GitLab CI/CD pipelines.

## Software
- Git
- Dynatrace OneAgent
- IIS
- IIS URL Rewrite
- .NET Hosting
- Web Deploy
- Request Router

## Secrets
Read from HashiCorp Vault. Path configured per environment in group_vars.

## Scheduled Tasks
Configured via `scheduled_tasks` in inventory group_vars.

## Environments
lab → dev → tst → prd

---

## Backup Guide

Run these steps on the **old machine** before migration.
Store all backup files in a folder named `backup_<hostname>_<date>` on the backup machine.

### Certificate
1. Open Certificate Manager — run `certmgr.msc`
2. Navigate to Certificates → Local Computer → Personal → Certificates
3. Right click each certificate → All Tasks → Export
4. Select "Yes, export the private key"
5. Set a strong password
6. Save as `web_api_ssl_cert.pfx`
7. **Store the password in HashiCorp Vault — do not store it anywhere else**

### Environment Variables
1. Open Registry Editor — run `regedit`
2. Navigate to:
```
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment
```
3. Right click `Environment` → Export
4. Save as `env_variables.reg`

### Server Roles
Run in PowerShell as Administrator:
```powershell
Get-WindowsFeature |
Where-Object { $_.InstallState -eq 'Installed' } |
Select-Object Name |
Export-Csv -Path "C:\sources\web_api_migration\server_roles.csv" -NoTypeInformation
```

### IIS Applications
Run in PowerShell as Administrator:
```powershell
iisreset /stop /force

cd "C:\Program Files\IIS\Microsoft Web Deploy V3"

.\msdeploy.exe -verb:sync `
  -source:webServer `
  "-dest:package='C:\sources\web_api_migration\IIS_Backup.zip',encryptPassword='yourpassword'"

iisreset /start
```
**Store the encrypt password in HashiCorp Vault — do not store it anywhere else**

### Copy To Backup Machine
Copy the following files to `backup_<hostname>_<date>\` on the backup machine:
```
backup_<hostname>_<date>\
  ├── web_api_ssl_cert.pfx
  ├── env_variables.reg
  ├── server_roles.csv
  └── IIS_Backup.zip
```

---

## Migration Guide

### Pre-Migration Checklist
Run through this checklist before triggering the pipeline.

| Step | Description | Done |
|---|---|---|
| Snapshot | Take VM snapshot of new machine before starting | ☐ |
| SSH | Verify connectivity: `ssh username@hostname` | ☐ |
| Backup files | Copy from backup machine to `C:\sources\web_api_migration\` on new machine | ☐ |
| Vault secrets | Confirm secrets exist at correct path for target environment in Vault | ☐ |
| Dynatrace | Verify version and custom properties in `inventories/<env>/group_vars/web_api.yml` | ☐ |

### Backup Files Location On New Machine
All backup files must be at:
```
C:\sources\web_api_migration\
  ├── web_api_ssl_cert.pfx
  ├── env_variables.reg
  ├── server_roles.csv
  └── IIS_Backup.zip
```

### Run The Playbook
```bash
ansible-playbook -i inventories/<env>/hosts.yml \
  playbooks/windows/platform/web_api.yml
```

### Environment Promotion
Always follow this order — never skip environments:
```
lab → dev → tst → prd
```

### Migration Results
- Full migration completed in ~30 minutes
- Server roles restoration ~20 minutes (Windows feature activation time)
- IIS application restore via msdeploy full webserver backup
- Repeatable and idempotent — safe to run multiple times
```

---

