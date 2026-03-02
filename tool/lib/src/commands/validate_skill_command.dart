// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../models/skill_params.dart';
import '../services/gemini_service.dart';
import 'base_skill_command.dart';

/// Command to validate skills by re-generating and comparing with existing skills.
class ValidateSkillCommand extends BaseSkillCommand {
  /// Creates a new [ValidateSkillCommand].
  ValidateSkillCommand({
    required super.httpClient,
    super.outputDir,
    this.validationDir,
  }) : super(logger: Logger('ValidateSkillCommand'));

  /// The directory to output validation reports.
  final Directory? validationDir;

  @override
  String get name => 'validate-skill';

  @override
  String get description =>
      'Validates skills using existing skill files and yaml configuration.';

  @override
  Future<void> runSkill(
    SkillParams skill,
    GeminiService gemini,
    Directory outputDir,
    int thinkingBudget, {
    Directory? configDir,
  }) async {
    logger.info('Validating skill: ${skill.name}...');

    try {
      // Re-generate markdown content
      final markdown = await fetchAndConvertContent(
        skill.resources,
        httpClient,
        logger,
        configDir: configDir,
      );

      if (markdown.isEmpty) {
        logger.warning(
          '  No content fetched for ${skill.name}. Skipping validation.',
        );
        return;
      }

      // Read existing content
      final existingSkillFile = File(
        p.join(outputDir.path, skill.name, 'SKILL.md'),
      );
      if (!existingSkillFile.existsSync()) {
        logger.warning(
          '  Existing skill file not found at ${existingSkillFile.path}',
        );
        return;
      }

      final existingSkillFileContent = existingSkillFile.readAsStringSync();

      // Check for verbatim name and description
      if (!existingSkillFileContent.contains('name: ${skill.name}')) {
        logger.severe(
          '  Validation Failed: Skill name mismatch in ${existingSkillFile.path}. '
          'Expected "name: ${skill.name}"',
        );
      }

      // Extract metadata from existing content
      final generationDate =
          RegExp(
            'last_modified: (.*)',
          ).firstMatch(existingSkillFileContent)?.group(1) ??
          'Unknown';
      final modelName =
          RegExp(
            'model: (.*)',
          ).firstMatch(existingSkillFileContent)?.group(1) ??
          'Unknown';

      // Compare
      logger.info('  Comparing versions...');
      final result = await gemini.validateExistingSkillContent(
        markdown,
        skill.name,
        skill.instructions ?? 'No instructions provided',
        generationDate,
        modelName,
        existingSkillFileContent,
        thinkingBudget: thinkingBudget,
      );

      if (result != null) {
        final valDirBase = validationDir ?? Directory('validation');
        final valDir = Directory(p.join(valDirBase.path, skill.name));
        if (!valDir.existsSync()) {
          valDir.createSync(recursive: true);
        }

        File(p.join(valDir.path, 'validation.md')).writeAsStringSync(result);

        // Extract and log the grade
        final gradeMatch = RegExp(r'Grade:\s*(\d+)').firstMatch(result);
        final grade = gradeMatch?.group(1);

        logger.info(
          '  Validation report written to ${p.join(valDir.path, 'validation.md')} '
          '${grade != null ? '(Grade: $grade)' : ''}',
        );
      } else {
        logger.severe(
          '  Failed to generate validation report for ${skill.name}',
        );
      }
    } on Exception catch (e) {
      logger.severe('  Error validating ${skill.name}: $e');
    }
  }
}
