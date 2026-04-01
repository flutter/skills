/// Severity level for a specific analysis rule.
enum AnalysisSeverity {
  /// Check is completely disabled.
  disabled,

  /// Failures are reported as warnings and do not fail the overall validation.
  warning,

  /// Failures are reported as errors and fail the overall validation.
  error,
}

/// Encapsulates metadata and severity state for a specific validation rule.
class CheckType {
  CheckType({
    required this.name,
    required this.defaultSeverity,
  }) : severity = defaultSeverity;
  final String name;

  /// The default severity if not overridden by config or flags.
  final AnalysisSeverity defaultSeverity;

  /// The current resolved severity for this run.
  AnalysisSeverity severity;
}
