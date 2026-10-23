# Development Toolbox

The development toolbox is the set of tools installed on developer machines by Ansible.
Every machine gets the **base toolbox** described here. Each team adds its own tools on top (see [Teams](#teams)).

Ansible owns the installed tools and their configuration. Changes made by hand to managed
files are overwritten on the next run. Installed versions are defined in
[`profiles/windows/toolbox/base.yml`](../../profiles/windows/toolbox/base.yml).

## Base tools

| Tool | Purpose | Location |
|---|---|---|
| Git | Version control | `C:\Program Files\Git` |
| VS Code | Editor | `C:\Program Files\Microsoft VS Code` |
| JDK | Java development (`JAVA_HOME`) | `C:\Program Files\Java\jdk-<version>` |
| Maven | Java builds (`MAVEN_HOME`) | `C:\Tools\apache-maven-<version>` |
| Bruno | API testing | `C:\Program Files\Bruno` |

## One-time setup: Artifactory credentials

Maven (and npm in some team toolboxes) reads your Artifactory credentials from two
user environment variables. Set them once in a terminal:

```
setx ARTIFACTORY_USERNAME <your Artifactory user>
setx ARTIFACTORY_API_KEY <your Artifactory token>
```

Open a **new** terminal afterwards. When your token is renewed, run the second command again.

## Preconfigured for you

**Maven**
- `%MAVEN_HOME%\conf\settings.xml` points Maven to Artifactory and uses the credentials above.
- `MAVEN_OPTS` makes Java use the Windows certificate store and the Windows proxy settings,
  so no truststore or proxy configuration is needed.
- A personal `%USERPROFILE%\.m2\settings.xml` takes precedence over the global one.
  Use it only for personal additions, not to change the repository or the credentials.

## Installed at your first sign-in

Some team tools can only be installed per user. Ansible prepares
them on the machine, and Windows installs them **once for each user at sign-in**.

- Sign out completely and sign in again. Reconnecting to an open remote session does not count.
- The installation runs in the background and can take a minute after sign-in.

## Troubleshooting

**A new or changed environment variable is not visible**
Open a new terminal. Terminals that were already open keep the old values.

**`mvn` reports that `JAVA_HOME` is not defined correctly**
Run `echo %JAVA_HOME%`. It must be the JDK folder itself, for example
`C:\Program Files\Java\jdk-23`, **without** `\bin`. If it is wrong, ask your team lead:
the value is managed by Ansible.

**A tool that is installed at sign-in is missing**
Windows records the installation as done even if it failed. To run it again:

1. Delete the record for that tool (the name is listed on the team page, for example `postman`):
   ```
   reg delete "HKCU\Software\Microsoft\Active Setup\Installed Components\Ansible_<name>" /f
   ```
2. Sign out completely and sign in again.

## Teams

- [Team QA](team_qa.md)

## Background

How the toolbox is built (package pinning, installation at sign-in, tool configuration):
[arc42, chapter 8](../architecture/arc42-architecture.md#8-crosscutting-concepts).
