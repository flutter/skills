// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:http/http.dart' as http;

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
}
