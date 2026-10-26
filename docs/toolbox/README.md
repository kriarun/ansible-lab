# Development Toolbox

A development toolbox is a Windows server assigned to a team. It provides the tools that
team needs for its development work, for example QA, UiPath, AI/ML or OutSystems development.

All software on a toolbox is installed and configured by Ansible:

- **Base tools** are installed on every toolbox. They are listed in
  [`profiles/windows/toolbox/base.yml`](../../profiles/windows/toolbox/base.yml).
- **Team tools** are added on top, depending on what the team needs. Each team has its own
  profile in [`profiles/windows/toolbox/`](../../profiles/windows/toolbox/).

Changes made by hand to installed tools or their configuration are overwritten on the next run.

## Artifactory credentials

Tools that download packages from Artifactory (Maven, npm, pip, NuGet) need your
Artifactory credentials. Add these two **user** environment variables once:

| Variable | Value |
|---|---|
| `ARTIFACTORY_USERNAME` | your Artifactory user |
| `ARTIFACTORY_API_KEY` | your Artifactory token |

For example via *Start → "Edit environment variables for your account"*, or in a terminal:

```
setx ARTIFACTORY_USERNAME <your Artifactory user>
setx ARTIFACTORY_API_KEY <your Artifactory token>
```

Open a new terminal afterwards. When your token is renewed, update `ARTIFACTORY_API_KEY`.

## pip

pip cannot read environment variables, so it needs its own file with the Artifactory URL
and your credentials. Create `%APPDATA%\pip\pip.ini` once (ask your team lead for the URL):

```ini
[global]
index-url = https://<your Artifactory user>:<your Artifactory token>@<Artifactory PyPI URL>/simple
```

When your token is renewed, update this file too. The CA certificate is already configured
globally, so do not set `cert` in this file.

## Preconfigured tools

These tools are configured globally for all users. No manual configuration is needed.

- **Maven**: Artifactory repository and credentials, Windows certificate store and proxy settings.
- **Node.js / npm**: Artifactory registry and credentials.

## Internal CA certificates

The bank's internal CA bundle is placed on every toolbox by the system admin team at
`C:\Users\Public\certs\ca-bundle.crt`. Tools that need it are already configured to use it.
No action is needed.

## Teams

- [Team QA](team_qa.md)
