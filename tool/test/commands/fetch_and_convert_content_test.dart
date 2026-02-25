// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logging/logging.dart';
import 'package:skills/src/services/gemini_service.dart';

import 'package:test/test.dart';

void main() {
  group('fetchAndConvertContent', () {
    late Logger logger;
    late List<String> logs;

    setUp(() {
      logger = Logger('test');
      logs = [];
      Logger.root.onRecord.listen((record) {
        logs.add(record.message);
      });
    });

    test('fetches and converts content successfully', () async {
      final client = MockClient((request) async {
        if (request.url.toString() == 'https://example.com') {
          return http.Response('<h1>Hello</h1>', 200);
        }
        return http.Response('Not Found', 404);
      });

      final result = await fetchAndConvertContent(
        ['https://example.com'],
        client,
        logger,
      );

      expect(result, contains('--- Raw content from https://example.com ---'));
      expect(result, contains('# Hello'));
    });

    test('handles failed fetch', () async {
      final client = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      expect(
        () => fetchAndConvertContent(['https://example.com'], client, logger),
        throwsA(isA<Exception>()),
      );
    });

    test('handles exception during fetch', () async {
      final client = MockClient((request) async {
        throw Exception('Network error');
      });

      expect(
        () => fetchAndConvertContent(['https://example.com'], client, logger),
        throwsA(isA<Exception>()),
      );
    });
  });
}
