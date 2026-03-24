# Add a Software Catalog Entry

Use this guide when you want to register a new package in the software catalog.

Windows catalog files live under:

```text
profiles/windows/software_catalog/
```

## 1. Choose a software key

Use a clear key that includes the software name and version.

Examples:

- `git_2_44_0`
- `python_3_13_2`
- `vscode_1_87_0`

## 2. Add the package definition

Each entry should define:

- `source`
- `install`
- optional `path`
- optional `env`
- optional `registry`
- optional `certificate`

Minimal example:

```yaml
git_2_44_0:
  source:
    type: local
    path: "D:\\ManualDrops"
    filename: "Git-2.44.0-64-bit.exe"
  install:
    type: exe
    arguments: "/VERYSILENT"
    check:
      path_exists: "C:\\Program Files\\Git\\bin\\git.exe"
```

## 3. Reference the key from a role variable

The catalog entry is only metadata. A role or profile must reference the key.

Example:

```yaml
git_packages:
  - git_2_44_0
```

## 4. Add optional configuration

If the software also needs path entries, environment variables, registry entries, or certificates, add them to the same catalog item.

Example:

```yaml
maven:
  source:
    type: local
    path: "D:\\ManualDrops"
    filename: "apache-maven-3.9.9-bin.zip"
  install:
    type: zip
    destination: "C:\\Tools\\apache-maven-3.9.9"
    check:
      path_exists: "C:\\Tools\\apache-maven-3.9.9\\bin\\mvn.cmd"
  path:
    enabled: true
    entries:
      - "C:\\Tools\\apache-maven-3.9.9\\bin"
  env:
    enabled: true
    variables:
      MAVEN_HOME: "C:\\Tools\\apache-maven-3.9.9"
```

## Notes

- Put installation metadata in the catalog, not in the role.
- Always include a verification check under `install.check`.
- Use the examples document for source-type and optional-section patterns.
