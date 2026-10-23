# Team QA Toolbox

Includes everything in the [base toolbox](README.md), plus the tools below.
Installed versions are defined in
[`profiles/windows/toolbox/team_qa.yml`](../../profiles/windows/toolbox/team_qa.yml).

## Tools

| Tool | Purpose | Notes |
|---|---|---|
| Node.js + npm | Test projects (Playwright, Cucumber-js) | npm preconfigured for Artifactory |
| Python + pip | Scripts and tooling | on `PATH`, pip preconfigured (see [pip](#pip)) |
| Postman | API testing | installed at your first sign-in (`postman`) |
| k6 | Load tests | on `PATH` |
| k6 Studio | Recording load tests | installed at your first sign-in (`k6_studio`) |
| Chrome | Manual testing | updates itself |
| Firefox ESR | Manual testing | |
| ctags | Code navigation | on `PATH` |
| VS Code extensions | Playwright Test, Cucumber autocomplete | installed at your first sign-in (`vscode_extensions`) |

The name in brackets is the one to use when re-running an installation
(see [Troubleshooting](README.md#troubleshooting) in the base toolbox).

## One-time setup

1. Set your Artifactory credentials as described in the [base toolbox](README.md#one-time-setup-artifactory-credentials).
   npm uses `ARTIFACTORY_API_KEY`. pip needs its own file, see [pip](#pip).
2. Get the internal CA bundle from your team lead and copy it to:
   ```
   C:\Users\Public\certs\ca-bundle.crt
   ```
   npm and pip need it to trust Artifactory. They do not use the Windows certificate store.

Never set `strict-ssl=false` to work around certificate errors. It turns off certificate
checking and can send your Artifactory token to a server pretending to be Artifactory.

## npm

npm is configured for all users in `C:\Program Files\nodejs\node_modules\npm\npmrc`:
Artifactory as registry, your token from `ARTIFACTORY_API_KEY`, and the CA bundle above.
Globally installed packages go to `%APPDATA%\npm`.

- Do not set `registry`, `cafile` or `strict-ssl` in your own `%USERPROFILE%\.npmrc`:
  your file takes precedence and would override the managed settings.
- Check the setup: `npm config get registry` shows the Artifactory URL, and
  `npm view playwright version` returns a version number.

| Error | Likely cause |
|---|---|
| `E401` / unauthorized | credentials not set, token expired, or terminal opened before `setx` |
| certificate error (`UNABLE_TO_GET_ISSUER_CERT…`) or `ENOENT … ca-bundle.crt` | CA bundle missing or in the wrong place |

## pip

The machine-wide `C:\ProgramData\pip\pip.ini` is managed by Ansible and points pip to the CA bundle.

pip cannot read environment variables, so the Artifactory URL and your credentials go into
your own `%APPDATA%\pip\pip.ini`. Create it once (ask your team lead for the URL):

```ini
[global]
index-url = https://<your Artifactory user>:<your Artifactory token>@<Artifactory PyPI URL>/simple
```

When your token is renewed, update this file too. Do not set `cert` or `trusted-host` in it.

## Playwright browsers

`PLAYWRIGHT_BROWSERS_PATH=0` is set on the machine. Playwright installs its browsers inside
each project's `node_modules`, so the browser version always matches the project's
Playwright version. After `npm install`, run this once in each project:

```
npx playwright install
```

## VS Code extensions

The extensions are installed into your own VS Code profile at sign-in.
Log: `%LOCALAPPDATA%\ansible-vscode-extensions.log`.

When the extension list changes, the listed versions are installed again,
also over a newer version you may have installed yourself.
