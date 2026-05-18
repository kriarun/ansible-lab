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

## Migration
One-time activity. Restores from backup taken on old machine.
Backups must be pre-staged at `C:\Migration\Backup` before running.

## Scheduled Tasks
Configured via `scheduled_tasks` in inventory group_vars.

## Secrets
Read from HashiCorp Vault. Path configured per environment in group_vars.

## Environments
lab → dev → tst → prd