// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'config_parser.dart';
import 'fixable_rule.dart';
import 'models/analysis_severity.dart';
import 'models/check_type.dart';
import 'models/ignore_entry.dart';
import 'models/skill_context.dart';
import 'models/skill_rule.dart';
import 'models/skills_ignores.dart';
import 'models/validation_error.dart';
import 'rule_registry.dart';
import 'skills_ignores_storage.dart';
import 'validator.dart';

final _log = Logger('dart_skills_lint');

const _printWarningsFlag = 'print-warnings';
const _fastFailFlag = 'fast-fail';
const _quietFlag = 'quiet';
const _skillsDirectoryFlag = 'skills-directory';
const _skillOption = 'skill';
const _ignoreFileOption = 'ignore-file';
const _ignoreConfigFlag = 'ignore-config';
const _generateBaselineFlag = 'generate-baseline';
const _fixFlag = 'fix';
const _fixApplyFlag = 'fix-apply';
const _allowMisconfiguredKeysFlag = 'allow-misconfigured-keys';

@visibleForTesting
const defaultIgnoreFileName = 'dart_skills_lint_ignore.json';

@visibleForTesting
const skillIsValidMsg = '  Skill is valid.';
@visibleForTesting
const skillIsInvalidMsg = '  Skill is invalid:';
@visibleForTesting
const warningsMsg = 'Warnings:';

@visibleForTesting
const evaluatingDirMsg = 'Evaluating directory:';

@visibleForTesting
const directoryErrorMsg = 'Directory error:';

