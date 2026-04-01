import 'package:dart_skills_lint/src/models/ignore_entry.dart';
import 'package:dart_skills_lint/src/models/skills_ignores.dart';
import 'package:test/test.dart';

void main() {
  group('IgnoreEntry Serialization', () {
    test('fromJson parses rule_id and file_name', () {
      final json = {
        'rule_id': 'description_too_long',
        'file_name': 'SKILL.md',
      };
      final entry = IgnoreEntry.fromJson(json);
      expect(entry.ruleId, equals('description_too_long'));
      expect(entry.fileName, equals('SKILL.md'));
      expect(entry.used, isFalse); // Default
    });

    test('toJson serializes rule_id and file_name', () {
      final entry = IgnoreEntry(ruleId: 'description_too_long', fileName: 'SKILL.md');
      final Map<String, dynamic> json = entry.toJson();
      expect(json['rule_id'], equals('description_too_long'));
      expect(json['file_name'], equals('SKILL.md'));
      expect(json.containsKey('used'), isFalse); // Suppressed
    });
  });

  group('SkillsIgnores Serialization', () {
    test('fromJson parses nested skills map', () {
      final json = {
        'skills': {
          'skill-a': [
            {'rule_id': 'rule1', 'file_name': 'file1.md'},
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
      final ignores = SkillsIgnores(skills: {
        'skill-a': [entry]
      });
      final Map<String, dynamic> json = ignores.toJson();

      expect(json.containsKey('skills'), isTrue);
      final skillsJson = json['skills'] as Map<String, dynamic>;
      expect(skillsJson.containsKey('skill-a'), isTrue);
      expect(skillsJson['skill-a'][0]['rule_id'], equals('rule1'));
    });
  });
}
