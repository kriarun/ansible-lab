# Add A Software Catalog Entry

Use this guide when you want to register a new package in the automation platform.

For Windows, catalog fragments live under:

```text
profiles/windows/software_catalog/
```

Each fragment usually groups related package entries, for example `git.yml` or `python.yml`.

## 1. Pick The Catalog Fragment

Choose whether to:

- add a package to an existing fragment such as `git.yml`
- create a new fragment such as `maven.yml`

Keep the fragment name aligned with the role that will consume it.

## 2. Choose A Clear Package Key

Use a stable key that includes product and version information.

Examples:

- `git_2_44_0`
- `python_3_13_2`
- `dotnet-hosting-8.0.13-win`

## 3. Add The Package Definition

Each package entry should define at least:

- `source`
- `install`

Optional sections currently supported by the shared Windows flow include:

- `path`
- `env`
- `registry`
- `certificate`

Example:

```yaml
maven_3_9_9:
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

## 4. Add A Verification Check

Always include an installation verification marker under:

```yaml
install:
  check:
    path_exists: ...
```

This is the primary validation pattern used by the current execution flow.

## 5. Reference The Package Key From A Profile

The catalog entry is just metadata until a profile includes the corresponding package key.

Example:

```yaml
maven_packages:
  - maven_3_9_9
```

That variable should live in the same profile layer that owns the role:

- toolbox base profile
- toolbox team profile
- machine profile

## 6. Make Sure The Role Consumes The Right Fragment

The matching role should call `install_from_catalog.yml` with:

- `software_catalog_entry`: the fragment file name, for example `maven.yml`
- `software_package_list`: the package variable, for example `maven_packages`

Example:

```yaml
- name: Install Maven packages
  ansible.builtin.include_tasks: ../../common/tasks/install_from_catalog.yml
  vars:
    software_catalog_entry: maven.yml
    software_package_list: "{{ maven_packages | default([]) }}"
    software_role_name: maven
```

## Notes

- Put installation metadata in the catalog, not in the role.
- Keep package keys versioned so profile intent stays explicit.
- Reuse the examples document for source-type and optional-section patterns.
- If you are adding machine-wide environment settings unrelated to one package, consider whether they belong in `machine_env` instead.
