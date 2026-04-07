# dart_skills_lint

A static analysis linter for Agent Skills to ensure they meet the specification in presubmit checks. This project is a Dart package and can be run as a CLI tool to validate your skills directory before committing.

## Table of Contents
- [Overview](#overview)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Specification Validation](#specification-validation)
- [Best Practices](#best-practices)

## Overview

An **Agent Skill** is a portable, self-contained directory that extends an AI agent's capabilities. Pre-submit linting ensures that your skill definitions are valid and ready for consumption by agent platforms.

`dart_skills_lint` validates:
- Presence of mandatory `SKILL.md` file.
- YAML frontmatter constraints (naming, length, etc.).
- Directory structure (flat, no deep nesting).
- Relative path integrity.

For a full definition of the skill standard, see the [Agent Skills Specification](documentation/knowledge/SPECIFICATION.md).

## Installation

Add `dart_skills_lint` to your Dart project or activate it globally.

### 1. As a project dependency
Add it to your `pubspec.yaml` (once published on pub.dev):
```yaml
dev_dependencies:
  dart_skills_lint: ^1.0.0
```
Then run:
```bash
dart pub get
```

### 2. Globally activated
If you want to use it across multiple projects without adding it to each `pubspec.yaml`:
```bash
dart pub global activate dart_skills_lint
```

## Usage

Run the linter against your skills or root skills directories.

### Project Usage
If installed as a dev_dependency:
```bash
dart run dart_skills_lint --skills-directory ./path/to/skills-root
```

Multiple root directories can be specified:
```bash
dart run dart_skills_lint --skills-directory ./path/to/root-a --skills-directory ./path/to/root-b
```

Validate Individual Skills directly using `--skill` or `-s`:
```bash
dart run dart_skills_lint --skill ./path/to/my-single-skill
```

If no directory is specified, it automatically checks `.claude/skills` and `.agents/skills` relative to your workspace root.

### Flags
- `-d`, `--skills-directory`: Specifies a root directory containing sub-folders of skills to validate. Can be passed multiple times. Can use home tilde expansion (ex: `~/.agents/skills`).
- `-s`, `--skill`: Specifies an individual skill directory to validate directly. Can be passed multiple times.
- `-q`, `--quiet`: Hide non-error validation output.
- `-w`, `--print-warnings`: Enable printing of warning messages.
- `--fast-fail`: Halt execution immediately on the error.
- `--ignore-config`: Ignore the YAML configuration file entirely.

## Configuration

You can configure the linter using a configuration file (defaulting to `dart_skills_lint.yaml`).

### Example `dart_skills_lint.yaml`
Create this file in the root of your repository:

```yaml
# dart_skills_lint.yaml
dart_skills_lint:
  rules:
    no-unresolved-relative-paths: error
    valid-yaml-metadata: error
    flat-directory-structure: warning # Can override to warning instead of error
```

## Specification Validation

The linter checks against the criteria defined in `documentation/knowledge/SPECIFICATION.md` (Section 5.1). Key checks include:

### 1. Directory and File Structure
- Path existence and directory verification.
- Mandatory `SKILL.md` file at the root.
- Directories starting with a dot `.` (e.g., `.dart_tool`) are ignored when scanning for skills.

### 2. Metadata (YAML Frontmatter)
- Valid YAML syntax.
- Allowed fields: `name`, `description`, `license`, `allowed-tools`, `metadata`, `compatibility`.
- Required fields: `name` and `description`.

### 3. Field Specific Constraints
- **Skill Name (`name`)**: Max 64 characters, lowercase alphanumeric and hyphens only, no leading/trailing/consecutive hyphens. **Must match the parent directory name.**
- **Description (`description`)**: Max 1024 characters.
- **Compatibility (`compatibility`)**: Max 500 characters.

## Contributing

Contributions are welcome! Please ensure that any PRs pass the linter themselves and align with the `documentation/knowledge/SPECIFICATION.md`.

