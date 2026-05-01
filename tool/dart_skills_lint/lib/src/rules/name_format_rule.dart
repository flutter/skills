import 'dart:io';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';
import '../fixable_rule.dart';
import '../models/analysis_severity.dart';
import '../models/skill_context.dart';
import '../models/skill_rule.dart';
import '../models/validation_error.dart';

/// Enforces constraints on the skill name field.
class NameFormatRule extends SkillRule implements FixableRule {
  NameFormatRule({this.severity = defaultSeverity});

  static const String ruleName = 'invalid-skill-name';
  static const AnalysisSeverity defaultSeverity = AnalysisSeverity.error;

  @override
  String get name => ruleName;

  @override
  final AnalysisSeverity severity;

  static const maxNameLength = 64;
  static final _validNameRegex = RegExp(r'^[a-z0-9\-]+$');
  static const String _skillFileName = SkillContext.skillFileName;
  static const _nameFieldUrl = 'https://agentskills.io/specification#name-field';

  @override
  Future<List<ValidationError>> validate(SkillContext context) async {
    final errors = <ValidationError>[];

    if (context.parsedYaml == null) {
      return errors;
    }

    final YamlMap yaml = context.parsedYaml!;
    final String skillName = getNameNode(yaml)?.value.toString() ?? '';

    if (skillName.isEmpty) {
      return errors; // Handled by required fields check
    }

    if (skillName != skillName.toLowerCase()) {
      errors.add(
        ValidationError(
          ruleId: name,
          severity: severity,
          file: _skillFileName,
          message: 'Skill name must be lowercase: $skillName (see $_nameFieldUrl)',
        ),
      );
    }

    if (skillName.length > maxNameLength) {
      errors.add(
        ValidationError(
          ruleId: name,
          severity: severity,
          file: _skillFileName,
          message: 'Skill name too long. Maximum $maxNameLength characters (see $_nameFieldUrl)',
        ),
      );
    }

    if (!_validNameRegex.hasMatch(skillName)) {
      errors.add(
        ValidationError(
          ruleId: name,
          severity: severity,
          file: _skillFileName,
          message:
              'Skill name contains invalid characters. Only lowercase letters, digits, and hyphens allowed (see $_nameFieldUrl)',
        ),
      );
    }

    if (skillName.startsWith('-') || skillName.endsWith('-')) {
      errors.add(
        ValidationError(
          ruleId: name,
          severity: severity,
          file: _skillFileName,
          message: 'Skill name cannot have leading or trailing hyphens (see $_nameFieldUrl)',
        ),
      );
    }

    if (skillName.contains('--')) {
      errors.add(
        ValidationError(
          ruleId: name,
          severity: severity,
          file: _skillFileName,
          message: 'Skill name cannot have consecutive hyphens (see $_nameFieldUrl)',
        ),
      );
    }

    final String dirName = basename(context.directory.path);
    if (skillName != dirName) {
      errors.add(
        ValidationError(
          ruleId: name,
          severity: severity,
          file: _skillFileName,
          message:
              'Skill name ($skillName) must exactly match the parent directory name ($dirName) (see $_nameFieldUrl)',
        ),
      );
    }

    return errors;
  }

  @override
  Future<String> fix(String filePath, String currentContent, Directory directory) async {
    if (filePath != SkillContext.skillFileName) {
      return currentContent;
    }

    final RegExpMatch? match = SkillContext.skillStartRegex.firstMatch(currentContent);
    if (match == null) {
      return currentContent;
    }
    final String yamlStr = match.group(1)!;

    final dynamic yamlObj;
    try {
      yamlObj = loadYaml(yamlStr);
    } catch (e) {
      return currentContent;
    }

    if (yamlObj is! YamlMap) {
      return currentContent;
    }

    final YamlMap yaml = yamlObj;
    final YamlNode? nameNode = getNameNode(yaml);
    if (nameNode == null) {
      return currentContent;
    }

    final String dirName = basename(directory.path);

    final currentName = nameNode.value.toString();
    if (currentName == dirName) {
      return currentContent;
    }

    final int yamlOffset = currentContent.indexOf(yamlStr, match.start);

    // ignore: specify_nonobvious_local_variable_types
    final span = nameNode.span;
    final String before = currentContent.substring(0, yamlOffset + span.start.offset);
    final String after = currentContent.substring(yamlOffset + span.end.offset);

    return '$before$dirName$after';
  }

  /// Returns the YAML node for the skill name.
  @visibleForTesting
  static YamlNode? getNameNode(YamlMap yaml) {
    return yaml.nodes['name'];
  }
}