/// Main entrypoint execution logic for the CLI tool.
///
/// Parses arguments and runs validation on the specified directory.
Future<void> runApp(List<String> args) async {
  // Setup logger to print to stdout/stderr
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    if (record.level >= Level.SEVERE) {
      stderr.writeln(record.message);
    } else {
      stdout.writeln(record.message);
    }
  });

  const helpFlag = 'help';

  final parser = ArgParser()
    ..addFlag(helpFlag, abbr: 'h', negatable: false, help: 'Show usage information.')
    ..addFlag(_printWarningsFlag, abbr: 'w', defaultsTo: true, help: 'Print validation warnings.');

  // Dynamically add flags for all registered rules.
  for (final CheckType check in RuleRegistry.allChecks) {
    parser.addFlag(
      check.name,
      defaultsTo: check.defaultSeverity != AnalysisSeverity.disabled,
      help: check.help,
    );
  }

  parser
    ..addFlag(
      _fastFailFlag,
      negatable: false,
      help: 'Fail immediately on the first skill validation error.',
    )
    ..addFlag(
      _quietFlag,
      abbr: 'q',
      negatable: false,
      help: 'Quiet mode (only print errors and warnings).',
    )
    ..addMultiOption(
      _skillsDirectoryFlag,
      abbr: 'd',
      help: 'Path to a skills directory to validate. Can be specified multiple times.',
    )
    ..addMultiOption(
      _skillOption,
      abbr: 's',
      help: 'Path to an individual skill directory to validate. Can be specified multiple times.',
    )
    ..addOption(_ignoreFileOption, help: 'Path to a JSON file listing lints to ignore for the run.')
    ..addFlag(
      _generateBaselineFlag,
      negatable: false,
      help: 'Write all current errors into $defaultIgnoreFileName to ignore on future runs.',
    )
    ..addFlag(
      _ignoreConfigFlag,
      negatable: false,
      help: 'Ignore the YAML configuration file entirely.',
    )
    ..addFlag(_fixFlag, negatable: false, help: 'Preview fixes for failing lints (dry run).')
    ..addFlag(_fixApplyFlag, negatable: false, help: 'Apply fixes for failing lints.')
    ..addFlag(
      _allowMisconfiguredKeysFlag,
      negatable: false,
      hide: true,
      help: 'Allow misconfigured keys in dart_skills_lint.yaml.',
    );

  final ArgResults results;
  try {
    results = parser.parse(args);
    if (results[helpFlag] as bool) {
      _printUsage(parser);
      return;
    }
  } catch (e) {
    _printUsage(parser, e.toString());
    exitCode = 64; // Bad usage
    return;
  }

  final ignoreConfig = results[_ignoreConfigFlag] as bool;
  final Configuration config = ignoreConfig ? Configuration() : await loadConfig();
  if (ignoreConfig && !(results[_quietFlag] as bool)) {
    _log.info('Ignoring configuration file due to $_ignoreConfigFlag flag');
  }

  if (config.parsingErrors.isNotEmpty) {
    final allowMisconfiguredKeys = results[_allowMisconfiguredKeysFlag] as bool;
    if (allowMisconfiguredKeys) {
      for (final String error in config.parsingErrors) {
        _log.warning('Configuration warning: $error');
      }
    } else {
      for (final String error in config.parsingErrors) {
        _log.severe('Configuration error: $error');
      }
      _log.severe('Use --$_allowMisconfiguredKeysFlag to ignore these errors.');
      exitCode = 1;
      return;
    }
  }

  var skillDirPaths = results[_skillsDirectoryFlag] as List<String>;
  final individualSkillPaths = results[_skillOption] as List<String>;

  if (skillDirPaths.isEmpty && individualSkillPaths.isEmpty) {
    if (config.directoryConfigs.isNotEmpty) {
      skillDirPaths = config.directoryConfigs.map((e) => e.path).toList();
    } else {
      final defaults = ['.claude/skills', '.agents/skills'];
      final existingDefaults = <String>[];
      for (final path in defaults) {
        if (Directory(path).existsSync()) {
          existingDefaults.add(path);
        }
      }
      if (existingDefaults.isEmpty) {
        _printUsage(parser, 'Missing skills directory. Checked defaults: ${defaults.join(', ')}');
        exitCode = 64;
        return;
      }
      skillDirPaths = existingDefaults;
    }
  }

  final Map<String, AnalysisSeverity> resolvedRules = resolveRules(results, config);

  final printWarnings = results[_printWarningsFlag] as bool;
  final fastFail = results[_fastFailFlag] as bool;
  final quiet = results[_quietFlag] as bool;
  final generateBaseline = results[_generateBaselineFlag] as bool;
  final fix = results[_fixFlag] as bool;
  final fixApply = results[_fixApplyFlag] as bool;

  String? ignoreFileOverride;
  if (results.wasParsed(_ignoreFileOption)) {
    ignoreFileOverride = results[_ignoreFileOption] as String?;
  }

  final bool success = await validateSkillsInternal(
    skillDirPaths: skillDirPaths,
    individualSkillPaths: individualSkillPaths,
    resolvedRules: resolvedRules,
    printWarnings: printWarnings,
    fastFail: fastFail,
    quiet: quiet,
    generateBaseline: generateBaseline,
    fix: fix,
    fixApply: fixApply,
    ignoreFileOverride: ignoreFileOverride,
    config: config,
  );

  exitCode = success ? 0 : 1;
}

/// Validates skills based on the provided configuration.
///
/// This is the public API for validating skills. It does not support fixing
/// lints as that feature is currently considered internal to the CLI.
///
/// [skillDirPaths] is a list of directories containing multiple skills.
/// [individualSkillPaths] is a list of paths to individual skill directories.
/// [resolvedRules] is a map of rule names to their severity overrides.
/// [printWarnings] controls whether to print validation warnings.
/// [fastFail] causes validation to stop on the first error.
/// [quiet] suppresses non-error/warning output.
/// [generateBaseline] writes current errors to a baseline file instead of reporting them.
/// [ignoreFileOverride] is an optional path to a baseline file to use.
/// [config] is the loaded configuration.
///
/// Returns `true` if all validations passed (or if generating a baseline), `false` otherwise.
Future<bool> validateSkills({
  List<String> skillDirPaths = const [],
  List<String> individualSkillPaths = const [],
  Map<String, AnalysisSeverity> resolvedRules = const {},
  bool printWarnings = true,
  bool fastFail = false,
  bool quiet = false,
  bool generateBaseline = false,
  String? ignoreFileOverride,
  Configuration? config,
  List<SkillRule> customRules = const [],
}) async {
  return validateSkillsInternal(
    skillDirPaths: skillDirPaths,
    individualSkillPaths: individualSkillPaths,
    resolvedRules: resolvedRules,
    printWarnings: printWarnings,
    fastFail: fastFail,
    quiet: quiet,
    generateBaseline: generateBaseline,
    ignoreFileOverride: ignoreFileOverride,
    config: config,
    customRules: customRules,
  );
}

