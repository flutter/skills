---
name: dart-skills-lint-validation
description: |-
  Use this skill when you need to validate that AI agent skills meet the specification.
  This includes generic validation of any skills for users that have Dart installed,
  as well as integrating dart_skills_lint into a Dart project as a dev_dependency
  to automate skill validation in tests or CI/CD.
---

# Skill Validation with dart_skills_lint

## Usage for Agents (CLI)
Agents can use the `dart_skills_lint` CLI to validate skills.

If the package is in your dependencies, run:
```bash
dart run dart_skills_lint -d .agents/skills
```

Or if activated globally:
```bash
dart pub global run dart_skills_lint -d .agents/skills
```

### Common Flags
- `-d`, `--skills-directory`: Specifies a root directory containing sub-folders of skills to validate. Can be passed multiple times.
- `-s`, `--skill`: Specifies an individual skill directory to validate directly. Can be passed multiple times.
- `-q`, `--quiet`: Hide non-error validation output.
- `-w`, `--print-warnings`: Enable printing of warning messages.

## Setup for Dart Developers
To setup validation in your Dart project:

1. Add `dart_skills_lint` to your `pubspec.yaml` as a `dev_dependency`:
   ```yaml
   dev_dependencies:
     dart_skills_lint: ^0.2.0
   ```

2. You can also integrate the linter into your automated tests by importing the package and calling `validateSkills`. This has the advantage that your skills are automatically validated whenever you run `dart test`.

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
