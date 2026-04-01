import 'dart:io';

import 'package:dart_skills_lint/src/validator.dart';
import 'package:test/test.dart';

void main() {
  group('Directory Structure Validation', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('skill_test.');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('fails if directory does not exist', () async {
      final nonExistentDir = Directory('path/to/nothing');
      final validator = Validator();
      final ValidationResult result = await validator.validate(nonExistentDir);

      expect(result.isValid, isFalse);
      expect(result.errors, contains(contains('Directory does not exist')));
    });

    test('fails if path is a file', () async {
      final file = File('${tempDir.path}/some_file');
      await file.create();
      final validator = Validator();
      final ValidationResult result = await validator.validate(Directory(file.path));

      expect(result.isValid, isFalse);
      expect(result.errors, contains(contains('is not a directory')));
    });

    test('fails if SKILL.md is missing', () async {
      final validator = Validator();
      final ValidationResult result = await validator.validate(tempDir);

      expect(result.isValid, isFalse);
      expect(result.errors, contains(contains('SKILL.md is missing')));
    });

    test('passes if directory exists and contains SKILL.md', () async {
      final skillDir = Directory('${tempDir.path}/test-skill');
      await skillDir.create();
      await File('${skillDir.path}/SKILL.md').writeAsString('''
---
name: test-skill
description: A test skill
---
Body''');

      final validator = Validator();
      final ValidationResult result = await validator.validate(skillDir);

      expect(result.isValid, isTrue, reason: result.errors.isEmpty ? '' : result.errors.first);
      expect(result.errors, isEmpty);
    });
  });
}
