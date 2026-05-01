// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart_skills_lint/src/models/analysis_severity.dart';
import 'package:dart_skills_lint/src/models/skill_context.dart';
import 'package:dart_skills_lint/src/models/validation_error.dart';
import 'package:dart_skills_lint/src/rules/trailing_whitespace_rule.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('Trailing Whitespace Validation', () {
    test('passes for line with no trailing whitespace', () async {
      final rule = TrailingWhitespaceRule(severity: AnalysisSeverity.warning);
      final context = SkillContext(
        directory: Directory('dummy'),
        rawContent: '${buildFrontmatter(name: 'test-skill')}Line without trailing whitespace\n',
      );

      final List<ValidationError> errors = await rule.validate(context);

      expect(errors, isEmpty);
    });

    test('passes for line with exactly 2 trailing spaces (hard line break)', () async {
      final rule = TrailingWhitespaceRule(severity: AnalysisSeverity.warning);
      final context = SkillContext(
        directory: Directory('dummy'),
        rawContent: '${buildFrontmatter(name: 'test-skill')}Line with 2 spaces  \nNext line\n',
      );

      final List<ValidationError> errors = await rule.validate(context);

      expect(errors, isEmpty);
    });

    test('flags line with 1 trailing space as warning', () async {
      final rule = TrailingWhitespaceRule(severity: AnalysisSeverity.warning);
      final context = SkillContext(
        directory: Directory('dummy'),
        rawContent: '${buildFrontmatter(name: 'test-skill')}Line with 1 space \n',
      );

      final List<ValidationError> errors = await rule.validate(context);

      expect(errors.any((e) => e.message.contains('has 1 trailing space(s)')), isTrue);
    });

    test('flags line with 3 trailing spaces as warning', () async {
      final rule = TrailingWhitespaceRule(severity: AnalysisSeverity.warning);
      final context = SkillContext(
        directory: Directory('dummy'),
        rawContent: '${buildFrontmatter(name: 'test-skill')}Line with 3 spaces   \n',
      );

      final List<ValidationError> errors = await rule.validate(context);

      expect(errors.any((e) => e.message.contains('has 3 trailing space(s)')), isTrue);
    });

    test('flags line with trailing tabs as warning', () async {
      final rule = TrailingWhitespaceRule(severity: AnalysisSeverity.warning);
      final context = SkillContext(
        directory: Directory('dummy'),
        rawContent: '${buildFrontmatter(name: 'test-skill')}Line with tab\t\n',
      );

      final List<ValidationError> errors = await rule.validate(context);

      expect(errors.any((e) => e.message.contains('trailing whitespace containing tabs')), isTrue);
    });

    test('respects severity setting', () async {
      final rule = TrailingWhitespaceRule(severity: AnalysisSeverity.error);
      final context = SkillContext(
        directory: Directory('dummy'),
        rawContent: '${buildFrontmatter(name: 'test-skill')}Line with 1 space \n',
      );

      final List<ValidationError> errors = await rule.validate(context);

      expect(errors.length, 1);
      expect(errors.first.severity, AnalysisSeverity.error);
    });

    test(
      r'flags line with 1 trailing space before Windows line ending (\r\n) as warning',
      () async {
        final rule = TrailingWhitespaceRule(severity: AnalysisSeverity.warning);
        final context = SkillContext(
          directory: Directory('dummy'),
          rawContent: '${buildFrontmatter(name: 'test-skill')}Line with 1 space \r\n',
        );

        final List<ValidationError> errors = await rule.validate(context);

        expect(errors.any((e) => e.message.contains('has 1 trailing space(s)')), isTrue);
      },
    );

    test('flags line containing only whitespace (3 spaces) as warning', () async {
      final rule = TrailingWhitespaceRule(severity: AnalysisSeverity.warning);
      final context = SkillContext(
        directory: Directory('dummy'),
        rawContent: '${buildFrontmatter(name: 'test-skill')}   \n',
      );

      final List<ValidationError> errors = await rule.validate(context);

      expect(errors.any((e) => e.message.contains('has 3 trailing space(s)')), isTrue);
    });

    test('passes for line containing only 2 spaces', () async {
      final rule = TrailingWhitespaceRule(severity: AnalysisSeverity.warning);
      final context = SkillContext(
        directory: Directory('dummy'),
        rawContent: '${buildFrontmatter(name: 'test-skill')}  \n',
      );

      final List<ValidationError> errors = await rule.validate(context);

      expect(errors, isEmpty);
    });

    group('Trailing Whitespace Fix', () {
      test('removes trailing whitespace', () {
        final rule = TrailingWhitespaceRule();

        expect(rule.fixLine('Line with 1 space '), 'Line with 1 space');
        expect(rule.fixLine('Line with 3 spaces   '), 'Line with 3 spaces');
        expect(rule.fixLine('Line with tab\t'), 'Line with tab');
      });

      test('keeps exactly 2 spaces', () {
        final rule = TrailingWhitespaceRule();

        expect(rule.fixLine('Line with 2 spaces  '), 'Line with 2 spaces  ');
      });

      test('handles Windows line endings', () {
        final rule = TrailingWhitespaceRule();

        expect(rule.fixLine('Line with 1 space \r'), 'Line with 1 space\r');
        expect(rule.fixLine('Line with 3 spaces   \r'), 'Line with 3 spaces\r');
      });
    });
  });
}
