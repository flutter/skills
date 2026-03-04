// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

import 'package:skills/src/services/resource_fetcher_service.dart';
import 'package:test/test.dart';

void main() {
  group('ResourceFetcherService', () {
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

      final fetcher = ResourceFetcherService(
        httpClient: client,
        logger: logger,
      );

      final result = await fetcher.fetchAndConvertContent([
        'https://example.com/doc1',
        'https://example.com/doc2',
      ]);

      expect(result, contains('Doc 1'));
      expect(result, contains('Doc 2 content'));
    });

    test('throws Exception on non-200 status code to save tokens', () async {
      final client = MockClient((request) async {
        return http.Response('Not found', 404);
      });

      final fetcher = ResourceFetcherService(
        httpClient: client,
        logger: logger,
      );

      expect(
        () => fetcher.fetchAndConvertContent(['https://example.com/missing']),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('HTTP 404'),
          ),
        ),
      );
    });

    test('throws exception on network error to save tokens', () async {
      final client = MockClient((request) async {
        throw http.ClientException('Connection failed');
      });

      final fetcher = ResourceFetcherService(
        httpClient: client,
        logger: logger,
      );

      expect(
        () => fetcher.fetchAndConvertContent(['https://example.com/error']),
        throwsA(isA<http.ClientException>()),
      );
    });

    test('throws Exception for insecure http:// URL', () async {
      final client = MockClient((request) async {
        return http.Response('content', 200);
      });

      final fetcher = ResourceFetcherService(
        httpClient: client,
        logger: logger,
      );

      expect(
        () => fetcher.fetchAndConvertContent(['http://example.com/doc1']),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Insecure HTTP URL found'),
          ),
        ),
      );
    });

    test('fetches local file correctly relative to configDir', () async {
      final tempDir = io.Directory.systemTemp.createTempSync('gemini_test');
      try {
        io.File(
          p.join(tempDir.path, 'local_doc.md'),
        ).writeAsStringSync('# Local Doc\ncontent');

        final client = MockClient((request) async {
          return http.Response('Not found', 404);
        });

        final fetcher = ResourceFetcherService(
          httpClient: client,
          logger: logger,
        );

        final result = await fetcher.fetchAndConvertContent([
          'local_doc.md',
        ], configDir: tempDir);

        expect(result, contains('Local Doc'));
        expect(result, contains('content'));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('throws Exception for missing local file', () async {
      final tempDir = io.Directory.systemTemp.createTempSync('gemini_test');
      try {
        final client = MockClient((request) async {
          return http.Response('Not found', 404);
        });

        final fetcher = ResourceFetcherService(
          httpClient: client,
          logger: logger,
        );

        expect(
          () => fetcher.fetchAndConvertContent([
            'missing.md',
          ], configDir: tempDir),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Local resource file not found'),
            ),
          ),
        );
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
      'throws Exception for local file when no configDir is provided',
      () async {
        final client = MockClient((request) async {
          return http.Response('Not found', 404);
        });

        final fetcher = ResourceFetcherService(
          httpClient: client,
          logger: logger,
        );

        expect(
          () => fetcher.fetchAndConvertContent(['local_doc.md']),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('no configuration directory was provided to resolve it'),
            ),
          ),
        );
      },
    );
  });
}
