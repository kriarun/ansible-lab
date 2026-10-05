# TODO — ansible-lab / UiPath migration

Open items from the review on 2026-10-01. Fix one at a time; tick the box and note the commit when done.
Priority: **P1** = before any non-lab run · **P2** = before prd / audit · **P3** = cleanup.

---

## Waiting on input

- [ ] **P1 — Add `profiles/windows/jfrog_registry_token.yml`** (missing in this repo copy)
  - `resolve_installer.yml` loads it whenever `jfrog_bearer_token` is not set → every install fails without it.
  - Content (check the spelling — `lookup('evn'),...` will not work):
    ```yaml
    jfrog_bearer_token: "{{ lookup('env', 'JFROG_TOKEN') }}"
    ```
- [ ] **P3 — Add `profiles/windows/software_catalog/kdiff3.yml`** (missing; toolbox only, not UiPath).
- [ ] **P2 — Dynatrace installer per environment**
  - Only `Dynatrace-OneAgent-Windows-1.305.109_TST` exists in `dynatrace.yml`; all env inventories point to it for now. If prd (or others) need a different OneAgent installer/tenant, add a catalog entry and update `dynatrace_packages` in that env.

---

## roles/windows/common

- [ ] **P2 — Remove `run_once: true` from catalog build/merge** — `load_software_catalog.yml`
  - Catalog is rendered with the `template` lookup, so `{{ ... }}` in catalog values is evaluated once with the **first host's** vars and copied to all hosts.
  - Example: two hosts with different `uipath_action_center.fqdn` → host B installs with host A's `HOST_NAME`, silently.
  - Not a problem today (1 Orchestrator per env), but a trap for multi-host plays.
- [ ] **P2 — Hide JFrog token in logs** — `acquire_jfrog.yml`
  - Add `no_log: true` to `Download from JFrog (Bearer token)`.
- [ ] **P2 — Hide secrets in MSI/EXE arguments** — `execute_plan.yml` + `uipath_platform.yml`
  - On the MSI and EXE install tasks: `no_log: "{{ pkg.install.sensitive | default(false) | bool }}"`
  - In `uipath_platform.yml` add `sensitive: true` under `install:` for Orchestrator and Action Center (Action Center args contain `IDENTITY_INSTALLATION_TOKEN`).
- [ ] **P2 — Reject `command-line` install type until implemented** — `resolve_installer.yml`
  - Remove `'command-line'` from the allowed list and delete its validation block. Today it passes validation, installs nothing, then fails as "Installation failed" (misleading).
- [ ] **P3 — Drop `default(omit)` keys from resolver overrides** — `resolve_jfrog.yml`, `resolve_local.yml`, `resolve_share.yml`
  - Delete `path: "{{ sw.path | default(omit) }}"` (and `env:` in jfrog). `omit` only works at module-parameter level; inside a dict it becomes a placeholder string. `sw | combine(...)` already carries `path`/`env` through.
- [ ] **P3 — Delete dead resolver** — `resolve_share_copy.yml` (no longer routed). Also remove its link in `docs/architecture/arc42-architecture.md`.
- [ ] **P3 — Fix copy-paste task names** — last task in `resolve_local.yml` / `resolve_share.yml` says `(jfrog)` → `(local)` / `(share)`.
- [ ] **P3 — `_new_pkg_installed` is set but never read** — `execute_plan.yml`. Keep as the hook for the IIS handler (see below) or remove.

---

## roles/windows/uipath_orchestrator_migration

- [ ] **P2 — IIS restarted 3× per run** — `enable_iis_features.yml`, `post_installation_changes.yml`, `windows_auth_scoped_tasks.yml`
  - Option: `handlers/main.yml` with `Restart IIS`; changing tasks `notify` it; `meta: flush_handlers` before the Windows-auth verification. → one restart, and zero on a no-change re-run.
- [ ] **P3 — Cert lookup index error** — `fetch_thumprint.yml`
  - `valid_certificates[0]` fails with a Jinja index error before the assert runs (expired PFX / subject mismatch). `fetch_certificate.yml` already does it right (newest valid cert, `default('')`, then assert) → switch to it and delete the other.
- [ ] **P3 — Delete empty scaffolds** — `resourcecatalog_appsettings_production_configuration.yml`, `webhooks_appsettings_production_configuration.yml`, `uipath_orchestrator_dll_configuration.yml` (2 lines each, not included). *(`appsettings_production_configuration.yml` already deleted.)*
- [ ] **P3 — Rewrite role `README.md`** — describes a flow (IIS stop/start, appsettings files) that `main.yml` no longer runs. Part of the docs work.
- [ ] **P3 — SQL check wording** — `external_validation.yml` is a connectivity check (`SELECT 1` on `master`), not a "DB exists" check. Fix task names/README text accordingly.

## roles/windows/uipath_action_center

- [ ] **P3 — Readiness wait: drop `ignore_errors: true`**
  - `retries: 12` / `delay: 10` already covers the slow first call. `ignore_errors` only hides the case "MSI succeeded but site never comes up" and moves the failure to the ROPC auth task.