/// Internal implementation of skill validation that supports fixing.
///
/// Kept internal to avoid exposing experimental fix parameters in the public API.
@visibleForTesting
Future<bool> validateSkillsInternal({
  List<String> skillDirPaths = const [],
  List<String> individualSkillPaths = const [],
  Map<String, AnalysisSeverity> resolvedRules = const {},
  bool printWarnings = true,
  bool fastFail = false,
  bool quiet = false,
  bool generateBaseline = false,
  bool fix = false,
  bool fixApply = false,
  String? ignoreFileOverride,
  Configuration? config,
  List<SkillRule> customRules = const [],
}) async {
  config ??= Configuration();
  var globalAnyFailed = false;
  var anySkillsValidated = false;

  // 1. Process individual --skill (-s) paths
  for (final skillPath in individualSkillPaths) {
    final String normalizedSkillPath = p.normalize(_expandPath(skillPath));
    if (!quiet) {
      _log.info('$evaluatingDirMsg $normalizedSkillPath');
    }
    final skillDir = Directory(normalizedSkillPath);

    if (!skillDir.existsSync()) {
      _log.severe('Specified skill directory does not exist: $normalizedSkillPath');
      globalAnyFailed = true;
      continue;
    }

    final Map<String, AnalysisSeverity> localRules = _resolveRulesForPath(
      normalizedSkillPath,
      config,
      resolvedRules,
    );
    String? localIgnoreFile = _resolveIgnoreFileForPath(normalizedSkillPath, config);

    if (ignoreFileOverride != null) {
      localIgnoreFile = ignoreFileOverride;
    }

    final validator = Validator(ruleOverrides: localRules, customRules: customRules);

    final Map<String, List<IgnoreEntry>> ignoresMap = await _loadIgnores(
      localIgnoreFile,
      skillDir.parent,
    );
    final String skillName = p.basename(skillDir.path);
    final List<IgnoreEntry> skillIgnores = ignoresMap[skillName] ?? [];

    anySkillsValidated = true;
    final ValidationResult result = await _validateSingleSkill(
      skillDir: skillDir,
      validator: validator,
      ignoresMap: ignoresMap,
      printWarnings: printWarnings,
      quiet: quiet,
    );

    final ValidationResult finalResult = await _applyFixesIfNeeded(
      skillDir: skillDir,
      result: result,
      validator: validator,
      skillIgnores: skillIgnores,
      fix: fix,
      fixApply: fixApply,
      quiet: quiet,
    );

    if (generateBaseline) {
      await _generateBaselineFile(finalResult, localIgnoreFile, skillDir, skillDir);
    }

    if (!generateBaseline) {
      final String fullPath = p.absolute(skillDir.path);
      for (final ignore in skillIgnores) {
        if (!ignore.used) {
          _log.info(
            "Stale ignore entry found for rule '${ignore.ruleId}' in skill '$skillName' at '$fullPath'. Consider removing it.",
          );
        }
      }
    }

    if (!finalResult.isValid) {
      globalAnyFailed = true;
      if (fastFail) {
        break;
      }
    }
  }

  // 2. Process --skills-directory (-d) roots
  for (final rootPath in skillDirPaths) {
    final String normalizedRootPath = p.normalize(_expandPath(rootPath));
    if (!quiet) {
      _log.info('$evaluatingDirMsg $normalizedRootPath');
    }
    final rootDir = Directory(normalizedRootPath);

    if (!rootDir.existsSync()) {
      _log.severe('Specified root directory does not exist: $normalizedRootPath');
      globalAnyFailed = true;
      continue;
    }

    final Map<String, AnalysisSeverity> localRules = _resolveRulesForPath(
      normalizedRootPath,
      config,
      resolvedRules,
    );
    String? localIgnoreFile = _resolveIgnoreFileForPath(normalizedRootPath, config);

    if (ignoreFileOverride != null) {
      localIgnoreFile = ignoreFileOverride;
    }

    final validator = Validator(ruleOverrides: localRules, customRules: customRules);

    List<FileSystemEntity> entities;
    try {
      entities = await rootDir.list().toList();
    } catch (_) {
      _log.severe('  $directoryErrorMsg');
      _log.severe('    - Failed to list children of: $normalizedRootPath');
      globalAnyFailed = true;
      continue;
    }
    entities.sort((a, b) => a.path.compareTo(b.path));

    final Map<String, List<IgnoreEntry>> ignoresMap = await _loadIgnores(localIgnoreFile, rootDir);

    for (final entity in entities) {
      if (entity is Directory) {
        if (p.basename(entity.path).startsWith('.')) {
          continue;
        }
        anySkillsValidated = true;
        final ValidationResult result = await _validateSingleSkill(
          skillDir: entity,
          validator: validator,
          ignoresMap: ignoresMap,
          printWarnings: printWarnings,
          quiet: quiet,
        );

        final ValidationResult finalResult = await _applyFixesIfNeeded(
          skillDir: entity,
          result: result,
          validator: validator,
          skillIgnores: ignoresMap[p.basename(entity.path)] ?? [],
          fix: fix,
          fixApply: fixApply,
          quiet: quiet,
        );

        if (generateBaseline) {
          await _generateBaselineFile(finalResult, localIgnoreFile, rootDir, entity);
        }

        if (!finalResult.isValid) {
          globalAnyFailed = true;
          if (fastFail) {
            break;
          }
        }
      }
    }

    if (!generateBaseline) {
      for (final MapEntry<String, List<IgnoreEntry>> entry in ignoresMap.entries) {
        final String skillName = entry.key;
        for (final IgnoreEntry ignore in entry.value) {
          if (!ignore.used) {
            final String fullPath = p.absolute(p.join(rootDir.path, skillName));
            _log.info(
              "Stale ignore entry found for rule '${ignore.ruleId}' in skill '$skillName' at '$fullPath'. Consider removing it.",
            );
          }
        }
      }
    }

    if (globalAnyFailed && fastFail) {
      break;
    }
  }

  if (!anySkillsValidated) {
    var foundSingleSkillPassedToD = false;
    for (final rootPath in skillDirPaths) {
      final String expandedRootPath = _expandPath(rootPath);
      final skillMdFile = File(p.join(expandedRootPath, SkillContext.skillFileName));
      if (skillMdFile.existsSync()) {
        _log.severe(
          'Directory "$expandedRootPath" appears to be an individual skill. Use --skill / -s instead of -d / --skills-directory.',
        );
        foundSingleSkillPassedToD = true;
      }
    }
    if (!foundSingleSkillPassedToD) {
      _log.severe('No skills found to validate in the specified directories.');
    }
    globalAnyFailed = true;
  }

  if (generateBaseline) {
    globalAnyFailed = false;
  }

  return !globalAnyFailed;
}

