// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  final resourcesDir = Directory(
    p.normalize(p.join(Directory.current.path, '..', '..', 'resources')),
  );

  test(
    'resources directory exists',
    () {
      expect(
        resourcesDir.existsSync(),
        isTrue,
        reason: 'resources directory should exist',
      );
    },
    skip: !resourcesDir.existsSync() ? 'Directory not present' : false,
  );

  if (!resourcesDir.existsSync()) return;

  final yamlFiles = resourcesDir
      .listSync()
      .where((e) => e.path.endsWith('.yaml'))
      .cast<File>();

  test('resources contains YAML files', () {
    expect(yamlFiles, isNotEmpty, reason: 'No YAML files found in resources');
  });

  final client = http.Client();
  // We can't use addTearDown here because it must be within a test or setUp/tearDown.
  // We'll use tearDownAll for the group cleanup.
  tearDownAll(client.close);

  for (final file in yamlFiles) {
    group(p.basename(file.path), () {
      final content = file.readAsStringSync();
      YamlList? yaml;
      try {
        yaml = loadYaml(content) as YamlList;
      } catch (e) {
        test('is valid YAML list', () {
          fail('Failed to decode YAML: $e');
        });
        return;
      }

      test('structure is a List', () {
        expect(yaml, isA<YamlList>(), reason: 'Root must be a list');
        expect(yaml, isNotEmpty, reason: 'Root list must not be empty');
      });

      // yaml is known to be non-null here because of the try/catch above and type cast
      for (var i = 0; i < yaml.length; i++) {
        final item = yaml[i];
        if (item is! YamlMap && item is! Map) {
          test('Item $i is a Map', () {
            fail('Item $i is not a Map');
          });
          continue;
        }

        final name = item['name'] as String? ?? 'Item $i';
        test('name is kabob-case', () {
          expect(
            name,
            matches(RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$')),
            reason:
                'Skill name must be kabob-case (e.g. abc-def). See https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices#naming-conventions',
          );
        });

        if (p.basename(file.path) == 'flutter_skills.yaml') {
          test('name starting with "flutter-"', () {
            expect(
              name,
              startsWith('flutter-'),
              reason:
                  'All skills in flutter_skills.yaml must start with "flutter-"',
            );
          });

          test('description contains "Flutter"', () {
            final description = item['description'] as String?;
            expect(
              description,
              isNotNull,
              reason: 'Skill must have a description',
            );
            expect(
              description,
              contains('Flutter'),
              reason:
                  'All skills in flutter_skills.yaml must contain "Flutter" in their description',
            );
          });
        } else if (p.basename(file.path) == 'dart_skills.yaml') {
          test('name starting with "dart-"', () {
            expect(
              name,
              startsWith('dart-'),
              reason: 'All skills in dart_skills.yaml must start with "dart-"',
            );
          });

          test('description contains "Dart"', () {
            final description = item['description'] as String?;
            expect(
              description,
              isNotNull,
              reason: 'Skill must have a description',
            );
            expect(
              description,
              contains('Dart'),
              reason:
                  'All skills in dart_skills.yaml must contain "Dart" in their description',
            );
          });
        }

        group(name, () {
          test('has required fields', () {
            expect(item, contains('name'), reason: 'Missing "name"');
            expect(
              item,
              contains('description'),
              reason: 'Missing "description"',
            );
            expect(item, contains('resources'), reason: 'Missing "resources"');
          });

          test('resources is a non-empty List', () {
            expect(
              item['resources'],
              isA<YamlList>(),
              reason: '"resources" must be a list',
            );
            final resources = item['resources'] as YamlList;
            expect(
              resources,
              isNotEmpty,
              reason: '"resources" must not be empty',
            );
          });

          if (item['resources'] is YamlList) {
            final resources = item['resources'] as YamlList;
            for (final resource in resources) {
              final url = resource as String;
              test('URL starts with https://', () {
                expect(
                  url,
                  startsWith('https://'),
                  reason: 'All resources must be secure HTTPS URLs',
                );
              });
              test('URL: $url', () => _validateResource(client, url));
            }
          }
        });
      }
    });
  }
}

Future<void> _validateResource(http.Client client, String url) async {
  expect(url, startsWith('https://'), reason: 'URL must start with https://');

  try {
    final response = await client.head(Uri.parse(url));
    if (response.statusCode == 405) {
      // Fallback to GET if HEAD is not allowed
      final getResponse = await client.get(Uri.parse(url));
      expect(
        getResponse.statusCode,
        equals(200),
        reason: 'GET returned ${getResponse.statusCode}',
      );
    } else {
      expect(
        response.statusCode,
        equals(200),
        reason: 'HEAD returned ${response.statusCode}',
      );
    }
  } catch (e) {
    fail('Failed to connect: $e');
  }
}
