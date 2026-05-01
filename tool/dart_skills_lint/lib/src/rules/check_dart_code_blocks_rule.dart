// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import '../models/analysis_severity.dart';
import '../models/skill_context.dart';
import '../models/skill_rule.dart';
import '../models/validation_error.dart';

/// Validates that Dart code blocks in the skill file are valid by running them with popmark.
///
/// Expected YAML frontmatter structure in SKILL.md:
/// ```yaml
/// metadata:
///   popmark:
///     imports: "dart:io;dart:math"
///     template: "path/to/template.txt"
/// ```
class CheckDartCodeBlocksRule extends SkillRule {
  CheckDartCodeBlocksRule({this.severity = defaultSeverity});

  static const String ruleName = 'check-dart-code-blocks';
  static const AnalysisSeverity defaultSeverity = AnalysisSeverity.disabled;

  @override
  String get name => ruleName;

  @override
  final AnalysisSeverity severity;

  @override
  Future<List<ValidationError>> validate(SkillContext context) async {
    final errors = <ValidationError>[];

    if (context.parsedYaml == null) {
      return errors;
    }

    final YamlMap yaml = context.parsedYaml!;
    final Object? metadata = yaml['metadata'];
    String? imports;
    String? template;

    if (metadata is YamlMap) {
      final Object? popmark = metadata['popmark'];
      if (popmark is YamlMap) {
        imports = popmark['imports'] as String?;
        template = popmark['template'] as String?;
      }
    }

    final skillFile = File(p.join(context.directory.path, SkillContext.skillFileName));
    if (!skillFile.existsSync()) {
      return errors; // Should be handled by another rule, but safe check.
    }

    // Create a copy of the file to avoid modifying the original during validation.
    final String tempFilePath = p.join(context.directory.path, '${SkillContext.skillFileName}.tmp');
    final tempFile = File(tempFilePath);

    try {
      await skillFile.copy(tempFilePath);

      final args = <String>[
        'run',
        'popmark',
        tempFilePath,
        '--no-cache',
        '--cleanup',
      ];

      if (imports != null) {
        args.add('--imports');
        args.add(imports);
      }

      if (template != null) {
        args.add('--template');
        args.add(template);
      }

      final ProcessResult result = await Process.run('dart', args);

      if (result.exitCode != 0) {
        errors.add(ValidationError(
          ruleId: name,
          severity: severity,
          file: SkillContext.skillFileName,
          message:
              'Failed to validate Dart code blocks. Popmark exited with code ${result.exitCode}.\nStdout: ${result.stdout}\nStderr: ${result.stderr}',
        ));
      } else {
        // Popmark might exit with 0 but insert error messages into the file.
        // We read the file and check for typical Dart compiler errors.
        final String updatedContent = await tempFile.readAsString();
        final errorRegex = RegExp(r'\.dart:\d+:\d+: Error:');
        if (errorRegex.hasMatch(updatedContent)) {
          errors.add(ValidationError(
            ruleId: name,
            severity: severity,
            file: SkillContext.skillFileName,
            message: 'Dart code blocks contained compilation errors.',
          ));
        }
      }
    } catch (e) {
      errors.add(ValidationError(
        ruleId: name,
        severity: severity,
        file: SkillContext.skillFileName,
        message: 'Error running popmark: $e',
      ));
    } finally {
      if (tempFile.existsSync()) {
        await tempFile.delete();
      }
    }

    return errors;
  }
}
