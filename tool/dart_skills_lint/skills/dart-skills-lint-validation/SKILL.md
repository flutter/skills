---
name: dart-skills-lint-validation
description: |-
  Use this skill when you need to validate that AI agent skills meet the specification.
  This includes generic validation of any skills for users that have Dart installed,
  as well as integrating dart_skills_lint into a Dart project as a dev_dependency
  to automate skill validation in tests or CI/CD.
---

# Validating Skills with dart_skills_lint

## Contents
- [Usage for Agents (CLI)](#usage-for-agents-cli)
- [Setup for Dart Developers](#setup-for-dart-developers)
- [Authoring Custom Rules](#authoring-custom-rules)
- [Workflow: Validating Skills](#workflow-validating-skills)
- [Specification Reference](#specification-reference)

## Usage for Agents (CLI)
Use the `dart_skills_lint` CLI to validate skills. Choose the appropriate workflow based on your environment:

### Scenario A: The package is in your project dependencies
Use this method if you are working within a project that has `dart_skills_lint` listed in `pubspec.yaml`.
Run:
```bash
dart run dart_skills_lint -d .agents/skills
```

### Scenario B: The package is activated globally
Use this method if you want to validate skills across multiple projects without adding a dependency to each one.
Run:
```bash
dart pub global run dart_skills_lint -d .agents/skills
```

### Common Flags
- `-d`, `--skills-directory`: Specifies a root directory containing sub-folders of skills to validate. Can be passed multiple times.
- `-s`, `--skill`: Specifies an individual skill directory to validate directly. Can be passed multiple times.
- `-q`, `--quiet`: Hide non-error validation output.
- `-w`, `--print-warnings`: Enable printing of warning messages.
- `--fast-fail`: Halt execution immediately on the error.
- `--ignore-config`: Ignore the YAML configuration file entirely.

## Setup for Dart Developers
Setup validation in your Dart project:

1. Add `dart_skills_lint` to your `pubspec.yaml` as a `dev_dependency`:
   ```yaml
   dev_dependencies:
     dart_skills_lint: ^0.2.0
   ```

2. Integrate the linter into your automated tests by importing the package and calling `validateSkills`. This ensures your skills are automatically validated whenever you run `dart test`.

   Example `test/lint_skills_test.dart`:
   ```dart
   import 'package:dart_skills_lint/dart_skills_lint.dart';
   import 'package:test/test.dart';

   void main() {
     test('Run skills linter', () async {
       final isValid = await validateSkills(
         skillDirPaths: ['.agents/skills'],
       );
       expect(isValid, isTrue);
     });
   }
   ```

3. (Optional) Create a configuration file `dart_skills_lint.yaml` in the root of your project to customize rules and directories for the CLI:
**Note:** If you use `validateSkills` directly in tests, the `dart_skills_lint.yaml` file is ignored by default, and you should pass configuration programmatically if needed.
   ```yaml
   dart_skills_lint:
     rules:
       check-relative-paths: error
       check-absolute-paths: error
     directories:
       - path: ".agents/skills"
   ```

## Authoring Custom Rules
To author custom rules, extend the `SkillRule` class and pass them to `validateSkills`.

Example:
```dart
import 'package:dart_skills_lint/dart_skills_lint.dart';

class MyCustomRule extends SkillRule {
  @override
  final String name = 'my-custom-rule';

  @override
  final AnalysisSeverity severity = AnalysisSeverity.warning;

  @override
  Future<List<ValidationError>> validate(SkillContext context) async {
    final errors = <ValidationError>[];
    final yaml = context.parsedYaml;
    if (yaml == null) return errors;

    if (yaml['metadata']?['deprecated'] == true) {
      errors.add(ValidationError(
        ruleId: name,
        severity: severity,
        file: 'SKILL.md',
        message: 'This skill is marked as deprecated.',
      ));
    }
    return errors;
  }
}
```

Use it in your test:
```dart
await validateSkills(
  skillDirPaths: ['.agents/skills'],
  customRules: [MyCustomRule()],
);
```

## Workflow: Validating Skills
Follow this workflow to validate skills:

1. **Run the validator**: Execute the linter on your skills directory.
   ```bash
   dart run dart_skills_lint -d .agents/skills
   ```
2. **Review errors**: Check the output for any errors or warnings.
3. **Fix violations**: Edit the `SKILL.md` or directory structure to resolve issues.
4. **Verify**: Re-run the validator to ensure all checks pass.

### Task Progress
- [ ] Run validator
- [ ] Review errors
- [ ] Fix violations
- [ ] Verify clean run

## Specification Reference
<details>
<summary>View Skill Specification Constraints</summary>

### Directory and File Structure
- Mandatory `SKILL.md` file at the root of the skill folder.
- Directories starting with a dot `.` (e.g., `.dart_tool`) are ignored.

### Metadata (YAML Frontmatter)
- Required fields: `name` and `description`.

### Field Constraints
- **Name**: Max 64 characters, lowercase alphanumeric and hyphens only. Must match the parent directory name.
- **Description**: Max 1024 characters.
- **Compatibility**: Max 500 characters.
</details>
