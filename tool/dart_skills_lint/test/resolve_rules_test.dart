// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'package:dart_skills_lint/src/config_parser.dart';
import 'package:dart_skills_lint/src/entry_point.dart';
import 'package:dart_skills_lint/src/models/analysis_severity.dart';
import 'package:dart_skills_lint/src/models/check_type.dart';
import 'package:dart_skills_lint/src/rule_registry.dart';
import 'package:dart_skills_lint/src/rules/absolute_paths_rule.dart';
import 'package:dart_skills_lint/src/rules/description_length_rule.dart';
import 'package:dart_skills_lint/src/rules/disallowed_field_rule.dart';
import 'package:dart_skills_lint/src/rules/name_format_rule.dart';
import 'package:dart_skills_lint/src/rules/relative_paths_rule.dart';
import 'package:dart_skills_lint/src/rules/valid_yaml_metadata_rule.dart';
import 'package:test/test.dart';

void main() {
  group('resolveRules', () {
    ArgParser createParser() {
      final parser = ArgParser();
      for (final CheckType check in RuleRegistry.allChecks) {
        parser.addFlag(check.name, defaultsTo: check.defaultSeverity != AnalysisSeverity.disabled);
      }
      return parser;
    }

    test('returns defaults when no args and empty config', () {
      final ArgResults results = createParser().parse([]);
      final config = Configuration();

      final Map<String, AnalysisSeverity> resolved = resolveRules(results, config);

      expect(resolved[RelativePathsRule.ruleName], RelativePathsRule.defaultSeverity);
      expect(resolved[AbsolutePathsRule.ruleName], AbsolutePathsRule.defaultSeverity);
      expect(resolved[DisallowedFieldRule.ruleName], DisallowedFieldRule.defaultSeverity);
      expect(resolved[ValidYamlMetadataRule.ruleName], ValidYamlMetadataRule.defaultSeverity);
      expect(resolved[DescriptionLengthRule.ruleName], DescriptionLengthRule.defaultSeverity);
      expect(resolved[NameFormatRule.ruleName], NameFormatRule.defaultSeverity);
    });

    test('config overrides defaults', () {
      final ArgResults results = createParser().parse([]);
      final config = Configuration(
        configuredRules: {
          RelativePathsRule.ruleName: AnalysisSeverity.error,
          AbsolutePathsRule.ruleName: AnalysisSeverity.warning,
        },
      );

      final Map<String, AnalysisSeverity> resolved = resolveRules(results, config);

      expect(resolved[RelativePathsRule.ruleName], AnalysisSeverity.error);
      expect(resolved[AbsolutePathsRule.ruleName], AnalysisSeverity.warning);
      // Others should remain default
      expect(resolved[DisallowedFieldRule.ruleName], DisallowedFieldRule.defaultSeverity);
    });

    test('CLI flags override config and defaults', () {
      final ArgResults results = createParser().parse(['--${RelativePathsRule.ruleName}']);
      final config = Configuration(
        configuredRules: {RelativePathsRule.ruleName: AnalysisSeverity.error},
      );

      final Map<String, AnalysisSeverity> resolved = resolveRules(results, config);

      expect(resolved[RelativePathsRule.ruleName], AnalysisSeverity.error);
    });

    test('CLI flag disabled overrides config', () {
      final ArgResults results = createParser().parse(['--no-${ValidYamlMetadataRule.ruleName}']);
      final config = Configuration(
        configuredRules: {ValidYamlMetadataRule.ruleName: AnalysisSeverity.warning},
      );

      final Map<String, AnalysisSeverity> resolved = resolveRules(results, config);

      expect(resolved[ValidYamlMetadataRule.ruleName], AnalysisSeverity.disabled);
    });
  });
}
