// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import '../models/skill_params.dart';
import 'base_yaml_command.dart';

/// Command to update the README.md file with a table of available skills.
class UpdateReadmeCommand extends BaseYamlCommand {
  /// Creates a new [UpdateReadmeCommand].
  UpdateReadmeCommand({super.outputDir})
    : super(logger: Logger('UpdateReadmeCommand'));

  @override
  String get name => 'update-readme';

  @override
  String get description =>
      'Updates the README.md with a table of available skills from the configuration.';

  @override
  Future<void> runWithSkills(
    List<SkillParams> skills,
    Directory outputDir, {
    Directory? configDir,
  }) async {
    final readmePath = argResults!.rest.length > 1
        ? argResults!.rest[1]
        : '../README.md';

    final readmeFile = File(readmePath);

    if (!readmeFile.existsSync()) {
      logger.severe('README file not found at $readmePath');
      return;
    }

    logger.info('Updating README at ${readmeFile.path}...');

    final content = readmeFile.readAsStringSync();

    // Generate the table
    final buffer = StringBuffer();
    buffer.writeln('| Skill | Description |');
    buffer.writeln('|---|---|');

    // Sort skills by name for consistency
    final sortedSkills = List<SkillParams>.from(skills)
      ..sort((a, b) => a.name.compareTo(b.name));

    for (final skill in sortedSkills) {
      // Calculate relative link from README to the SKILL.md file
      final skillFile = File(p.join(outputDir.path, skill.name, 'SKILL.md'));
      final relativeLink = p.relative(
        skillFile.path,
        from: readmeFile.parent.path,
      );

      buffer.writeln(
        '| [${skill.name}]($relativeLink) | ${skill.description} |',
      );
    }

    final newTable = buffer.toString();

    // Find where to insert the table
    final sectionRegex = RegExp(
      r'^## (Available Skills|List of Skills|Skills List|Skill Index)',
      caseSensitive: false,
      multiLine: true,
    );
    final match = sectionRegex.firstMatch(content);

    String updatedContent;
    if (match != null) {
      // Find the end of the line with the header
      final headerEnd = content.indexOf('\n', match.start);
      // Find the next section header or end of file
      final nextSectionIndex = content.indexOf(
        RegExp(r'\n##\s', multiLine: true),
        headerEnd + 1,
      );

      final prefix = content.substring(
        0,
        headerEnd == -1 ? content.length : headerEnd + 1,
      );
      final suffix = nextSectionIndex != -1
          ? content.substring(nextSectionIndex)
          : '';

      updatedContent = '${prefix.trimRight()}\n\n$newTable${suffix.trimLeft()}';
    } else {
      // Add a new section at the end
      updatedContent =
          '${content.trimRight()}\n\n## Available Skills\n\n$newTable';
    }

    readmeFile.writeAsStringSync('${updatedContent.trimRight()}\n');
    logger.info('Successfully updated $readmePath');
  }
}
