# Team QA Toolbox

Includes everything in the [base toolbox](README.md). The additional QA tools are listed in
[`profiles/windows/toolbox/team_qa.yml`](../../profiles/windows/toolbox/team_qa.yml).

## Shared Node.js packages

The test packages (Playwright, Cucumber-js and their dependencies) are installed once in a
shared folder, maintained by the admins:

```
D:\cucumber\node_modules
```

Clone your projects into your own workspace folder, `D:\cucumber\workspace\<your user>`.
Node finds the shared packages from there automatically.

`PLAYWRIGHT_BROWSERS_PATH` is set to `0`, so Playwright uses the browsers that are already
in the shared folder instead of trying to download them.

## Installed at your first sign-in

Postman, k6 Studio and the VS Code extensions can only be installed per user. Ansible prepares
them on the machine, and Windows installs them **once for each user at sign-in**.

- Sign out completely and sign in again. Reconnecting to an open remote session does not count.
- The installation runs in the background and can take a minute after sign-in.

If one of them is missing after sign-in, Windows has recorded it as done even though it failed.
To run it again, delete its record and sign out and in again:

```
reg delete "HKCU\Software\Microsoft\Active Setup\Installed Components\Ansible_<name>" /f
```

| Tool | `<name>` |
|---|---|
| Postman | `postman` |
| k6 Studio | `k6_studio` |
| VS Code extensions | `vscode_extensions` |
