// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:html/dom.dart';
import 'package:html/parser.dart';

/// Converts HTML content to Markdown.
class MarkdownConverter {
  /// Converts HTML content to Markdown.
  String convert(String htmlContent) {
    final document = parse(htmlContent);
    final body = document.body;
    if (body == null) return '';
    return _convertElement(body).trim();
  }

  String _convertElement(Element element) {
    final buffer = StringBuffer();

    for (final node in element.nodes) {
      if (node is Text) {
        buffer.write(node.text);
      } else if (node is Element) {
        buffer.write(_processTag(node));
      }
    }

    return buffer.toString();
  }

  String _processTag(Element element) {
    final content = _convertElement(element);

    switch (element.localName) {
      case 'h1':
        return '\n# $content\n\n';
      case 'h2':
        return '\n## $content\n\n';
      case 'h3':
        return '\n### $content\n\n';
      case 'h4':
        return '\n#### $content\n\n';
      case 'h5':
        return '\n##### $content\n\n';
      case 'h6':
        return '\n###### $content\n\n';
      case 'p':
        return '$content\n\n';
      case 'a':
        final href = element.attributes['href'];
        return '[$content]($href)';
      case 'strong':
      case 'b':
        return '**$content**';
      case 'em':
      case 'i':
        return '*$content*';
      case 'del':
      case 's':
      case 'strike':
        return '~~$content~~';
      case 'code':
        return '`$content`';
      case 'pre':
        return '\n```\n${element.text}\n```\n\n';
      case 'blockquote':
        return '\n> $content\n\n';
      case 'hr':
        return '\n---\n\n';
      case 'ul':
        return '\n$content\n';
      case 'ol':
        return '\n$content\n';
      case 'li':
        return '- $content\n';
      case 'img':
        final src = element.attributes['src'] ?? '';
        final alt = element.attributes['alt'] ?? '';
        return '![$alt]($src)';
      case 'video':
        final src = element.attributes['src'] ?? '';
        final poster = element.attributes['poster'] ?? '';
        final title = element.attributes['title'] ?? 'Video';

        String? videoUrl;
        if (src.isNotEmpty) {
          videoUrl = src;
        } else {
          // Fallback for source elements
          videoUrl = element.children
              .where((e) => e.localName == 'source')
              .map((e) => e.attributes['src'])
              .firstWhere((s) => s != null, orElse: () => null);
        }

        if (videoUrl != null) {
          if (poster.isNotEmpty) {
            return '[![$title]($poster)]($videoUrl)';
          }
          return '[$title]($videoUrl)';
        }
        return '';
      case 'iframe':
        final src = element.attributes['src'] ?? '';
        final title = element.attributes['title'] ?? 'Iframe';
        if (src.isNotEmpty) {
          return '[$title]($src)';
        }
        return '';
      case 'table':
        return _processTable(element);
      case 'dl':
        return _processDefinitionList(element);
      case 'dt':
        return '\n**$content**\n';
      case 'dd':
        return ': $content\n';
      case 'details':
        // Preserve details as HTML, but convert children to markdown?
        // Or just preserve the tag structure and convert internal content.
        // Let's try to preserve the tag but convert content.
        return '\n<details>\n$content\n</details>\n';
      case 'summary':
        return '<summary>$content</summary>';
      case 'br':
        return '\n';
      case 'div':
      case 'section':
      case 'main':
      case 'article':
        return '$content\n';
      default:
        return content;
    }
  }

  String _processTable(Element table) {
    // Simple table converter
    // 1. Find headers (th)
    // 2. Find rows (tr)
    // 3. Construct markdown table

    final rows = table.querySelectorAll('tr');
    if (rows.isEmpty) return '';

    final buffer = StringBuffer('\n');
    var headerCells = <Element>[];
    final bodyRows = <Element>[];

    // Try to find thead
    final thead = table.querySelector('thead');
    if (thead != null) {
      final headerRow = thead.querySelector('tr');
      if (headerRow != null) {
        headerCells = headerRow.querySelectorAll('th');
        if (headerCells.isEmpty) {
          headerCells = headerRow.querySelectorAll('td');
        }
      }
    }

    // Try to find tbody
    final tbody = table.querySelector('tbody');
    if (tbody != null) {
      bodyRows.addAll(tbody.querySelectorAll('tr'));
    } else {
      // No tbody, check direct children
      final allRows = table.querySelectorAll('tr');
      for (final row in allRows) {
        if (thead != null && thead.contains(row)) continue;
        if (!bodyRows.contains(row)) {
          bodyRows.add(row);
        }
      }
    }

    // Promote first row to header if needed
    if (headerCells.isEmpty && bodyRows.isNotEmpty) {
      final firstRow = bodyRows.first;
      headerCells = firstRow.querySelectorAll('th');
      if (headerCells.isEmpty) {
        headerCells = firstRow.querySelectorAll('td');
      }
      if (bodyRows.isNotEmpty) bodyRows.removeAt(0);
    }

    if (headerCells.isEmpty && bodyRows.isEmpty) return '';

    // Write Header
    buffer.write('|');
    for (final cell in headerCells) {
      buffer.write(' ${_convertElement(cell).trim()} |');
    }
    buffer.write('\n|');
    for (var i = 0; i < headerCells.length; i++) {
      buffer.write('---|');
    }
    buffer.write('\n');

    // Write Body
    for (final row in bodyRows) {
      final cells = row.children
          .where((e) => e.localName == 'td' || e.localName == 'th')
          .toList();
      if (cells.isEmpty) continue;
      buffer.write('|');
      for (final cell in cells) {
        buffer.write(' ${_convertElement(cell).trim()} |');
      }
      buffer.write('\n');
    }
    buffer.write('\n');

    return buffer.toString();
  }

  String _processDefinitionList(Element dl) {
    final buffer = StringBuffer('\n');
    for (final child in dl.children) {
      buffer.write(_processTag(child));
    }
    buffer.write('\n\n');
    return buffer.toString();
  }
}
