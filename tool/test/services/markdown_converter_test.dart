// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:skills/src/services/markdown_converter.dart';
import 'package:test/test.dart';

void main() {
  group('MarkdownConverter', () {
    late MarkdownConverter converter;

    setUp(() {
      converter = MarkdownConverter();
    });

    test('converts headers', () {
      expect(converter.convert('<h1>Title</h1>'), contains('# Title'));
      expect(converter.convert('<h2>Subtitle</h2>'), contains('## Subtitle'));
      expect(converter.convert('<h3>Section</h3>'), contains('### Section'));
    });

    test('converts paragraphs', () {
      expect(converter.convert('<p>Hello World</p>'), contains('Hello World'));
    });

    test('converts links', () {
      expect(
        converter.convert('<a href="https://example.com">Link</a>'),
        contains('[Link](https://example.com)'),
      );
    });

    test('converts bold and italic', () {
      expect(converter.convert('<b>Bold</b>'), contains('**Bold**'));
      expect(
        converter.convert('<strong>Strong</strong>'),
        contains('**Strong**'),
      );
      expect(converter.convert('<i>Italic</i>'), contains('*Italic*'));
      expect(
        converter.convert('<em>Emphasized</em>'),
        contains('*Emphasized*'),
      );
    });

    test('converts code', () {
      expect(
        converter.convert('<code>print("hello")</code>'),
        contains('`print("hello")`'),
      );
      expect(
        converter.convert('<pre>void main() {}</pre>'),
        allOf(contains('```'), contains('void main() {}')),
      );
    });

    test('converts lists', () {
      const html = '''
        <ul>
          <li>Item 1</li>
          <li>Item 2</li>
        </ul>
      ''';
      final md = converter.convert(html);
      expect(md, contains('- Item 1'));
      expect(md, contains('- Item 2'));

      const htmlOl = '''
        <ol>
          <li>First</li>
          <li>Second</li>
        </ol>
      ''';
      final mdOl = converter.convert(htmlOl);
      // Currently the converter uses simplified list handling (returning - for both)
      expect(mdOl, contains('- First'));
      expect(mdOl, contains('- Second'));
    });

    test('converts line breaks', () {
      expect(converter.convert('Line 1<br>Line 2'), contains('Line 1\nLine 2'));
    });

    test('converts structural elements', () {
      expect(
        converter.convert('<div>Div Content</div>'),
        contains('Div Content'),
      );
      expect(
        converter.convert('<section>Section Content</section>'),
        contains('Section Content'),
      );
      expect(
        converter.convert('<main>Main Content</main>'),
        contains('Main Content'),
      );
      expect(
        converter.convert('<article>Article Content</article>'),
        contains('Article Content'),
      );
    });

    test('handles empty body', () {
      expect(converter.convert(''), isEmpty);
    });
  });
}
