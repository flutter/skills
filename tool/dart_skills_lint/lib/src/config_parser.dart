// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: specify_nonobvious_local_variable_types yaml parsing has dynamic types.

import 'dart:io';
import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';
import 'models/analysis_severity.dart';

final _log = Logger('dart_skills_lint');

const _dartSkillsLintKey = 'dart_skills_lint';
const _rulesKey = 'rules';
const _directoriesKey = 'directories';
const _pathKey = 'path';
const _ignoreFileKey = 'ignore_file';

AnalysisSeverity _parseSeverity(String value) {
  if (value == 'error') {
    return AnalysisSeverity.error;
  }
  if (value == 'warning') {
    return AnalysisSeverity.warning;
  }
  if (value == 'disabled') {
    return AnalysisSeverity.disabled;
  }
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
  Configuration({this.directoryConfigs = const [], this.configuredRules = const {}});
  final List<DirectoryConfig> directoryConfigs;
  final Map<String, AnalysisSeverity> configuredRules;
}

/// Reads dart_skills_lint.yaml from the current directory and returns the configuration.
Future<Configuration> loadConfig() async {
  final configFile = File('dart_skills_lint.yaml');
  if (!configFile.existsSync()) {
    return Configuration();
  }

  try {
    final String content = await configFile.readAsString();
    final yaml = loadYaml(content);
    if (yaml is YamlMap && yaml.containsKey(_dartSkillsLintKey)) {
      final toolConfig = yaml[_dartSkillsLintKey];
      if (toolConfig is YamlMap) {
        final configuredRules = <String, AnalysisSeverity>{};
        if (toolConfig.containsKey(_rulesKey)) {
          final rules = toolConfig[_rulesKey];
          if (rules is YamlMap) {
            for (final key in rules.keys) {
              configuredRules[key.toString()] = _parseSeverity(rules[key]?.toString() ?? '');
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
        return Configuration(directoryConfigs: directoryConfigs, configuredRules: configuredRules);
      }
    }
  } catch (e) {
    _log.warning('Failed to parse dart_skills_lint.yaml: $e');
  }
  return Configuration();
}
