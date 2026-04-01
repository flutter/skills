import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'models/check_type.dart';
import 'models/validation_error.dart';
import 'rules.dart';

/// The result of a skill directory validation attempt.
class ValidationResult {
  ValidationResult({
    this.validationErrors = const [],
    List<String> warnings = const [],
  }) : _manualWarnings = warnings;

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

/// Validates agent skill directories against the Agent Skills specification.
class Validator {
  Validator({Set<CheckType>? rules})
      : _ruleOverrides = rules != null ? {for (var r in rules) r.name: r} : {};
  static const _skillFileName = 'SKILL.md';

  final Map<String, CheckType> _ruleOverrides;

  CheckType _getRule(CheckType defaultRule) {
    return _ruleOverrides[defaultRule.name] ?? defaultRule;
  }

  static const _dirStructureUrl = ' (see https://agentskills.io/specification#directory-structure)';
  static const _metadataUrl = ' (see https://agentskills.io/specification#frontmatter)';
  static const _nameFieldUrl = ' (see https://agentskills.io/specification#name-field)';
  static const _descriptionFieldUrl =
      ' (see https://agentskills.io/specification#description-field)';
  static const _compatibilityFieldUrl =
      ' (see https://agentskills.io/specification#compatibility-field)';

  static const _nameField = 'name';
  static const _descriptionField = 'description';
  static const _licenseField = 'license';
  static const _allowedToolsField = 'allowed-tools';
  static const _metadataField = 'metadata';
  static const _compatibilityField = 'compatibility';
  // Frequently used in google skills
  static const _categoryField = 'category';
  static const _tagsField = 'tags';
  static const _versionField = 'version';
  static const _evalTaskField = 'eval_task';

  static const Set<String> _allowedFields = {
    _nameField,
    _descriptionField,
    _licenseField,
    _allowedToolsField,
    _metadataField,
    _compatibilityField,
    _categoryField,
    _tagsField,
    _versionField,
    _evalTaskField,
  };

  static const Set<String> _requiredFields = {
    _nameField,
    _descriptionField,
  };

  @visibleForTesting
  static const maxNameLength = 64;

  @visibleForTesting
  static const maxDescriptionLength = 1024;

  @visibleForTesting
  static const maxCompatibilityLength = 500;

  static final _skillStartRegex = RegExp(r'^---\s*\n(.*?)\n---\s*\n', dotAll: true);
  static final _validNameRegex = RegExp(r'^[a-z0-9\-]+$');
  static final _markdownLinkRegex = RegExp(r'\[.*?\]\((.*?)\)');

  /// Validates a single skill directory.
  ///
  /// Scans the directory for `SKILL.md`, parses its YAML metadata, and validates
  /// constraints like name format and field lengths.
  ///
  /// The [relativePathsSeverity] and [absolutePathsSeverity] determine how link violations are handled.
  Future<ValidationResult> validate(Directory dir) async {
    final validationErrors = <ValidationError>[];
    final warnings = <String>[];

    final bool isValidDir = await _checkDirectoryStructure(dir, validationErrors);
    if (!isValidDir) {
      return ValidationResult(validationErrors: validationErrors, warnings: warnings);
    }

    final skillMdFile = File(p.join(dir.path, _skillFileName));
    final String content = await skillMdFile.readAsString();
    final RegExpMatch? match = _skillStartRegex.firstMatch(content);

    if (match == null) {
      validationErrors.add(ValidationError(
          ruleId: _getRule(validYamlMetadataCheck).name,
          severity: _getRule(validYamlMetadataCheck).severity,
          file: _skillFileName,
          message: 'Missing YAML metadata in $_skillFileName$_metadataUrl'));
    } else {
      final String yamlStr = match.group(1)!;
      _parseMetadataFields(yamlStr, dir, validationErrors, warnings);

      final AnalysisSeverity relativePathsSeverity = _getRule(relativePathsCheck).severity;
      final AnalysisSeverity absolutePathsSeverity = _getRule(absolutePathsCheck).severity;

      if (relativePathsSeverity != AnalysisSeverity.disabled ||
          absolutePathsSeverity != AnalysisSeverity.disabled) {
        final String restOfContent = content.substring(match.end);
        await _validateRelativeLinks(restOfContent, dir, validationErrors, warnings);
      }
    }

    return ValidationResult(
      validationErrors: validationErrors,
      warnings: warnings,
    );
  }

