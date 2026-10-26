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

- The Playwright browsers are part of the shared folder. No `npx playwright install` is needed.
- Do not install Playwright in your project: Playwright would then look for its browsers in
  the project and not find them.
- The shared folder is for development and trying things out. The packages in it are
  defined in a separate Git project, which also builds the pipeline's Docker image.

## Installed at your first sign-in

Postman, k6 Studio and the VS Code extensions can only be installed per user. Ansible prepares
them on the machine, and Windows installs them **once for each user at sign-in**.

- Sign out completely and sign in again. Reconnecting to an open remote session does not count.
- The installation runs in the background and can take a minute after sign-in.
- VS Code extensions log to `%LOCALAPPDATA%\ansible-vscode-extensions.log`. When the
  extension list changes, the listed versions are installed again, also over a newer
  version you may have installed yourself.

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
