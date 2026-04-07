// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'package:dart_skills_lint/src/config_parser.dart';
import 'package:dart_skills_lint/src/entry_point.dart';
import 'package:dart_skills_lint/src/models/analysis_severity.dart';
import 'package:dart_skills_lint/src/rules.dart';
import 'package:test/test.dart';

void main() {
  group('resolveRules', () {
    ArgParser createParser() {
      return ArgParser()
        ..addFlag(relativePathsCheck.name)
        ..addFlag(disallowedFieldCheck.name)
        ..addFlag(validYamlMetadataCheck.name, defaultsTo: true)
        ..addFlag(descriptionTooLongCheck.name, defaultsTo: true)
        ..addFlag(invalidSkillNameCheck.name, defaultsTo: true);
    }

    test('returns defaults when no args and empty config', () {
      final ArgResults results = createParser().parse([]);
      final config = Configuration();
      
      final Map<String, AnalysisSeverity> resolved = resolveRules(results, config);

      expect(resolved[relativePathsCheck.name], relativePathsCheck.defaultSeverity);
      expect(resolved[absolutePathsCheck.name], absolutePathsCheck.defaultSeverity);
      expect(resolved[disallowedFieldCheck.name], disallowedFieldCheck.defaultSeverity);
      expect(resolved[validYamlMetadataCheck.name], validYamlMetadataCheck.defaultSeverity);
      expect(resolved[descriptionTooLongCheck.name], descriptionTooLongCheck.defaultSeverity);
      expect(resolved[invalidSkillNameCheck.name], invalidSkillNameCheck.defaultSeverity);
      expect(resolved[pathDoesNotExistCheck.name], pathDoesNotExistCheck.defaultSeverity);
    });

    test('config overrides defaults', () {
      final ArgResults results = createParser().parse([]);
      final config = Configuration(configuredRules: {
        relativePathsCheck.name: AnalysisSeverity.error,
        absolutePathsCheck.name: AnalysisSeverity.warning,
      });
      
      final Map<String, AnalysisSeverity> resolved = resolveRules(results, config);

      expect(resolved[relativePathsCheck.name], AnalysisSeverity.error);
      expect(resolved[absolutePathsCheck.name], AnalysisSeverity.warning);
      // Others should remain default
      expect(resolved[disallowedFieldCheck.name], disallowedFieldCheck.defaultSeverity);
    });

    test('CLI flags override config and defaults', () {
      final ArgResults results = createParser().parse(['--${relativePathsCheck.name}']);
      final config = Configuration(configuredRules: {
        relativePathsCheck.name: AnalysisSeverity.error,
      });
      
      final Map<String, AnalysisSeverity> resolved = resolveRules(results, config);

      expect(resolved[relativePathsCheck.name], AnalysisSeverity.warning);
    });

    test('CLI flag disabled overrides config', () {
      final ArgResults results = createParser().parse(['--no-${validYamlMetadataCheck.name}']);
      final config = Configuration(configuredRules: {
        validYamlMetadataCheck.name: AnalysisSeverity.warning,
      });
      
      final Map<String, AnalysisSeverity> resolved = resolveRules(results, config);

      expect(resolved[validYamlMetadataCheck.name], AnalysisSeverity.disabled);
    });
  });
}
