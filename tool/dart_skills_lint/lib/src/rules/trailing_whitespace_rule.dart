// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../models/analysis_severity.dart';
import '../models/skill_context.dart';
import '../models/skill_rule.dart';
import '../models/validation_error.dart';

/// Enforces that lines in SKILL.md do not have trailing whitespace,
/// except for exactly two spaces which indicate a hard line break.
class TrailingWhitespaceRule extends SkillRule {
  TrailingWhitespaceRule({this.severity = defaultSeverity});

  static const String ruleName = 'check-trailing-whitespace';
  static const AnalysisSeverity defaultSeverity = AnalysisSeverity.disabled;
  static final RegExp _whitespaceRegExp = RegExp(r'([ \t]+)$');

  @override
  String get name => ruleName;

  @override
  final AnalysisSeverity severity;

  @override
  Future<List<ValidationError>> validate(SkillContext context) async {
    final errors = <ValidationError>[];
    final List<String> lines = context.rawContent.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final String line = lines[i];

      // Remove carriage return if present (Windows line endings)
      final String trimmedLine = line.endsWith('\r') ? line.substring(0, line.length - 1) : line;

      final RegExpMatch? match = _whitespaceRegExp.firstMatch(trimmedLine);
      if (match != null) {
        final String whitespace = match.group(1)!;
        String? message;

        if (whitespace.contains('\t')) {
          message = 'Line ${i + 1} has trailing whitespace containing tabs.';
        } else {
          final int spacesCount = whitespace.length;
          if (spacesCount == 1 || spacesCount >= 3) {
            message =
                'Line ${i + 1} has $spacesCount trailing space(s). Only exactly 2 spaces are allowed for line breaks.';
          }
        }

        if (message != null) {
          errors.add(ValidationError(
            ruleId: name,
            severity: severity,
            file: 'SKILL.md',
            message: message,
          ));
        }
      }
    }

    return errors;
  }
}