@visibleForTesting
Map<String, AnalysisSeverity> resolveRules(ArgResults results, Configuration config) {
  final resolved = <String, AnalysisSeverity>{};

  // 1. Initialize with default severities from the registry.
  for (final CheckType check in RuleRegistry.allChecks) {
    resolved[check.name] = check.defaultSeverity;
  }

  // 2. Override with configurations from the YAML file.
  resolved.addAll(config.configuredRules);

  // 3. Override with CLI flags. CLI flags take highest precedence.
  for (final CheckType check in RuleRegistry.allChecks) {
    final String name = check.name;

    // Skip if the flag was not passed on the command line.
    if (!results.wasParsed(name)) {
      continue;
    }

    // TODO(reidbaker): Handle options in addition to flags.
    final Object? value = results[name];
    if (value is! bool) {
      continue;
    }

    if (value) {
      // If the user explicitly enabled the rule via flag (e.g., --rule), set to error.
      resolved[name] = AnalysisSeverity.error;
    } else {
      // If the user explicitly disabled the rule via flag (e.g., --no-rule).
      resolved[name] = AnalysisSeverity.disabled;
    }
  }

  return resolved;
}

Map<String, AnalysisSeverity> _resolveRulesForPath(
  String normalizedPath,
  Configuration config,
  Map<String, AnalysisSeverity> baseRules,
) {
  final localRules = Map<String, AnalysisSeverity>.from(baseRules);
  for (final DirectoryConfig dirConfig in config.directoryConfigs) {
    final String normalizedConfigPath = p.normalize(dirConfig.path);
    if (normalizedPath.startsWith(normalizedConfigPath)) {
      localRules.addAll(dirConfig.rules);
      break;
    }
  }
  return localRules;
}