---

## UiPath Storage (package files)

- [x] **Storage scope decided (2026-10-05):** only `Orchestrator-Host\Libraries` (~3 GB) + `Orchestrator-<uuid>\Processes` (~360 MB). Not needed: SystemBuckets (videos), ExecutionMedia, Media, Retention, JobPersistence (→ no suspended jobs at cutover).
- [x] **Host libraries restore automated (2026-10-05):** `restore_host_libraries.yml` after `install_orchestrator`; skips with warning if `uipath_host_libraries_source` is missing.
- [ ] **P2 — Test `restore_host_libraries` in lab** — check that a library downloads from the UI afterwards (confirms inherited permissions are enough).
- [ ] **P3 — Processes: backup only** — restore manually / republish if a robot needs an old version.
- [ ] **P3 — Long-term: move `STORAGE_LOCATION` off C:** (data disk or share) so an OS rebuild never loses package files.

---

## Inventories

- [ ] **P1 — Verify generated values** in `inventories/{dev,tst,sandbox,prd}/group_vars/uipath_orchestrator.yml` (copied from lab on 2026-10-01; env tokens rewritten by pattern — header lists what to check). Dynatrace now points to the `_TST` package in every env (see Dynatrace item above).
- [ ] **P2 — Lab overrides the service account** — `inventories/lab/group_vars/uipath_orchestrator.yml` sets `ansible_user: user` / `ansible_password: lookup('env','user')`, which wins over `windows.yml`. Removed in the other envs; decide for lab.
- [ ] **P3 — `inventories/tst/group_vars/all.yml`** — copy-paste from lab (`ansible_connection: local`, `env_name: lab`).

---

## Docs (to discuss first)

- [ ] Agree structure & audience (colleagues taking over; in repo now, Confluence later → plain Markdown + Mermaid).
- [ ] Candidate set: `docs/uipath-migration/` README (strategy) · runbook (incl. gate: old 2016 node wiped first, rollback = DB restore) · ADRs · known-issues.

---

## Cleanup after UiPath — roles/windows/common (naming + README)

- [ ] **Rename variables to one name per concept** (see table) and use one `_` prefix rule for internals
  | Today | Means | Proposal |
  |---|---|---|
  | `software_catalog_entry` | catalog *file* (`git.yml`) | `catalog_file` |
  | `software_key` | one entry in the catalog | `package_key` |
  | `sw` | raw catalog entry | `_catalog_entry` |
  | `resolved_item` / `_resolved_item_overrides` | entry + resolved paths | `_resolved_pkg` |
  | `resolved_packages` | list to install | `_install_plan` |
  | `source.url` / `source.path` / `source.share_path` | where the installer is | one key, e.g. `source.location` |
- [ ] **Prefix all internal facts with `_`** (`sw`, `source_type`, `jfrog_cache_path`, `directory_name`, `marker_check`, `installer_file` are not) — `set_fact` lives for the whole play, so a stale value from the previous package can leak into the next one.
- [ ] **Group files by stage** — `catalog/`, `resolve/`, `acquire/`, `install/`, `hooks/pre_install/`, `helpers/`; `install_from_catalog.yml` stays the only public entry point.
- [ ] **Merge the 3 env-var helpers** — `add_env.yml`, `configure_environment_variables.yml`, `set_windows_env.yml` (+ env handling in `execute_plan.yml`).
- [ ] **Put the "Expects / Sets" contract header back** at the top of each task file.
- [ ] **Fix typo names** — `fetch_thumprint`, `montoring_mode`, `uipath_ochestrator_*`; role `uipath_orchestrator_migration` uses `uipath_orchestrator_packages`.
- [ ] **Stage-prefixed task names** — `catalog | …`, `resolve | …`, `acquire | …`, `install | …`, `verify | …` so the run log reads like the README diagram.
- [ ] **Remove indirection rather than add it** — fewer include/set_fact hops where possible.
- [ ] **README for common** — one diagram (catalog → resolve → acquire → install → verify), catalog entry schema, "install new software in 3 steps", and one complete worked example (e.g. Git: catalog entry → resolved package → download → install). Merge with `docs/how-to/add-a-software-catalog-entry.md` instead of duplicating.

---

## Done (2026-10-01)

- [x] Vault call: `return_content` / `status_code` moved out of `headers:` — `roles/windows/hashicorp/tasks/main.yml`
- [x] UiPath inventories created for dev / tst / sandbox / prd from lab
- [x] `install.json` template task `no_log: true` — `install_orchestrator.yml` (file is kept on purpose: verified and deleted manually after the run)
- [x] Pre-patch backup keeps first snapshot (`force: no`) — `post_installation_changes.yml`
- [x] Deleted unused `appsettings_production_configuration.yml`
- [x] Added `profiles/windows/software_catalog/dynatrace.yml` (OneAgent 1.305.109 _TST)
- [x] Deleted unused `roles/windows/uipath_orchestrator_migration/tasks/iis.yml`
- [x] Wrote `docs/uipath-orchestrator-migration.md`
