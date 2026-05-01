// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'models/analysis_severity.dart';
import 'models/check_type.dart';
import 'models/skill_context.dart';
import 'models/skill_rule.dart';
import 'models/validation_error.dart';
import 'rule_registry.dart';

const _dirStructureUrl = 'https://agentskills.io/specification#directory-structure';

final _log = Logger('dart_skills_lint');

/// Validates agent skill directories against the Agent Skills specification.
class Validator {
  Validator({Map<String, AnalysisSeverity>? ruleOverrides, List<SkillRule>? customRules})
    : _customSeverities = ruleOverrides ?? {},
      _rules = _buildRules(ruleOverrides ?? {}, customRules ?? []);
  static const String _skillFileName = SkillContext.skillFileName;

  /// The name of the special check for missing files or directories.
  static const String pathDoesNotExist = 'path-does-not-exist';

  /// The name of the special check for inaccessible files.
  static const String skillFileInaccessible = 'skill-file-inaccessible';

  /// The name of the special check for unexpected errors.
  static const String unexpectedError = 'unexpected-error';

  final Map<String, AnalysisSeverity> _customSeverities;
  final List<SkillRule> _rules;

  /// Returns the rules used by this validator.
  List<SkillRule> get rules => _rules;

  AnalysisSeverity _getSeverity(String name, AnalysisSeverity defaultSeverity) {
    return _customSeverities[name] ?? defaultSeverity;
  }

  /// Validates a single skill directory.
  ///
  /// Scans the directory for `SKILL.md`, parses its YAML metadata, and validates
  /// constraints like name format and field lengths using registered rules.
  Future<ValidationResult> validate(Directory dir) async {
    final validationErrors = <ValidationError>[];

    final bool isValidDir = await _checkDirectoryStructure(dir, validationErrors);
    if (!isValidDir) {
      return ValidationResult(validationErrors: validationErrors);
    }

    final skillMdFile = File(p.join(dir.path, _skillFileName));
    String content;
    try {
      content = await skillMdFile.readAsString();
    } on FileSystemException catch (e) {
      validationErrors.add(
        ValidationError(
          ruleId: skillFileInaccessible,
          file: skillMdFile.path,
          message: 'Failed to read $_skillFileName: $e',
          severity: _getSeverity(skillFileInaccessible, AnalysisSeverity.error),
        ),
      );
      return ValidationResult(validationErrors: validationErrors);
    } catch (e) {
      validationErrors.add(
        ValidationError(
          ruleId: unexpectedError,
          file: skillMdFile.path,
          message: 'Unexpected error reading $_skillFileName: $e',
          severity: _getSeverity(unexpectedError, AnalysisSeverity.error),
        ),
      );
      return ValidationResult(validationErrors: validationErrors);
    }

    YamlMap? parsedYaml;
    String? yamlParsingError;
    try {
      final RegExpMatch? match = SkillContext.skillStartRegex.firstMatch(content);
      if (match != null) {
        final String yamlStr = match.group(1)!;
        final Object? doc = loadYaml(yamlStr);
        if (doc is YamlMap) {
          parsedYaml = doc;
        } else {
          yamlParsingError = 'YAML frontmatter is not a map';
        }
      } else {
        yamlParsingError = 'Missing YAML metadata in $_skillFileName';
      }
    } catch (e) {
      yamlParsingError = 'Failed to parse YAML: $e';
    }

    final context = SkillContext(
      directory: dir,
      rawContent: content,
      parsedYaml: parsedYaml,
      yamlParsingError: yamlParsingError,
    );

    for (final SkillRule rule in _rules) {
      final List<ValidationError> errors = await rule.validate(context);
      for (final error in errors) {
        if (error.severity != rule.severity) {
          _log.warning(
            'Rule "${rule.name}" used severity ${error.severity} instead of defined ${rule.severity}.',
          );
        }
      }
      validationErrors.addAll(errors);
    }

    return ValidationResult(validationErrors: validationErrors, context: context);
  }

  static List<SkillRule> _buildRules(
    Map<String, AnalysisSeverity> customSeverities,
    List<SkillRule> customRules,
  ) {
    final rules = <SkillRule>[];
    final seenNames = <String>{};

    void addRule(SkillRule rule) {
      if (rule.severity != AnalysisSeverity.disabled) {
        if (seenNames.contains(rule.name)) {
          throw ArgumentError('Duplicate rule name detected: ${rule.name}');
        }
        seenNames.add(rule.name);
        rules.add(rule);
      }
    }

    for (final CheckType check in RuleRegistry.allChecks) {
      final AnalysisSeverity severity = customSeverities[check.name] ?? check.defaultSeverity;
      final SkillRule? rule = RuleRegistry.createRule(check.name, severity);
      if (rule != null) {
        addRule(rule);
      }
    }

    customRules.forEach(addRule);

    return rules;
  }

  Future<bool> _checkDirectoryStructure(
    Directory dir,
    List<ValidationError> validationErrors,
  ) async {
    final AnalysisSeverity pathDoesNotExistSeverity = _getSeverity(
      pathDoesNotExist,
      AnalysisSeverity.error,
    );

    if (!dir.existsSync()) {
      if (File(dir.path).existsSync()) {
        validationErrors.add(
          ValidationError(
            ruleId: pathDoesNotExist,
            file: dir.path,
            message: 'Path is not a directory: ${dir.path} (see $_dirStructureUrl)',
            severity: pathDoesNotExistSeverity,
          ),
        );
      } else {
        validationErrors.add(
          ValidationError(
            ruleId: pathDoesNotExist,
            file: dir.path,
            message: 'Directory does not exist: ${dir.path} (see $_dirStructureUrl)',
            severity: pathDoesNotExistSeverity,
          ),
        );
      }
      return false;
    }

    final skillMdFile = File(p.join(dir.path, _skillFileName));
    if (!skillMdFile.existsSync()) {
      validationErrors.add(
        ValidationError(
          ruleId: pathDoesNotExist,
          file: dir.path,
          message: '$_skillFileName is missing in directory: ${dir.path} (see $_dirStructureUrl)',
          severity: pathDoesNotExistSeverity,
        ),
      );
      return false;
    }
    return true;
  }
}

/// The result of a skill directory validation attempt.
class ValidationResult {
  ValidationResult({
    this.validationErrors = const [],
    List<String> warnings = const [],
    this.context,
  }) : _manualWarnings = warnings;

  /// The context used during validation.
  final SkillContext? context;

  /// Whether the skill directory is valid according to the specification.
  bool get isValid =>
      !validationErrors.any((e) => e.severity == AnalysisSeverity.error && !e.isIgnored);

  /// A list of structured validation errors found.
  final List<ValidationError> validationErrors;

  final List<String> _manualWarnings;

  /// A list of error messages for failing checks (excluding ignored ones).
  List<String> get errors => validationErrors
      .where((e) => e.severity == AnalysisSeverity.error && !e.isIgnored)
      .map((e) => e.message)
      .toList();

  /// A list of warning messages for suboptimal setups or recommendations.
  List<String> get warnings => [
    ..._manualWarnings,
    ...validationErrors
        .where((e) => e.severity == AnalysisSeverity.warning && !e.isIgnored)
        .map((e) => e.message),
  ];
}
