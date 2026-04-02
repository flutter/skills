// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'analysis_severity.dart';

/// Represents a single validation error found during analysis.
class ValidationError {
  ValidationError({
    required this.ruleId,
    required this.file,
    required this.message,
    required this.severity,
    this.isIgnored = false,
  });

  /// The unique rule ID (e.g., 'description_too_long').
  final String ruleId;

  /// The file name context (e.g., 'SKILL.md' or relative path).
  final String file;

  /// The human-readable error message.
  final String message;

  /// The severity of the error.
  final AnalysisSeverity severity;

  /// Whether this error has been ignored via configuration.
  bool isIgnored;
}
