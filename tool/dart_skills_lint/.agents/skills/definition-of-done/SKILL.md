---
name: definition-of-done
description: Mandatory checks to run before completing any task that touches md files or dart code in this repository.
---

# Definition of Done

Use this skill to ensure that all work meets the repository standards before declaring a task complete or requesting review.

## 📋 Mandatory Verification Steps

Before stating that a task is complete, you MUST execute and pass the following checks:

1.  **Formatting**: Run `dart format .` and ensure all files are formatted correctly.
2.  **Analysis**: Run `dart analyze --fatal-infos` and ensure there are zero issues (including info-level issues).
3.  **Metrics**: Run `dart run dart_code_linter:metrics analyze lib` and ensure there are zero issues.
4.  **Tests**: Run `dart test` and ensure all tests pass successfully.
5.  **Skill Validation**: If any skill files were modified, run `dart run dart_skills_lint -d .agents/skills` to ensure they are valid.

## 🚦 Completion Checklist

- [ ] Code is formatted (`dart format .`).
- [ ] Analysis is clean (`dart analyze --fatal-infos`).
- [ ] Metrics are clean (`dart run dart_code_linter:metrics analyze lib`).
- [ ] Tests are passing (`dart test`).
- [ ] Skills validated if modified (`dart run dart_skills_lint -d .agents/skills`).
- [ ] Documentation is updated.
