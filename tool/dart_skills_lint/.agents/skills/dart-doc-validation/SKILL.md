---
name: dart-doc-validation
description: |-
  Best practices for validating Dart documentation comments.
  Covers using `dart doc` to catch unresolved references and macros.
license: Apache-2.0
---

# Dart Doc Validation

## 1. When to use this skill

Use this skill when:
-   Writing or updating documentation comments (`///`) in Dart code.
-   Checking for broken documentation links, references, or macros.
-   Preparing a package for publishing to pub.dev.

## 2. Best Practices

### Validating Documentation Locally

Use the `dart doc` command with a temporary output directory to validate
documentation comments without polluting the local project workspace.

This command parses all documentation comments and reports warnings such as:
-   `warning: unresolved doc reference`
-   `warning: undefined macro`

**Command to run:**
```bash
dart doc -o $(mktemp -d)
```

This ensures that the generated HTML files are stored in a temporary location
and don't clutter the package directory, while still surfacing all validation
warnings in the terminal output.

### Fixing Common Warnings

-   **Unresolved doc reference**: Ensure that any identifier wrapped in square
    brackets (`[Identifier]`) correctly points to an existing class, method,
    property, or parameter in the current scope or imported libraries.
-   **Undefined macro**: If using `{@macro macro_name}`, ensure that the
    template `{@template macro_name}` is defined in the same file or a file
    that is imported and visible to the documentation generator.
