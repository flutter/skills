---
name: add-dart-lint-validation-rule
description: Instructions for adding a new validation rule and CLI flag to dart-skills-lint.
---

# Add a New Validation Rule and Flag

Use this skill when you need to add a new validation rule to the `dart_skills_lint` package, expose it as a toggleable CLI flag, and verify its behavior.

---

## 🛠️ Step-by-Step Implementation

### 1. Define the Rule in `lib/src/rules.dart`

To create a new rule, add a top-level `CheckType` instance.

```dart
// lib/src/rules.dart

/// Template instance for checking if the description has a trailing period.
final descriptionTrailingPeriodCheck = CheckType(
  name: 'description-trailing-period',
  defaultSeverity: AnalysisSeverity.error, // or warning/disabled
);
```

### 2. Expose the CLI Flag in `lib/src/entry_point.dart`

Modify `runApp` to include the toggleable flag for your new rule.

#### 📋 Register Parser Option
Add `.addFlag` in `runApp` (around line 60-90):

```dart
// lib/src/entry_point.dart

parser
  ..addFlag(descriptionTrailingPeriodCheck.name,
      negatable: true,
      defaultsTo: true,
      help: 'Check if the description ends with a period.');
```

#### 🎚️ Resolve Flag Logic or Override Severities
Find where severities are evaluated (around line 140-170) and bind your flag state:

```dart
if (results.wasParsed(descriptionTrailingPeriodCheck.name)) {
  descriptionTrailingPeriodCheck.severity = (results[descriptionTrailingPeriodCheck.name] as bool)
      ? descriptionTrailingPeriodCheck.defaultSeverity
      : AnalysisSeverity.disabled;
}
```

Add your rule to the `checkTypes` set if you want it loaded by default configuration overrides.

### 3. Implement Validation in `lib/src/validator.dart`

Write the specific logic inside `Validator` checking the schema.

```dart
// lib/src/validator.dart

void _validateDescriptionPeriod(String description, List<ValidationError> validationErrors) {
  if (description.isNotEmpty && !description.endsWith('.')) {
    validationErrors.add(ValidationError(
      ruleId: _getRule(descriptionTrailingPeriodCheck).name,
      file: _skillFileName,
      message: 'Description must end with a period.',
      severity: _getRule(descriptionTrailingPeriodCheck).severity,
    ));
  }
}
```

Invoke your sub-routine inside `_parseMetadataFields`:

```dart
final description = yaml[_descriptionField]?.toString() ?? '';
if (description.isNotEmpty) {
  _validateDescriptionPeriod(description, validationErrors);
}
```

---

## 🧪 Testing the New Rule

You must write automated tests verifying your rule triggers when it should and skips when it shouldn't.

### Creating a Test Suite Case
Add matching suite files in `test/` (e.g., `test/field_constraints_test.dart` or `test/metadata_validation_test.dart`).

```dart
// test/field_constraints_test.dart

test('triggers error when description does not end with period', () async {
  final tempDir = createTempSkillDir(
    name: 'test-skill',
    description: 'This description does not end with a period',
  );
  
  final validator = Validator(rules: {descriptionTrailingPeriodCheck});
  final result = await validator.validate(tempDir);
  
  expect(result.validationErrors.any((e) => e.ruleId == 'description-trailing-period'), isTrue);
});
test('skips error when description ends with period', () async {
  final tempDir = createTempSkillDir(
    name: 'test-skill',
    description: 'This description ends with a period.',
  );
  
  final validator = Validator(rules: {descriptionTrailingPeriodCheck});
  final result = await validator.validate(tempDir);
  
  expect(result.validationErrors.any((e) => e.ruleId == 'description-trailing-period'), isFalse);
});
```

---

## 📚 Documentation Updates

When a new rule is introduced, verify that you synchronize sibling markdown files!

1.  **`README.md`:** 
    *   Add your flag under the **Usage** and **Flags** sections so users know it exists.
    *   Add descriptive lines under **Specification Validation**.
2.  **`documentation/knowledge/SPECIFICATION.md`:** 
    *   If the rule implements standard specifications traits, add constraints parameters under Section 5.1 (Validation parameters).

---

## 🚦 Checklist Before Submitting PR

- [ ] Rule defined in `rules.dart`.
- [ ] Flag registered in `entry_point.dart`.
- [ ] Logic implemented in `validator.dart`.
- [ ] Toggle logic tests added in `test/`.
- [ ] Usage listed in `README.md`.
- [ ] Schema documented in `documentation/knowledge/SPECIFICATION.md`.
- [ ] Run `dart analyze` to ensure no issues.
- [ ] Run `dart test` to ensure tests passing.
- [ ] Run `dart format .` to format code.
