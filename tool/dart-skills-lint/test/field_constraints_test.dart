import 'dart:io';

import 'package:dart_skills_lint/src/validator.dart';
import 'package:test/test.dart';

import 'test_utils.dart';

void main() {
  group('Field Specific Constraints Validation', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('fields_test.');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('Skill Name', () {
      test('fails if not lowercase', () async {
        final Directory skillDir = await Directory('${tempDir.path}/Skill-Name').create();
        await File('${skillDir.path}/SKILL.md').writeAsString('${buildFrontmatter()}Body');
        final validator = Validator();
        final ValidationResult result = await validator.validate(skillDir);
        expect(result.isValid, isFalse);
        expect(result.errors, contains(contains('lowercase')));
      });

      test('fails if too long (> ${Validator.maxNameLength} chars)', () async {
        final String longName = 'a' * (Validator.maxNameLength + 1);
        final Directory skillDir = await Directory('${tempDir.path}/$longName').create();
        await File('${skillDir.path}/SKILL.md')
            .writeAsString('${buildFrontmatter(name: longName)}Body');
        final validator = Validator();
        final ValidationResult result = await validator.validate(skillDir);
        expect(result.isValid, isFalse);
        expect(result.errors, contains(contains('Maximum ${Validator.maxNameLength} characters')));
      });

      test('fails if contains invalid characters', () async {
        final Directory skillDir = await Directory('${tempDir.path}/skill_name').create();
        await File('${skillDir.path}/SKILL.md')
            .writeAsString('${buildFrontmatter(name: 'skill_name')}Body');
        final validator = Validator();
        final ValidationResult result = await validator.validate(skillDir);
        expect(result.isValid, isFalse);
        expect(result.errors, contains(contains('lowercase letters, digits, and hyphens')));
      });

      test('fails if has leading hyphen', () async {
        final Directory skillDir = await Directory('${tempDir.path}/-skill-name').create();
        await File('${skillDir.path}/SKILL.md')
            .writeAsString('${buildFrontmatter(name: '-skill-name')}Body');
        final validator = Validator();
        final ValidationResult result = await validator.validate(skillDir);
        expect(result.isValid, isFalse);
        expect(result.errors, contains(contains('leading or trailing hyphens')));
      });

      test('fails if has trailing hyphen', () async {
        final Directory skillDir = await Directory('${tempDir.path}/skill-name-').create();
        await File('${skillDir.path}/SKILL.md')
            .writeAsString('${buildFrontmatter(name: 'skill-name-')}Body');
        final validator = Validator();
        final ValidationResult result = await validator.validate(skillDir);
        expect(result.isValid, isFalse);
        expect(result.errors, contains(contains('leading or trailing hyphens')));
      });

      test('fails if has consecutive hyphens', () async {
        final Directory skillDir = await Directory('${tempDir.path}/skill--name').create();
        await File('${skillDir.path}/SKILL.md')
            .writeAsString('${buildFrontmatter(name: 'skill--name')}Body');
        final validator = Validator();
        final ValidationResult result = await validator.validate(skillDir);
        expect(result.isValid, isFalse);
        expect(result.errors, contains(contains('consecutive hyphens')));
      });

      test('fails if name does not match directory name', () async {
        final Directory skillDir = await Directory('${tempDir.path}/wrong-name').create();
        await File('${skillDir.path}/SKILL.md')
            .writeAsString('${buildFrontmatter(name: 'right-name')}Body');
        final validator = Validator();
        final ValidationResult result = await validator.validate(skillDir);
        expect(result.isValid, isFalse);
        expect(result.errors,
            contains(contains('must exactly match the name of its parent directory')));
      });
    });

    group('Description', () {
      test('fails if too long (> ${Validator.maxDescriptionLength} chars)', () async {
        final String longDesc = 'a' * (Validator.maxDescriptionLength + 1);
        final Directory skillDir = await Directory('${tempDir.path}/skill-name').create();
        await File('${skillDir.path}/SKILL.md')
            .writeAsString('${buildFrontmatter(name: 'skill-name', description: longDesc)}Body');
        final validator = Validator();
        final ValidationResult result = await validator.validate(skillDir);
        expect(result.isValid, isFalse);
        expect(result.errors,
            contains(contains('Maximum ${Validator.maxDescriptionLength} characters')));
      });
    });

    group('Compatibility', () {
      test('fails if too long (> ${Validator.maxCompatibilityLength} chars)', () async {
        final String longComp = 'a' * (Validator.maxCompatibilityLength + 1);
        final Directory skillDir = await Directory('${tempDir.path}/skill-name').create();
        await File('${skillDir.path}/SKILL.md').writeAsString('''
---
name: skill-name
description: A test skill
compatibility: $longComp
---
Body''');
        final validator = Validator();
        final ValidationResult result = await validator.validate(skillDir);
        expect(result.isValid, isFalse);
        expect(result.errors,
            contains(contains('Maximum ${Validator.maxCompatibilityLength} characters')));
      });
    });
  });
}
