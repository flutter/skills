import 'dart:io';
import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';
import 'models/check_type.dart';

final _log = Logger('dart_skills_lint');

const _dartSkillsLintKey = 'dart_skills_lint';
const _rulesKey = 'rules';
const _directoriesKey = 'directories';
const _pathKey = 'path';
const _ignoreFileKey = 'ignore_file';

AnalysisSeverity _parseSeverity(String value) {
  if (value == 'error') return AnalysisSeverity.error;
  if (value == 'warning') return AnalysisSeverity.warning;
  if (value == 'disabled') return AnalysisSeverity.disabled;
  return AnalysisSeverity.disabled; // Default if unknown
}

/// Configuration for a specific directory.
class DirectoryConfig {
  DirectoryConfig({required this.path, required this.rules, this.ignoreFile});
  final String path;
  final Map<String, AnalysisSeverity> rules;
  final String? ignoreFile;
}

/// Structured configuration for the linter.
class Configuration {
  Configuration({this.directoryConfigs = const []});
  final List<DirectoryConfig> directoryConfigs;
}

/// Reads dart_skills_lint.yaml from the current directory and updates the check types.
Future<Configuration> loadConfig(Set<CheckType> checkTypes) async {
  final configFile = File('dart_skills_lint.yaml');
  if (!await configFile.exists()) return Configuration();

  try {
    final String content = await configFile.readAsString();
    final yaml = loadYaml(content);
    if (yaml is YamlMap && yaml.containsKey(_dartSkillsLintKey)) {
      final toolConfig = yaml[_dartSkillsLintKey];
      if (toolConfig is YamlMap) {
        if (toolConfig.containsKey(_rulesKey)) {
          final rules = toolConfig[_rulesKey];
          if (rules is YamlMap) {
            for (final check in checkTypes) {
              if (rules.containsKey(check.name)) {
                check.severity = _parseSeverity(rules[check.name]?.toString() ?? '');
              }
            }
          }
        }

        final directoryConfigs = <DirectoryConfig>[];
        if (toolConfig.containsKey(_directoriesKey)) {
          final dirs = toolConfig[_directoriesKey];
          if (dirs is YamlList) {
            for (final dir in dirs) {
              if (dir is YamlMap && dir.containsKey(_pathKey)) {
                final path = dir[_pathKey] as String;
                final rules = <String, AnalysisSeverity>{};
                if (dir.containsKey(_rulesKey)) {
                  final localRules = dir[_rulesKey];
                  if (localRules is YamlMap) {
                    for (final key in localRules.keys) {
                      rules[key.toString()] = _parseSeverity(localRules[key]?.toString() ?? '');
                    }
                  }
                }
                final ignoreFile = dir[_ignoreFileKey] as String?;
                directoryConfigs
                    .add(DirectoryConfig(path: path, rules: rules, ignoreFile: ignoreFile));
              }
            }
          }
        }
        return Configuration(directoryConfigs: directoryConfigs);
      }
    }
  } catch (e) {
    _log.warning('Failed to parse dart_skills_lint.yaml: $e');
  }
  return Configuration();
}
