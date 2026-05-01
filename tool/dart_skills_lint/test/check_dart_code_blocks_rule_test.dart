// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:dart_skills_lint/src/models/analysis_severity.dart';
import 'package:dart_skills_lint/src/rules/check_dart_code_blocks_rule.dart';
import 'package:dart_skills_lint/src/validator.dart';
import 'package:test/test.dart';
import 'test_utils.dart';

void main() {
  group('CheckDartCodeBlocksRule', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('check_dart_code_blocks_test.');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('passes with valid code block', () async {
      final Directory skillDir = await Directory('${tempDir.path}/test-skill').create();
      await File('${skillDir.path}/SKILL.md').writeAsString('''
${buildFrontmatter(name: 'test-skill')}
```dart
void main() {
  print("Hello");
}
```
''');

      final validator =
          Validator(ruleOverrides: {CheckDartCodeBlocksRule.ruleName: AnalysisSeverity.error});
      final ValidationResult result = await validator.validate(skillDir);

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('fails with invalid code block', () async {
      final Directory skillDir = await Directory('${tempDir.path}/test-skill').create();
      await File('${skillDir.path}/SKILL.md').writeAsString('''
${buildFrontmatter(name: 'test-skill')}
```dart
void main() {
  invalidCode();
}
```
''');

      final validator =
          Validator(ruleOverrides: {CheckDartCodeBlocksRule.ruleName: AnalysisSeverity.error});
      final ValidationResult result = await validator.validate(skillDir);

      expect(result.isValid, isFalse);
      expect(result.errors, contains(contains('Dart code blocks contained compilation errors')));
    });

    test('disabled by default', () async {
      final Directory skillDir = await Directory('${tempDir.path}/test-skill').create();
      await File('${skillDir.path}/SKILL.md').writeAsString('''
${buildFrontmatter(name: 'test-skill')}
```dart
void main() {
  invalidCode();
}
```
''');

      final validator = Validator(); // No overrides
      final ValidationResult result = await validator.validate(skillDir);

      expect(result.isValid, isTrue); // Passes because rule is disabled
      expect(result.errors, isEmpty);
    });

    test('reads config from frontmatter', () async {
      final Directory skillDir = await Directory('${tempDir.path}/test-skill').create();
      await File('${skillDir.path}/SKILL.md').writeAsString('''
---
name: test-skill
description: test
metadata:
  popmark:
    imports: "dart:math"
---
```dart
void main() {
  print(sqrt(4));
}
```
''');

      final validator =
          Validator(ruleOverrides: {CheckDartCodeBlocksRule.ruleName: AnalysisSeverity.error});
      final ValidationResult result = await validator.validate(skillDir);

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });
  });
}
