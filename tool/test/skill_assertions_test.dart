// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('Skill Assertions', () {
    final skillsDir = Directory('../skills');

    test('skills directory exists', () {
      expect(
        skillsDir.existsSync(),
        isTrue,
        reason: 'skills directory should exist',
      );
    });

    final skillDirs = skillsDir.listSync().whereType<Directory>();

    for (final dir in skillDirs) {
      final skillName = path.basename(dir.path);

      group('Skill: $skillName', () {
        test('has exactly one SKILL.md', () {
          final files = dir
              .listSync()
              .whereType<File>()
              .where((f) => path.basename(f.path) == 'SKILL.md')
              .toList();
          expect(
            files.length,
            equals(1),
            reason: 'Should have exactly one SKILL.md file',
          );
        });

        test('SKILL.md has valid frontmatter', () {
          final skillFile = File(path.join(dir.path, 'SKILL.md'));
          if (!skillFile.existsSync()) return;

          final content = skillFile.readAsStringSync();
          final frontmatterMatch = RegExp(
            r'^---\n([\s\S]*?)\n---',
          ).firstMatch(content);

          expect(
            frontmatterMatch,
            isNotNull,
            reason:
                'SKILL.md should start with YAML frontmatter bounded by ---',
          );

          final yamlContent = frontmatterMatch!.group(1)!;
          final yaml = loadYaml(yamlContent) as Map;

          // 1. Name matches directory name
          expect(
            yaml['name'],
            equals(skillName),
            reason: 'name in SKILL.md should match directory name',
          );

          expect(
            skillName,
            matches(r'^[a-z0-9]+(?:-[a-z0-9]+)*(?:_[0-9]+)?$'),
            reason:
                'Skill name should be kebab-case (lowercase, numbers, hyphens), '
                'with an optional numeric suffix starting with underscore (e.g. _2)',
          );

          // 2. Name validation strategy
          final isDocSkill =
              (yaml['name'] as String).startsWith('dart-docs-') ||
              (yaml['name'] as String).startsWith('flutter-docs-');

          // 3. Required fields
          expect(
            yaml,
            contains('description'),
            reason: 'Should have description',
          );

          // Metadata validation (Strict only for doc skills)
          if (isDocSkill) {
            expect(
              yaml,
              contains('metadata'),
              reason: 'Doc skills should have metadata',
            );
            final metadata = yaml['metadata'] as Map;
            expect(
              metadata,
              contains('url'),
              reason: 'Metadata should have url',
            );
            expect(
              metadata,
              contains('model'),
              reason: 'Metadata should have model',
            );

            final hasLastModified = metadata.containsKey('last_modified');
            expect(
              hasLastModified,
              isTrue,
              reason: 'Metadata should have last_modified',
            );

            // URL validation
            final url = Uri.tryParse(metadata['url'] as String);
            expect(url, isNotNull, reason: 'URL should be valid');
            expect(url!.hasScheme, isTrue, reason: 'URL should have scheme');
          }
        });
      });
    }
  });
}
