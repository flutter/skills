// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart_skills_lint/src/models/analysis_severity.dart';
import 'package:dart_skills_lint/src/models/check_type.dart';
import 'package:dart_skills_lint/src/validator.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('Relative Paths Validation', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('paths_test.');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('passes with valid relative file path (existing file)', () async {
      final Directory skillDir = await Directory('${tempDir.path}/test-skill').create();
      await File('${skillDir.path}/SKILL.md').writeAsString(
          '${buildFrontmatter(name: 'test-skill')}[Link to a reference](references/DETAILS.md)\n');

      final Directory refDir = await Directory('${skillDir.path}/references').create();
      await File('${refDir.path}/DETAILS.md').writeAsString('Details here');

      final validator = Validator(rules: {
        CheckType(name: 'check-relative-paths', defaultSeverity: AnalysisSeverity.warning)
      });
      final ValidationResult result = await validator.validate(skillDir);

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
      expect(result.warnings, isEmpty);
    });

    test('warns with missing relative file path', () async {
      final Directory skillDir = await Directory('${tempDir.path}/test-skill').create();
      await File('${skillDir.path}/SKILL.md').writeAsString(
          '${buildFrontmatter(name: 'test-skill')}[Link to a references file missing](references/MISSING.md)\n');

      final validator = Validator(rules: {
        CheckType(name: 'check-relative-paths', defaultSeverity: AnalysisSeverity.warning)
      });
      final ValidationResult result = await validator.validate(skillDir);

      expect(result.isValid, isTrue);
      expect(result.warnings, contains(contains('Linked file does not exist')));
    });

    test('fails with absolute file path', () async {
      final Directory skillDir = await Directory('${tempDir.path}/test-skill').create();
      await File('${skillDir.path}/SKILL.md').writeAsString(
          '${buildFrontmatter(name: 'test-skill')}[Absolute path link](/tmp/some_absolute_path/file.md)\n');

      final validator = Validator(rules: {
        CheckType(name: 'check-relative-paths', defaultSeverity: AnalysisSeverity.warning)
      });
      final ValidationResult result = await validator.validate(skillDir);

      expect(result.isValid, isFalse);
      expect(result.errors, contains(contains('Absolute filepath found in link')));
    });

    test('ignores web URLs, emails, javascript, data URIs, and anchors', () async {
      final Directory skillDir = await Directory('${tempDir.path}/test-skill').create();
      await File('${skillDir.path}/SKILL.md').writeAsString(
          '${buildFrontmatter(name: 'test-skill')}- [Web link](http://example.com)\n- [Web TLS link](https://example.com)\n- [Email link](mailto:user@domain.com)\n- [JS link](javascript:alert(1))\n- [Data URI](data:image/png;base64,iVBORw)\n- [Anchor link](#section-name)\n');

      final validator = Validator(rules: {
        CheckType(name: 'check-relative-paths', defaultSeverity: AnalysisSeverity.warning)
      });
      final ValidationResult result = await validator.validate(skillDir);

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
      expect(result.warnings, isEmpty); // None of these should trigger local file checks
    });
  });
}
