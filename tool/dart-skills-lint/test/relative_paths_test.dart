import 'dart:io';

import 'package:dart_skills_lint/src/models/check_type.dart';
import 'package:dart_skills_lint/src/validator.dart';
import 'package:test/test.dart';

void main() {
  group('Relative Paths Validation', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('paths_test.');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('passes with valid relative file path (existing file)', () async {
      final Directory skillDir = await Directory('${tempDir.path}/test-skill').create();
      await File('${skillDir.path}/SKILL.md').writeAsString('''
---
name: test-skill
description: A test skill
---
[Link to a reference](references/DETAILS.md)
''');

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
      await File('${skillDir.path}/SKILL.md').writeAsString('''
---
name: test-skill
description: A test skill
---
[Link to a references file missing](references/MISSING.md)
''');

      final validator = Validator(rules: {
        CheckType(name: 'check-relative-paths', defaultSeverity: AnalysisSeverity.warning)
      });
      final ValidationResult result = await validator.validate(skillDir);

      expect(result.isValid, isTrue);
      expect(result.warnings, contains(contains('Linked file does not exist')));
    });

    test('fails with absolute file path', () async {
      final Directory skillDir = await Directory('${tempDir.path}/test-skill').create();
      await File('${skillDir.path}/SKILL.md').writeAsString('''
---
name: test-skill
description: A test skill
---
[Absolute path link](/tmp/some_absolute_path/file.md)
''');

      final validator = Validator(rules: {
        CheckType(name: 'check-relative-paths', defaultSeverity: AnalysisSeverity.warning)
      });
      final ValidationResult result = await validator.validate(skillDir);

      expect(result.isValid, isFalse);
      expect(result.errors, contains(contains('Absolute filepath found in link')));
    });

    test('ignores web URLs, emails, javascript, data URIs, and anchors', () async {
      final Directory skillDir = await Directory('${tempDir.path}/test-skill').create();
      await File('${skillDir.path}/SKILL.md').writeAsString('''
---
name: test-skill
description: A test skill
---
- [Web link](http://example.com)
- [Web TLS link](https://example.com)
- [Email link](mailto:user@domain.com)
- [JS link](javascript:alert(1))
- [Data URI](data:image/png;base64,iVBORw)
- [Anchor link](#section-name)
''');

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
