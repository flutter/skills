# Report: Conflict Analysis for Dual-Publishing as Pub Package and Agent Skill

This report investigates the compatibility of the `dart_skills_lint` codebase with two different distribution specifications: the [pub.dev package specification](https://dart.dev/tools/pub/pubspec) and the [Agent Skills specification](../knowledge/SPECIFICATION.md).

## 1. Executive Summary

While it is technically possible to host both specifications in a single codebase, there are several **hard conflicts** regarding naming conventions and directory requirements. Most notably, a single identifier cannot satisfy both naming standards simultaneously if it contains separators.

## 2. Identified Conflicts

### 2.1 Naming Convention (Hard Conflict)
The most significant conflict lies in the allowed characters for project identifiers:

*   **Pub Package Specification:** Package names must be valid Dart identifiers. They **must use underscores** (`_`) for separators and **cannot contain hyphens** (`-`).
*   **Agent Skills Specification:** Skill names must be lowercase alphanumeric and **must use hyphens** (`-`) for separators. They **cannot contain underscores** (`_`).

**Result:** A project named `dart_skills_lint` (valid for pub) is invalid for Agent Skills. A project named `dart-skills-lint` (valid for skills) is invalid for pub. To publish as both, the project must use two different names (e.g., `dart_skills_lint` on pub and `dart-skills-lint` as a skill).

### 2.2 Directory Name Match Rule (Structural Conflict)
*   **Agent Skills Specification:** The `name` field in `SKILL.md` **must exactly match** the name of its parent directory.
*   **Pub Package Specification:** While not strictly enforced for publishing, Dart conventions strongly prefer the directory name to match the package name in `pubspec.yaml`.

**Result:** To satisfy the Agent Skills specification, the project directory **must** be named `dart-skills-lint`. This forces a discrepancy between the directory name and the internal Dart package name (`dart_skills_lint`), which may cause minor confusion for Dart developers but does not prevent functionality.

### 2.3 Directory Structure and "Clutter"
*   **Agent Skills Specification:** Recommends a "flat and predictable structure" consisting of `SKILL.md`, `scripts/`, `references/`, and `assets/`.
*   **Pub Package Specification:** Requires a specific structure with `pubspec.yaml`, `lib/`, `bin/`, and `test/`, along with ephemeral directories like `.dart_tool/`.

**Result:** While these can coexist, a Dart project is significantly more complex than the "flat" structure envisioned for Agent Skills. An AI agent scanning the skill directory will encounter numerous files (like `pubspec.lock`, `analysis_options.yaml`) that are irrelevant to its operation, potentially wasting context if not explicitly ignored.

### 2.4 Executable Location
*   **Agent Skills Specification:** Expects executable logic to reside in the `scripts/` directory.
*   **Pub Package Specification:** Places CLI entry points in the `bin/` directory.

**Result:** To align with the Agent Skills specification, the `SKILL.md` instructions must either:
1.  Explicitly point the agent to `bin/dart_skills_lint.dart`.
2.  Provide a wrapper script in a `scripts/` directory (e.g., `scripts/run-linter.sh`) that executes the Dart code.

### 2.5 Metadata Redundancy
Both specifications require overlapping metadata (description, license, version).
*   **Pub:** Stored in `pubspec.yaml`.
*   **Skills:** Stored in `SKILL.md` YAML frontmatter.

**Result:** There is no native mechanism to synchronize these. Developers must manually ensure that the description and version remain consistent across both files, increasing the risk of "metadata drift."

## 3. Recommended Strategy for `dart_skills_lint`

To achieve dual-compatibility, the following configuration is recommended:

1.  **Directory Name:** Keep the directory named `dart-skills-lint`.
2.  **SKILL.md:**
    -   Set `name: dart-skills-lint`.
    -   Provide clear instructions to run `dart bin/dart_skills_lint.dart` or `dart run`.
3.  **pubspec.yaml:**
    -   Set `name: dart_skills_lint`.
4.  **Scripts Wrapper:** Consider adding a `scripts/lint.sh` that calls the Dart linter to satisfy the standard skill directory structure.
