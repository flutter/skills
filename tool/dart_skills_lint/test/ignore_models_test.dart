// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_skills_lint/src/models/ignore_entry.dart';
import 'package:dart_skills_lint/src/models/skills_ignores.dart';
import 'package:test/test.dart';

void main() {
  group('IgnoreEntry Serialization', () {
    test('fromJson parses rule_id and file_name', () {
      final Map<String, dynamic> json = {
        IgnoreEntry.ruleIdKey: 'description_too_long',
        IgnoreEntry.fileNameKey: 'SKILL.md',
      };
      final entry = IgnoreEntry.fromJson(json);
      expect(entry.ruleId, equals('description_too_long'));
      expect(entry.fileName, equals('SKILL.md'));
      expect(entry.used, isFalse); // Default
    });

    test('toJson serializes rule_id and file_name', () {
      final entry = IgnoreEntry(ruleId: 'description_too_long', fileName: 'SKILL.md');
      final Map<String, dynamic> json = entry.toJson();
      expect(json[IgnoreEntry.ruleIdKey], equals('description_too_long'));
      expect(json[IgnoreEntry.fileNameKey], equals('SKILL.md'));
      expect(json.containsKey('used'), isFalse); // Suppressed
    });
  });

  group('SkillsIgnores Serialization', () {
    test('fromJson parses nested skills map', () {
      final Map<String, dynamic> json = {
        SkillsIgnores.skillsKey: {
          'skill-a': [
            {IgnoreEntry.ruleIdKey: 'rule1', IgnoreEntry.fileNameKey: 'file1.md'},
          ],
        },
      };
      final ignores = SkillsIgnores.fromJson(json);
      expect(ignores.skills.containsKey('skill-a'), isTrue);
      expect(ignores.skills['skill-a']!.length, equals(1));
      expect(ignores.skills['skill-a']![0].ruleId, equals('rule1'));
    });

    test('toJson serializes nested skills map', () {
      final entry = IgnoreEntry(ruleId: 'rule1', fileName: 'file1.md');
      final ignores = SkillsIgnores(
        skills: {
          'skill-a': [entry],
        },
      );
      final Map<String, dynamic> json = ignores.toJson();

      expect(json.containsKey(SkillsIgnores.skillsKey), isTrue);
      final skillsJson = json[SkillsIgnores.skillsKey] as Map<String, dynamic>;
      expect(skillsJson.containsKey('skill-a'), isTrue);
      final skillAList = skillsJson['skill-a'] as List<dynamic>;
      final firstItem = skillAList[0] as Map<String, dynamic>;
      expect(firstItem[IgnoreEntry.ruleIdKey], equals('rule1'));
    });
  });
}
