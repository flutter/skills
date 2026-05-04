// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Baseline-generation throughput benchmark for `dart_skills_lint`.
///
/// Generates synthetic skill directories at multiple sizes, runs them through
/// `validateSkills` with `--generate-baseline`, and prints a wall-clock table.
/// Intentionally not run in CI — see `bench/README.md`.
library;

import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_skills_lint/dart_skills_lint.dart';
import 'package:path/path.dart' as p;

const String _sizesFlag = 'sizes';
const String _errorsPerSkillFlag = 'errors-per-skill';
const String _runsFlag = 'runs';
const String _warmupFlag = 'warmup';
const String _helpFlag = 'help';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      _sizesFlag,
      defaultsTo: '10,100,1000',
      help: 'Comma-separated list of N values (number of synthetic skills) to benchmark.',
    )
    ..addOption(
      _errorsPerSkillFlag,
      defaultsTo: '1',
      help: 'Number of baseline-recordable errors each synthetic skill should produce (1-3).',
    )
    ..addOption(_runsFlag, defaultsTo: '3', help: 'Number of timed runs per cell.')
    ..addOption(_warmupFlag, defaultsTo: '1', help: 'Number of untimed warmup runs before timing.')
    ..addFlag(_helpFlag, abbr: 'h', negatable: false, help: 'Show usage information.');

  try {
    final ArgResults results = parser.parse(args);

    if (results[_helpFlag] as bool) {
      stdout.writeln('Usage: dart run bench/baseline_throughput.dart [options]');
      stdout.writeln(parser.usage);
      return;
    }

    final List<int> sizes = _parseSizes(results[_sizesFlag] as String);
    final int errorsPerSkill = _clampErrorsPerSkill(
      _parsePositiveInt(results[_errorsPerSkillFlag] as String, _errorsPerSkillFlag),
    );
    final int runs = _parsePositiveInt(results[_runsFlag] as String, _runsFlag);
    final int warmup = _parseNonNegativeInt(results[_warmupFlag] as String, _warmupFlag);

    final rows = <_Row>[];
    for (final n in sizes) {
      final _Row row = await _benchSize(
        n: n,
        errorsPerSkill: errorsPerSkill,
        runs: runs,
        warmup: warmup,
      );
      rows.add(row);
    }

    _printTable(rows);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stderr.writeln(parser.usage);
  }
}

int _parsePositiveInt(String raw, String flag) {
  final int value =
      int.tryParse(raw) ?? (throw FormatException('--$flag must be an integer (got "$raw").'));
  if (value < 1) {
    throw FormatException('--$flag must be >= 1 (got $value).');
  }
  return value;
}

int _parseNonNegativeInt(String raw, String flag) {
  final int value =
      int.tryParse(raw) ?? (throw FormatException('--$flag must be an integer (got "$raw").'));
  if (value < 0) {
    throw FormatException('--$flag must be >= 0 (got $value).');
  }
  return value;
}

List<int> _parseSizes(String raw) {
  final sizes = <int>[];
  for (final String token in raw.split(',').map((String s) => s.trim())) {
    if (token.isEmpty) {
      continue;
    }
    final int? n = int.tryParse(token);
    if (n == null || n < 1) {
      throw FormatException('--$_sizesFlag entries must be positive integers (got "$token").');
    }
    sizes.add(n);
  }
  if (sizes.isEmpty) {
    throw const FormatException('--sizes must contain at least one positive integer.');
  }
  return sizes;
}

int _clampErrorsPerSkill(int requested) {
  const maxSupported = 3;
  if (requested < 1) {
    stderr.writeln('errors-per-skill must be >= 1; using 1.');
    return 1;
  }
  if (requested > maxSupported) {
    stderr.writeln(
      'errors-per-skill > $maxSupported is not supported (only $maxSupported distinct '
      'baseline-recordable rules trigger per skill); clamping to $maxSupported.',
    );
    return maxSupported;
  }
  return requested;
}