String? _resolveIgnoreFileForPath(String normalizedPath, Configuration config) {
  for (final DirectoryConfig dirConfig in config.directoryConfigs) {
    final String normalizedConfigPath = p.normalize(dirConfig.path);
    if (normalizedPath.startsWith(normalizedConfigPath)) {
      return dirConfig.ignoreFile;
    }
  }
  return null;
}

Future<Map<String, List<IgnoreEntry>>> _loadIgnores(
  String? ignoreFileOverride,
  Directory rootDir,
) async {
  final String ignorePath = ignoreFileOverride != null
      ? p.normalize(_expandPath(ignoreFileOverride))
      : p.join(rootDir.path, defaultIgnoreFileName);

  final file = File(ignorePath);

  if (file.existsSync()) {
    final storage = SkillsIgnoresStorage();
    final SkillsIgnores ignores = await storage.load(ignorePath);
    return ignores.skills;
  }

  // If a custom ignore file was specified but not found, create an empty one
  // so the user can start adding ignores to it.
  if (ignoreFileOverride != null) {
    _log.warning('File not found generating-baseline');
    try {
      await file.writeAsString(jsonEncode({SkillsIgnores.skillsKey: <String, dynamic>{}}));
    } catch (_) {
      // Ignore write errors, we will just return empty ignores.
    }
  }

  return {};
}

void _applyIgnores(ValidationResult result, List<IgnoreEntry> ignores, Directory skillDir) {
  for (final ValidationError error in result.validationErrors) {
    if (error.isIgnored) {
      continue;
    }
    final String fileName = error.file;
    for (final ignore in ignores) {
      if (ignore.ruleId == error.ruleId && p.normalize(ignore.fileName) == p.normalize(fileName)) {
        error.isIgnored = true;
        ignore.used = true;
        break;
      }
    }
  }
}

Future<ValidationResult> _validateSingleSkill({
  required Directory skillDir,
  required Validator validator,
  required Map<String, List<IgnoreEntry>> ignoresMap,
  required bool printWarnings,
  required bool quiet,
}) async {
  final String skillName = p.basename(skillDir.path);
  if (!quiet) {
    _log.info('--- Validating skill: $skillName ---');
  }
  final ValidationResult result = await validator.validate(skillDir);
  final List<IgnoreEntry> skillIgnores = ignoresMap[skillName] ?? [];
  _applyIgnores(result, skillIgnores, skillDir);
  _printValidationResult(result, printWarnings, quiet);
  return result;
}

Future<ValidationResult> _applyFixesIfNeeded({
  required Directory skillDir,
  required ValidationResult result,
  required Validator validator,
  required List<IgnoreEntry> skillIgnores,
  required bool fix,
  required bool fixApply,
  required bool quiet,
}) async {
  if (!fix && !fixApply) {
    return result;
  }

  final SkillContext? context = result.context;
  if (context == null) {
    return result;
  }

  final String skillName = p.basename(skillDir.path);
  final skillMdFile = File(p.join(skillDir.path, SkillContext.skillFileName));
  if (!skillMdFile.existsSync()) {
    return result;
  }

  String currentContent = context.rawContent;
  final originalContent = currentContent;
  var modified = false;

  for (final SkillRule rule in validator.rules) {
    if (rule is FixableRule) {
      final bool hasErrors = result.validationErrors.any(
        (e) => e.ruleId == rule.name && !e.isIgnored,
      );
      if (hasErrors) {
        try {
          final String newContent = await (rule as FixableRule).fix(
            SkillContext.skillFileName,
            currentContent,
            context.directory,
          );
          if (newContent != currentContent) {
            currentContent = newContent;
            modified = true;
          }
        } catch (e) {
          _log.severe("  Failed to apply fix for rule '${rule.name}': $e");
        }
      }
    }
  }

  if (modified) {
    if (fixApply) {
      await skillMdFile.writeAsString(currentContent);
      if (!quiet) {
        _log.info('  Applied fixes for $skillName');
      }
      final ValidationResult newResult = await validator.validate(skillDir);
      _applyIgnores(newResult, skillIgnores, skillDir);
      return newResult;
    } else if (fix) {
      if (!quiet) {
        _log.info('  [Dry Run] Proposed changes for $skillName (SKILL.md):');
        _printDiff(originalContent, currentContent);
      }
    }
  }

  return result;
}