  Future<bool> _checkDirectoryStructure(
      Directory dir, List<ValidationError> validationErrors) async {
    if (!await dir.exists()) {
      if (await File(dir.path).exists()) {
        validationErrors.add(ValidationError(
            ruleId: _getRule(pathDoesNotExistCheck).name,
            file: dir.path,
            message: 'Path is not a directory: ${dir.path}$_dirStructureUrl',
            severity: _getRule(pathDoesNotExistCheck).severity));
      } else {
        validationErrors.add(ValidationError(
            ruleId: _getRule(pathDoesNotExistCheck).name,
            file: dir.path,
            message: 'Directory does not exist: ${dir.path}$_dirStructureUrl',
            severity: _getRule(pathDoesNotExistCheck).severity));
      }
      return false;
    }

    final skillMdFile = File(p.join(dir.path, _skillFileName));
    if (!await skillMdFile.exists()) {
      validationErrors.add(ValidationError(
          ruleId: _getRule(pathDoesNotExistCheck).name,
          file: dir.path,
          message: '$_skillFileName is missing in directory: ${dir.path}$_dirStructureUrl',
          severity: _getRule(pathDoesNotExistCheck).severity));
      return false;
    }
    return true;
  }

  void _parseMetadataFields(String yamlStr, Directory dir, List<ValidationError> validationErrors,
      List<String> warnings) {
    try {
      final yaml = loadYaml(yamlStr);
      if (yaml is! YamlMap) {
        validationErrors.add(ValidationError(
            ruleId: _getRule(validYamlMetadataCheck).name,
            file: _skillFileName,
            message: 'Invalid YAML metadata: expected a map$_metadataUrl',
            severity: _getRule(validYamlMetadataCheck).severity));
        return;
      }

      for (final String field in _requiredFields) {
        if (!yaml.containsKey(field)) {
          validationErrors.add(ValidationError(
              ruleId: validYamlMetadataCheck.name,
              file: _skillFileName,
              message: 'Missing required field: $field$_metadataUrl',
              severity: validYamlMetadataCheck.severity));
        }
      }

      if (_getRule(disallowedFieldCheck).severity != AnalysisSeverity.disabled) {
        for (final key in yaml.keys) {
          if (!_allowedFields.contains(key)) {
            validationErrors.add(ValidationError(
                ruleId: _getRule(disallowedFieldCheck).name,
                file: _skillFileName,
                message: 'Disallowed field: $key$_metadataUrl',
                severity: _getRule(disallowedFieldCheck).severity));
          }
        }
      }

      final String name = yaml[_nameField]?.toString() ?? '';
      if (name.isNotEmpty) {
        _validateNameField(name, dir, validationErrors);
      }

      final String description = yaml[_descriptionField]?.toString() ?? '';
      if (description.length > maxDescriptionLength) {
        validationErrors.add(ValidationError(
            ruleId: _getRule(descriptionTooLongCheck).name,
            file: _skillFileName,
            message:
                'Description too long. Maximum $maxDescriptionLength characters.$_descriptionFieldUrl',
            severity: _getRule(descriptionTooLongCheck).severity));
      }

      if (yaml.containsKey(_compatibilityField)) {
        final String compatibility = yaml[_compatibilityField]?.toString() ?? '';
        if (compatibility.length > maxCompatibilityLength) {
          validationErrors.add(ValidationError(
              ruleId: _getRule(validYamlMetadataCheck).name,
              file: _skillFileName,
              message:
                  'Compatibility too long. Maximum $maxCompatibilityLength characters.$_compatibilityFieldUrl',
              severity: _getRule(validYamlMetadataCheck).severity));
        }
      }
    } catch (e) {
      validationErrors.add(ValidationError(
          ruleId: _getRule(validYamlMetadataCheck).name,
          file: _skillFileName,
          message: 'Invalid YAML metadata: $e$_metadataUrl',
          severity: _getRule(validYamlMetadataCheck).severity));
    }
  }

