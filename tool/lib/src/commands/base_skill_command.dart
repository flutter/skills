// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';

import '../models/skill_params.dart';
import '../services/gemini_service.dart';

/// Base command for skill operations.
abstract class BaseSkillCommand extends Command<void> {
  /// Creates a new [BaseSkillCommand].
  BaseSkillCommand({
    required this.httpClient,
    required this.logger,
    this.outputDir,
    this.environment,
  }) {
    argParser
      ..addOption('skill', help: 'Process only the specified skill by name.')
      ..addOption(
        'directory',
        abbr: 'd',
        help: 'The directory to output/search for skills.',
      )
      ..addOption(
        'thinking-budget',
        help:
            'The token budget for the model to "think". Defaults to ${GeminiService.defaultThinkingBudget} (recommended for technical documentation).',
        defaultsTo: GeminiService.defaultThinkingBudget.toString(),
      )
      ..addFlag(
        'debug',
        help: 'Enable debug logging, showing "Fetching" and "Model:" outputs.',
      );
  }

  /// The HTTP client used for fetching resources.
  final http.Client httpClient;

  /// The directory to output or find generated skills.
  final Directory? outputDir;

  /// Optional override for the environment variables, for testing.
  final Map<String, String>? environment;

  /// The logger for this command.
  final Logger logger;

  @override
  Future<void> run() async {
    final isDebug = argResults?['debug'] as bool? ?? false;
    if (isDebug && Logger.root.level == Level.INFO) {
      Logger.root.level = Level.ALL;
    }

    final inputFile = argResults!.rest.isNotEmpty
        ? argResults!.rest.first
        : 'resources/flutter_skills.yaml';

    final file = File(inputFile);
    if (!file.existsSync()) {
      logger.severe('Configuration file not found: $inputFile');
      return;
    }

    final yamlContent = file.readAsStringSync();
    final yamlList = loadYaml(yamlContent) as YamlList;
    final skills = yamlList
        .map(
          (e) => SkillParams.fromJson(
            jsonDecode(jsonEncode(e)) as Map<String, dynamic>,
          ),
        )
        .toList();

    final skillFilter = argResults?['skill'] as String?;
    final targetSkills = skillFilter != null
        ? skills.where((s) => s.name == skillFilter).toList()
        : skills;

    if (targetSkills.isEmpty) {
      if (skillFilter != null) {
        logger.warning('No skill found with name: $skillFilter');
      } else {
        logger.warning('No skills found in configuration file.');
      }
      return;
    }

    final apiKey = (environment ?? Platform.environment)['GEMINI_API_KEY'];
    if (apiKey == null) {
      logger.severe('GEMINI_API_KEY environment variable not set.');
      return;
    }

    final gemini = GeminiService(apiKey: apiKey, httpClient: httpClient);
    final directoryArg = argResults?['directory'] as String?;
    final outDir = directoryArg != null
        ? Directory(directoryArg)
        : (outputDir ?? Directory('../skills'));

    int thinkingBudget;
    try {
      thinkingBudget = int.parse(argResults!['thinking-budget'] as String);
    } on FormatException {
      logger.warning(
        'Invalid thinking-budget: ${argResults!['thinking-budget']}. Skipping.',
      );
      return;
    }

    for (final skill in targetSkills) {
      await runSkill(
        skill,
        gemini,
        outDir,
        thinkingBudget,
        configDir: file.parent,
      );
    }
  }

  /// Executes the command for a specific skill.
  Future<void> runSkill(
    SkillParams skill,
    GeminiService gemini,
    Directory outputDir,
    int thinkingBudget, {
    Directory? configDir,
  });
}