/// Prints a simple line-by-line diff between [original] and [modified].
///
/// **Limitation**: This naive diff algorithm does not handle line additions or
/// removals well, as it compares lines at the same index. It is sufficient for
/// current fixers that only modify existing lines, but should be replaced with
/// a more robust diffing solution (e.g., `package:diff`) if future fixers
/// add or remove lines.
void _printDiff(String original, String modified) {
  final List<String> origLines = original.split('\n');
  final List<String> modLines = modified.split('\n');
  final int maxLines = origLines.length > modLines.length ? origLines.length : modLines.length;
  for (var i = 0; i < maxLines; i++) {
    final String orig = i < origLines.length ? origLines[i] : '';
    final String mod = i < modLines.length ? modLines[i] : '';
    if (orig != mod) {
      if (orig.isNotEmpty) {
        _log.info('- Line ${i + 1}: $orig');
      }
      if (mod.isNotEmpty) {
        _log.info('+ Line ${i + 1}: $mod');
      }
    }
  }
}

Future<void> _generateBaselineFile(
  ValidationResult result,
  String? ignoreFileOverride,
  Directory rootDir,
  Directory skillDir,
) async {
  final String ignorePath = ignoreFileOverride != null
      ? p.normalize(_expandPath(ignoreFileOverride))
      : p.join(rootDir.path, defaultIgnoreFileName);
  final storage = SkillsIgnoresStorage();
  final SkillsIgnores ignores = await storage.load(ignorePath);

  final String skillName = p.basename(skillDir.path);
  final List<IgnoreEntry> currentSkillIgnores = ignores.skills[skillName] ?? [];
  final currentSkillSeen = <String>{};
  for (final ignore in currentSkillIgnores) {
    currentSkillSeen.add('${ignore.ruleId}:${ignore.fileName}');
  }

  for (final ValidationError error in result.validationErrors) {
    if (!error.isIgnored) {
      final key = '${error.ruleId}:${error.file}';
      if (currentSkillSeen.contains(key)) {
        continue;
      }
      currentSkillSeen.add(key);

      currentSkillIgnores.add(IgnoreEntry(ruleId: error.ruleId, fileName: error.file));
    }
  }

  if (currentSkillIgnores.isNotEmpty) {
    ignores.skills[skillName] = currentSkillIgnores;
  } else {
    ignores.skills.remove(skillName);
  }

  try {
    await storage.save(ignorePath, ignores);
  } catch (e) {
    _log.warning('Failed to generate baseline file at $ignorePath: $e');
  }
}

void _printUsage(ArgParser parser, [String? error]) {
  if (error != null) {
    _log.severe('Error: $error');
  }
  _log.info('Usage: dart_skills_lint [options] --$_skillsDirectoryFlag <$_skillsDirectoryFlag>');
  _log.info(parser.usage);
}

void _printValidationResult(ValidationResult result, bool printWarnings, bool quiet) {
  if (result.isValid) {
    if (!quiet) {
      _log.info('  $skillIsValidMsg');
    }
  } else {
    _log.severe('  $skillIsInvalidMsg');
    for (final String error in result.errors) {
      _log.severe('    - $error');
    }
  }

  if (printWarnings && result.warnings.isNotEmpty) {
    _log.warning('  $warningsMsg');
    for (final String warning in result.warnings) {
      _log.warning('    - $warning');
    }
  }
}

String _expandPath(String path) {
  if (path.startsWith('~/')) {
    final String? homeDir = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (homeDir != null) {
      return p.join(homeDir, path.substring(2));
    }
  }
  return path;
}