  void _validateNameField(String name, Directory dir, List<ValidationError> validationErrors) {
    if (name != name.toLowerCase()) {
      validationErrors.add(ValidationError(
          ruleId: _getRule(invalidSkillNameCheck).name,
          file: _skillFileName,
          message: 'Skill name must be lowercase: $name$_nameFieldUrl',
          severity: _getRule(invalidSkillNameCheck).severity));
    }
    if (name.length > maxNameLength) {
      validationErrors.add(ValidationError(
          ruleId: _getRule(invalidSkillNameCheck).name,
          file: _skillFileName,
          message: 'Skill name too long. Maximum $maxNameLength characters.$_nameFieldUrl',
          severity: _getRule(invalidSkillNameCheck).severity));
    }
    if (!_validNameRegex.hasMatch(name)) {
      validationErrors.add(ValidationError(
          ruleId: _getRule(invalidSkillNameCheck).name,
          file: _skillFileName,
          message:
              'Skill name contains invalid characters. Only lowercase letters, digits, and hyphens allowed.$_nameFieldUrl',
          severity: _getRule(invalidSkillNameCheck).severity));
    }
    if (name.startsWith('-') || name.endsWith('-')) {
      validationErrors.add(ValidationError(
          ruleId: _getRule(invalidSkillNameCheck).name,
          file: _skillFileName,
          message: 'Skill name cannot have leading or trailing hyphens.$_nameFieldUrl',
          severity: _getRule(invalidSkillNameCheck).severity));
    }
    if (name.contains('--')) {
      validationErrors.add(ValidationError(
          ruleId: _getRule(invalidSkillNameCheck).name,
          file: _skillFileName,
          message: 'Skill name cannot have consecutive hyphens.$_nameFieldUrl',
          severity: _getRule(invalidSkillNameCheck).severity));
    }

    final String dirName = p.basename(dir.path);
    if (name != dirName) {
      validationErrors.add(ValidationError(
          ruleId: _getRule(invalidSkillNameCheck).name,
          file: _skillFileName,
          message:
              'Skill name ($name) must exactly match the name of its parent directory ($dirName).$_nameFieldUrl',
          severity: _getRule(invalidSkillNameCheck).severity));
    }
  }

  Future<void> _validateRelativeLinks(String markdownContent, Directory dir,
      List<ValidationError> validationErrors, List<String> warnings) async {
    for (final RegExpMatch linkMatch in _markdownLinkRegex.allMatches(markdownContent)) {
      final String path = linkMatch.group(1)!;
      if (p.isAbsolute(path) || p.windows.isAbsolute(path)) {
        final AnalysisSeverity absolutePathsSeverity = _getRule(absolutePathsCheck).severity;
        if (absolutePathsSeverity != AnalysisSeverity.disabled) {
          validationErrors.add(ValidationError(
              ruleId: _getRule(absolutePathsCheck).name,
              file: _skillFileName,
              message: 'Absolute filepath found in link: $path',
              severity: absolutePathsSeverity));
        }
        continue; // Do not process it as relative file or uri
      }

      try {
        final Uri uri = Uri.parse(path);
        if (uri.hasScheme || path.startsWith('#')) {
          continue; // Ignore web URLs, email links, anchors, etc.
        }
      } catch (_) {
        // If Uri parsing fails, treat it as a potential filepath.
      }

      final linkedFile = File(p.join(dir.path, path));
      final AnalysisSeverity relativePathsSeverity = _getRule(relativePathsCheck).severity;
      if (!await linkedFile.exists()) {
        if (relativePathsSeverity != AnalysisSeverity.disabled) {
          validationErrors.add(ValidationError(
              ruleId: _getRule(relativePathsCheck).name,
              file: _skillFileName,
              message: 'Linked file does not exist: $path',
              severity: relativePathsSeverity));
        }
      }
    }
  }
}
