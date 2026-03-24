# Future Considerations

This document captures known gaps and planned enhancements that are intentionally out of scope for the current implementation.

## Package Version and Side-by-Side Rules

Some software cannot be installed side by side on the same machine, or should have only one active version at a time.

Examples may include:

- Git
- Google Chrome
- other products with machine-wide installers or upgrade-only behavior

This is not handled yet in the current framework.

Future work may include:

- defining a catalog flag such as `side_by_side_supported: false`
- detecting conflicting installed versions before installation
- uninstalling or replacing incompatible versions
- enforcing a single approved version per machine profile
- failing early when a profile requests conflicting versions

## Pre-Install Validation

Some packages may require validation before installation begins.

Examples:

- confirm whether an existing installation is upgradeable
- block installation if another version is already present
- verify prerequisites before applying package configuration

## Conflict Resolution Strategy

The framework may later need a standard strategy for handling software conflicts.

Possible options:

- skip installation when a conflict is detected
- upgrade the existing version in place
- uninstall the old version and install the new version
- allow behavior to be controlled per software catalog entry

## Profile and Catalog Metadata

Future metadata may be added to catalog entries to support more advanced behavior.

Examples:

```yaml
git_2_44_0:
  compatibility:
    side_by_side_supported: false
    upgrade_strategy: in_place
    conflicts_with:
      - git_2_43_0
```

## Notes

- These ideas are design placeholders, not active behavior.
- The current platform should continue to focus on stable installation flows first.
- When this work starts, the preferred place for the logic will likely be the resolver or execution-plan layer rather than individual roles.
