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

    test('converts basic HTML to Markdown', () {
      const html = '<h1>Title</h1><p>Paragraph</p>';
      final markdown = converter.convert(html);
      expect(markdown, contains('# Title'));
      expect(markdown, contains('Paragraph'));
    });

    test('converts images', () {
      const html = '<img src="image.png" alt="Alt Text">';
      final markdown = converter.convert(html);
      expect(markdown, equals('![Alt Text](image.png)'));
    });

    test('converts images without alt text', () {
      const html = '<img src="image.png">';
      final markdown = converter.convert(html);
      expect(markdown, equals('![](image.png)'));
    });

    test('converts unordered lists', () {
      const html = '<ul><li>Item 1</li><li>Item 2</li></ul>';
      final markdown = converter.convert(html);
      expect(markdown, contains('- Item 1'));
      expect(markdown, contains('- Item 2'));
    });

    test('converts nested elements', () {
      const html = '<div><p>Paragraph <strong>Bold</strong></p></div>';
      final markdown = converter.convert(html);
      expect(markdown, contains('Paragraph **Bold**'));
    });

    test('converts blockquotes', () {
      const html = '<blockquote>Quote</blockquote>';
      final markdown = converter.convert(html);
      expect(markdown, contains('> Quote'));
    });

    test('converts horizontal rules', () {
      const html = '<hr>';
      final markdown = converter.convert(html);
      expect(markdown, contains('---'));
    });

    test('converts strikethrough', () {
      const html = '<del>Deleted</del> <s>Struck</s> <strike>Strike</strike>';
      final markdown = converter.convert(html);
      expect(markdown, contains('~~Deleted~~'));
      expect(markdown, contains('~~Struck~~'));
      expect(markdown, contains('~~Strike~~'));
    });

    test('converts headers', () {
      const html = '<h4>H4</h4><h5>H5</h5><h6>H6</h6>';
      final markdown = converter.convert(html);
      expect(markdown, contains('#### H4'));
      expect(markdown, contains('##### H5'));
      expect(markdown, contains('###### H6'));
    });

    test('converts video with src', () {
      const html = '<video src="video.mp4" title="Video Title"></video>';
      final markdown = converter.convert(html);
      expect(markdown, equals('[Video Title](video.mp4)'));
    });

    test('converts video with source child', () {
      const html =
          '<video title="Video Title"><source src="video.mp4"></video>';
      final markdown = converter.convert(html);
      expect(markdown, equals('[Video Title](video.mp4)'));
    });

    test('converts video with poster', () {
      const html =
          '<video src="video.mp4" poster="poster.jpg" title="Video Title"></video>';
      final markdown = converter.convert(html);
      expect(markdown, equals('[![Video Title](poster.jpg)](video.mp4)'));
    });

    test('converts iframe', () {
      const html =
          '<iframe src="https://example.com" title="Example Iframe"></iframe>';
      final markdown = converter.convert(html);
      expect(markdown, equals('[Example Iframe](https://example.com)'));
    });
  });
}
