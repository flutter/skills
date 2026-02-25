// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:skills/src/services/markdown_converter.dart';
import 'package:test/test.dart';

void main() {
  group('MarkdownConverter Tables', () {
    late MarkdownConverter converter;

    setUp(() {
      converter = MarkdownConverter();
    });

    test('converts simple table', () {
      const html = '''
<table>
  <thead>
    <tr>
      <th>Header 1</th>
      <th>Header 2</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Cell 1</td>
      <td>Cell 2</td>
    </tr>
  </tbody>
</table>
''';
      final markdown = converter.convert(html);
      expect(markdown, contains('| Header 1 | Header 2 |'));
      expect(markdown, contains('|---|---|'));
      expect(markdown, contains('| Cell 1 | Cell 2 |'));
    });

    test('converts table without thead', () {
      const html = '''
<table>
  <tr>
    <td>Cell 1</td>
    <td>Cell 2</td>
  </tr>
</table>
''';
      final markdown = converter.convert(html);
      // Fallback: treated as table with first row as header
      expect(markdown, contains('| Cell 1 | Cell 2 |'));
      expect(markdown, contains('|---|---|'));
    });

    test('converts definition lists', () {
      const html = '''
<dl>
  <dt>Term 1</dt>
  <dd>Definition 1</dd>
  <dt>Term 2</dt>
  <dd>Definition 2</dd>
</dl>
''';
      final markdown = converter.convert(html);
      expect(markdown, contains('**Term 1**'));
      expect(markdown, contains(': Definition 1'));
      expect(markdown, contains('**Term 2**'));
      expect(markdown, contains(': Definition 2'));
    });

    test('converts details/summary', () {
      const html = '''
<details>
  <summary>Summary</summary>
  Details content
</details>
''';
      // We'll preserve HTML for details as it's often supported in markdown rendering
      // OR we can just output the content.
      // Preserving HTML is usually safer for details.
      final markdown = converter.convert(html);
      expect(markdown, contains('<details>'));
      expect(markdown, contains('<summary>Summary</summary>'));
      expect(markdown, contains('Details content'));
      expect(markdown, contains('</details>'));
    });
  });
}
