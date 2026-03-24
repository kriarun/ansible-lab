# Software Catalog Examples

This document shows common patterns used in Windows software catalog entries.

## Local Source

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

## JFrog Source

```yaml
python_3_13_2:
  source:
    type: jfrog
    url: "https://jfrog.example/artifactory/windows-tools"
    filename: "python-3.13.2-amd64.exe"
  install:
    type: exe
    arguments: "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0"
    check:
      path_exists: "C:\\Program Files\\Python313\\python.exe"
```

## PATH Entries

```yaml
maven:
  path:
    enabled: true
    entries:
      - "C:\\Tools\\apache-maven-3.9.9\\bin"
```

## Environment Variables

Use this when a package should set environment variables during installation.

```yaml
maven:
  env:
    enabled: true
    variables:
      JAVA_HOME: "C:\\Java\\jdk-21"
      MAVEN_HOME: "C:\\Tools\\apache-maven-3.9.9"
```

## Registry Entries

```yaml
tool_x:
  registry:
    enabled: true
    entries:
      - path: HKLM:\Software\MyCompany\ToolX
        name: Enabled
        type: dword
        value: 1
```

## Certificates

```yaml
visual_studio:
  certificate:
    enabled: true
    entries:
      - file: "\\\\share\\vs\\certificates\\MicrosoftWindowsCodeSigningPCA2024.cer"
        store_location: LocalMachine
        store_name: CA
```

## Full Example

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
      JAVA_HOME: "C:\\Java\\jdk-21"
      MAVEN_HOME: "C:\\Tools\\apache-maven-3.9.9"
  registry:
    enabled: true
    entries:
      - path: HKLM:\Software\MyCompany\Maven
        name: Installed
        type: dword
        value: 1
```
