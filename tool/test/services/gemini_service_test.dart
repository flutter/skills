// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logging/logging.dart';

import 'package:skills/src/services/gemini_service.dart';
import 'package:test/test.dart';

void main() {
  group('GeminiService', () {
    late GeminiService service;

    setUp(() {
      service = GeminiService(
        apiKey: 'test-api-key',
        httpClient: http.Client(),
      );
    });

    group('cleanContent', () {
      test('returns null for null content', () {
        expect(service.cleanContent(null), isNull);
      });

      test('removes markdown code blocks around content', () {
        const content = '''
```markdown
# Title
Some content
```
''';
        const expected = '''
# Title
Some content
''';
        expect(service.cleanContent(content), expected);
      });

      test('removes markdown code blocks with other languages', () {
        const content = '''
```text
# Title
Some content
```
''';
        const expected = '''
# Title
Some content
''';
        expect(service.cleanContent(content), expected);
      });

      test('ignores trailing markdown code block if no start block', () {
        const content = '''
# Title
Some content
```
''';
        const expected = '''
# Title
Some content
```
''';
        expect(service.cleanContent(content), expected);
      });

      test('strips possible frontmatter at start', () {
        const content = '''
---
key: value
---
# Title
Some content
''';
        const expected = '''
# Title
Some content
''';
        expect(service.cleanContent(content), expected);
      });

      test('strips possible frontmatter after some noise', () {
        const content = '''
Here is the content:
---
key: value
---
# Title
Some content
''';
        const expected = '''
# Title
Some content
''';
        expect(service.cleanContent(content), expected);
      });

      test('preserves internal code blocks', () {
        const content = '''
# Title
Here is some code:
```dart
void main() {}
```
''';
        const expected = '''
# Title
Here is some code:
```dart
void main() {}
```
''';
        expect(service.cleanContent(content), expected);
      });

      test('ensures content ends with newline', () {
        const content = 'Some content';
        const expected = 'Some content\n';
        expect(service.cleanContent(content), expected);
      });

      test('handles complex nested structure', () {
        const content = '''
```markdown
---
key: value
---
# Title
Content with code:
```dart
print('hello');
```
```
''';
        const expected = '''
# Title
Content with code:
```dart
print('hello');
```
''';
        expect(service.cleanContent(content), expected);
      });
      test('removes markdown code blocks with leading whitespace', () {
        const content = '''
  ```markdown
# Title
Some content
```
''';
        const expected = '''
# Title
Some content
''';
        expect(service.cleanContent(content), expected);
      });

      test(
        'removes markdown code blocks with trailing whitespace on fence',
        () {
          const content = '''
```markdown 
# Title
Some content
``` 
''';
          const expected = '''
# Title
Some content
''';
          expect(service.cleanContent(content), expected);
        },
      );

      test('removes markdown code blocks with uppercase language', () {
        const content = '''
```MARKDOWN
# Title
Some content
```
''';
        const expected = '''
# Title
Some content
''';
        expect(service.cleanContent(content), expected);
      });
    });
  });

  group('GeminiService URL Validation', () {
    late GeminiService service;

    setUp(() {
      Logger.root.level = Level.ALL;
    });

    test('retries when content contains URLs', () async {
      var attempt = 0;

      final client = MockClient((request) async {
        attempt++;
        if (attempt == 1) {
          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': 'Here is a link: https://example.com'},
                    ],
                  },
                },
              ],
            }),
            200,
          );
        } else {
          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [
                      {'text': 'No links here.'},
                    ],
                  },
                },
              ],
            }),
            200,
          );
        }
      });

      service = GeminiService(
        apiKey: 'key',
        httpClient: client,
        model: 'gemini-3-pro',
      );

      final result = await service.generateSkillContent(
        'markdown',
        'name',
        'desc',
        urls: ['urls'],
      );

      expect(attempt, 2);
      expect(result, contains('No links here.'));
      expect(result, isNot(contains('https://example.com')));
    });

    test('fails after retries if content always contains URLs', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Link: https://example.com'},
                  ],
                },
              },
            ],
          }),
          200,
        );
      });

      service = GeminiService(
        apiKey: 'key',
        httpClient: client,
        model: 'gemini-3-pro',
      );

      // Capture logs to verify retries
      final logs = <String>[];
      final subscription = Logger.root.onRecord.listen(
        (r) => logs.add(r.message),
      );
      addTearDown(subscription.cancel);

      final result = await service.generateSkillContent(
        'markdown',
        'name',
        'desc',
        urls: ['urls'],
      );

      expect(result, isNull);
      expect(logs, contains(contains('Retrying Gemini generation')));
      expect(logs, contains(contains('Gemini generation failed')));
    });
  });

  group('fetchAndConvertContent', () {
    late Logger logger;

    setUp(() {
      logger = Logger('test');
    });

    test('fetches and converts content successfully on 200 OK', () async {
      final client = MockClient((request) async {
        if (request.url.toString() == 'https://example.com/doc1') {
          return http.Response('<h1>Doc 1</h1>', 200);
        } else if (request.url.toString() == 'https://example.com/doc2') {
          return http.Response('<p>Doc 2 content</p>', 200);
        }
        return http.Response('Not found', 404);
      });

      final result = await fetchAndConvertContent(
        ['https://example.com/doc1', 'https://example.com/doc2'],
        client,
        logger,
      );

      expect(result, contains('Doc 1'));
      expect(result, contains('Doc 2 content'));
    });

    test(
      'throws Exception on non-200 status code to save Gemini tokens',
      () async {
        final client = MockClient((request) async {
          return http.Response('Not found', 404);
        });

        expect(
          () => fetchAndConvertContent(
            ['https://example.com/missing'],
            client,
            logger,
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('HTTP 404'),
            ),
          ),
        );
      },
    );

    test('throws exception on network error to save Gemini tokens', () async {
      final client = MockClient((request) async {
        throw http.ClientException('Connection failed');
      });

      expect(
        () => fetchAndConvertContent(
          ['https://example.com/error'],
          client,
          logger,
        ),
        throwsA(isA<http.ClientException>()),
      );
    });
  });
}