Future<_Row> _benchSize({
  required int n,
  required int errorsPerSkill,
  required int runs,
  required int warmup,
}) async {
  final Directory tempDir = Directory.systemTemp.createTempSync('dskl_bench_');
  try {
    final skillsRoot = Directory(p.join(tempDir.path, 'skills'))..createSync();
    for (var i = 0; i < n; i++) {
      _writeSyntheticSkill(skillsRoot, i, errorsPerSkill);
    }
    final String ignorePath = p.join(tempDir.path, 'ignore.json');

    for (var i = 0; i < warmup; i++) {
      await _runOnce(skillsRoot.path, ignorePath);
    }

    final samples = <int>[];
    for (var i = 0; i < runs; i++) {
      final int ms = await _runOnce(skillsRoot.path, ignorePath);
      samples.add(ms);
    }

    samples.sort();
    final int min = samples.first;
    final int max = samples.last;
    final int median = samples[samples.length ~/ 2];
    return _Row(n: n, minMs: min, medianMs: median, maxMs: max, runs: runs);
  } finally {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }
}

Future<int> _runOnce(String skillsRootPath, String ignorePath) async {
  final ignoreFile = File(ignorePath);
  if (ignoreFile.existsSync()) {
    ignoreFile.deleteSync();
  }
  final sw = Stopwatch()..start();
  await validateSkills(
    skillDirPaths: <String>[skillsRootPath],
    generateBaseline: true,
    quiet: true,
    ignoreFileOverride: ignorePath,
  );
  sw.stop();
  return sw.elapsedMilliseconds;
}

void _writeSyntheticSkill(Directory skillsRoot, int index, int errorsPerSkill) {
  final dirName = 'skill-$index';
  final skillDir = Directory(p.join(skillsRoot.path, dirName))..createSync();

  // Error 1: name mismatch — `name:` does not match the directory name.
  // This always triggers `invalid-skill-name`.
  const name = 'wrong-name-on-purpose';

  // Error 2 (when errorsPerSkill >= 2): description longer than 1024 chars
  // triggers `description-too-long`.
  final String description = errorsPerSkill >= 2
      ? 'x' * 1100
      : 'Synthetic skill for benchmarking; '
            'the yaml name does not match the directory name '
            'so the linter records a name-format error.';

  // Error 3 (when errorsPerSkill >= 3): an absolute-path link in the body
  // triggers `check-absolute-paths` (warning, but baseline-recordable). Using
  // `p.absolute(...)` guarantees the link is absolute on the host OS regardless
  // of platform (POSIX or Windows).
  final body = errorsPerSkill >= 3
      ? '# Test skill\n\n[abs](${p.absolute('synthetic-abs-path')})\n'
      : '# Test skill\n';

  final sb = StringBuffer()
    ..writeln('---')
    ..writeln('name: $name')
    ..writeln('description: $description')
    ..writeln('---')
    ..writeln()
    ..write(body);

  File(p.join(skillDir.path, 'SKILL.md')).writeAsStringSync(sb.toString());
}

void _printTable(List<_Row> rows) {
  stdout.writeln('N      | min   | median | max   | runs');
  stdout.writeln('-------|-------|--------|-------|-----');
  for (final row in rows) {
    stdout.writeln(
      '${_padRight(row.n.toString(), 6)} '
      '| ${_padLeft('${row.minMs}ms', 5)} '
      '| ${_padLeft('${row.medianMs}ms', 6)} '
      '| ${_padLeft('${row.maxMs}ms', 5)} '
      '| ${row.runs}',
    );
  }
}

String _padRight(String s, int width) => s.padRight(width);
String _padLeft(String s, int width) => s.padLeft(width);

class _Row {
  _Row({
    required this.n,
    required this.minMs,
    required this.medianMs,
    required this.maxMs,
    required this.runs,
  });

  final int n;
  final int minMs;
  final int medianMs;
  final int maxMs;
  final int runs;
}
