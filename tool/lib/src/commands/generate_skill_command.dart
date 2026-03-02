// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../models/skill_params.dart';
import '../services/gemini_service.dart';
import 'base_skill_command.dart';

/// Command to generate skills from a configuration file.
class GenerateSkillCommand extends BaseSkillCommand {
  /// Creates a new [GenerateSkillCommand].
  GenerateSkillCommand({
    required super.httpClient,
    super.outputDir,
    super.environmentOverride,
  }) : super(logger: Logger('GenerateSkillCommand'));

  @override
  String get name => 'generate-skill';

  @override
  String get description => 'Generates skills from using yaml configuration.';

  @override
  Future<void> runSkill(
    SkillParams skill,
    GeminiService gemini,
    Directory outputDir,
    int thinkingBudget,
  ) async {
    logger.info('Generating skill: ${skill.name}...');

    try {
      final combinedMarkdown = await fetchAndConvertContent(
        skill.resources,
        httpClient,
        logger,
      );

      if (combinedMarkdown.isEmpty) {
        logger.warning('  No content fetched for ${skill.name}. Skipping.');
        return;
      }

      final generatedContent = await gemini.generateSkillContent(
        combinedMarkdown,
        skill.name,
        skill.description,
        instructions: skill.instructions,
        urls: skill.resources,
        thinkingBudget: thinkingBudget,
      );

      if (generatedContent != null && generatedContent.isNotEmpty) {
        final skillDir = Directory(p.join(outputDir.path, skill.name));
        if (!skillDir.existsSync()) {
          skillDir.createSync(recursive: true);
        }

        File(
          p.join(skillDir.path, 'SKILL.md'),
        ).writeAsStringSync(generatedContent);
        logger.info(
          '  Generated ${p.join(outputDir.path, skill.name, 'SKILL.md')}',
        );
      } else {
        logger.severe('  Failed to generate content for ${skill.name}');
      }
    } on Exception catch (e) {
      logger.severe('  Error processing ${skill.name}: $e');
    }
  }
}
