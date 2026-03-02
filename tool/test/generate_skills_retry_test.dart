// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:skills/src/commands/generate_skill_command.dart';
import 'package:test/test.dart';

void main() {
  group('GenerateSkillsCommand Retry Logic', () {
    late CommandRunner runner;
    late Directory tempDir;
    late File inputFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('skills_retry_test');
      inputFile = File(p.join(tempDir.path, 'input.json'));
      runner = CommandRunner('skills', 'Test runner');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('retries failed LLM calls up to 3 times', () async {
      const url = 'https://example.com/retry';
      inputFile.writeAsStringSync(
        jsonEncode([
          {
            'name': 'retry_skill',
            'description': 'Retry Description',
            'resources': [url],
          },
        ]),
      );

      var attemptCount = 0;
      final logs = <String>[];
      final sub = Logger.root.onRecord.listen((record) {
        logs.add(record.message);
      });
      addTearDown(sub.cancel);

      final mockClient = MockClient((request) async {
        if (request.url.toString() == url) {
          return http.Response('<html>Content</html>', 200);
        }

        if (request.url.toString().contains('generativelanguage')) {
          attemptCount++;
          if (attemptCount < 3) {
            throw Exception('Simulated Network Error');
          }
          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': '---\nname: skill\n---\nContent'},
                    ],
                  },
                },
              ],
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final command = GenerateSkillCommand(environmentOverride: {'GEMINI_API_KEY': 'fake'},
        httpClient: mockClient,
        outputDir: tempDir,
      );
      runner.addCommand(command);

      await runner.run(['generate-skill', inputFile.path]);

      expect(
        attemptCount,
        3,
        reason: 'Should attempt 3 times (1 initial + 2 retries)',
      );
      expect(
        logs,
        contains(contains('Retrying Gemini generation')),
        reason: 'Should log retry warnings',
      );
      expect(
        logs,
        contains(contains('Generated')),
        reason: 'Should eventually succeed',
      );
    });
  });
}
