// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';

import '../models/skill_params.dart';

/// Base command for operations that read skills from a YAML file.
abstract class BaseYamlCommand extends Command<void> {
  /// Creates a new [BaseYamlCommand].
  BaseYamlCommand({required this.logger, this.outputDir}) {
    argParser
      ..addOption('skill', help: 'Process only the specified skill by name.')
      ..addOption(
        'directory',
        abbr: 'd',
        help: 'The directory to search for skills.',
      );
  }

  /// The logger for this command.
  final Logger logger;

  /// The directory to find generated skills.
  final Directory? outputDir;

  @override
  Future<void> run() async {
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

    final directoryArg = argResults?['directory'] as String?;
    final outDir = directoryArg != null
        ? Directory(directoryArg)
        : (outputDir ?? Directory('../skills'));

    await runWithSkills(targetSkills, outDir, configDir: file.parent);
  }

  /// Executes the command with the parsed and filtered list of skills.
  Future<void> runWithSkills(
    List<SkillParams> skills,
    Directory outputDir, {
    Directory? configDir,
  });
}
