# Feature Design Doc: Resolving Legacy Inconsistencies in Rule Resolution

This document analyzes patterns of code where legacy implementations create inconsistencies, specifically around rule resolution, configuration overrides, and global state management.

## Identified Inconsistencies

### 1. Mutable Global State in `CheckType`

The `CheckType` objects defined in `lib/src/rules.dart` behave as global singletons. While they are declared `final` as variables, their `severity` field itself is mutable.

-   **Impact**: When `config_parser.dart` or `entry_point.dart` updates rule severities from a configuration file or CLI flags, they directly mutate these global objects.
-   **Inconsistency**: This conflicts with the new Dependency Injection pattern in `Validator`, which is designed to receive an isolated set of rule configurations for a specific validation run. If we mutate global state, two independent `Validator` instances created in the same process would share the same rule severities.

### 2. Side-Effects in Configuration Parsing

The `loadConfig` function in `lib/src/config_parser.dart` takes a `Set<CheckType> checkTypes` and mutates it as a side effect while parsing global rules.

-   **Impact**: Code calling `loadConfig` gets its input modified without an explicit return value indicating the change.
-   **Inconsistency**: It mixes "reading configuration" with "updating application state".

### 3. Fragmentation in Directory Overrides

In `lib/src/entry_point.dart`, overrides for specific directories are resolved manually using hardcoded string keys (e.g., `'check-relative-paths'`), rather than leveraging the typed `CheckType` objects or a dynamic loop.

-   **Impact**: When we added the explicit rule injection to `Validator`, we had to introduce local shadowing variables to bridge the gap between hardcoded config overrides and the `Validator` constructor.
-   **Inconsistency**: Rule lookup logic is split across multiple styles (string-based maps vs typed `CheckType` instances).

---

## Proposed Solutions

### Solution 1: Immutable `CheckType` with `copyWith`

Make `CheckType` fully immutable by marking all fields as `final`. Introduce a `copyWith` method to create modified instances safely.

```dart
class CheckType {
  final String name;
  final AnalysisSeverity defaultSeverity;
  final AnalysisSeverity severity; // Changed to final

  CheckType({
    required this.name,
    required this.defaultSeverity,
    AnalysisSeverity? severity,
  }) : severity = severity ?? defaultSeverity;

  CheckType copyWith({
    String? name,
    AnalysisSeverity? defaultSeverity,
    AnalysisSeverity? severity,
  }) {
    return CheckType(
      name: name ?? this.name,
      defaultSeverity: defaultSeverity ?? this.defaultSeverity,
      severity: severity ?? this.severity,
    );
  }
}
```

This was also suggested in `FEATURE_REQUESTS.md`. By using immutable data types, we can pass configuration around without risking unintended side leaks.

### Solution 2: Functional `loadConfig`

Refactor `loadConfig` to return a `Configuration` object that encapsulates *all* resolved rule overrides, rather than mutating its inputs.

```dart
// Suggested loadConfig signature
Future<Configuration> loadConfig() async { ... }

class Configuration {
  final Map<String, AnalysisSeverity> globalRuleOverrides;
  final List<DirectoryConfig> directoryConfigs;
  // ...
}
```

### Solution 3: Dynamic Rule Resolution in Entry Point

Instead of hardcoding rules in the directory loop, we can map directory config rules directly to creating a `Validator` instance.

```dart
// Pre-resolve directory rules by name in entry_point.dart
final Map<String, AnalysisSeverity> resolvedLocalRules = {};

// Fallback to global rules
for (final rule in globalRules) {
   resolvedLocalRules[rule.name] = rule.severity;
}

// Override with specific directory rules
for (final key in dirConfig.rules.keys) {
   resolvedLocalRules[key] = dirConfig.rules[key]!;
}

// Create Validator with these local overrides
final localValidator = Validator(
  rules: resolvedLocalRules.entries.map((e) => CheckType(name: e.key, defaultSeverity: e.value)).toSet(),
);
```

This unifies rule resolution into a single dynamic pattern.

---
## Verification Plan

### Automated Tests
1. Add tests verify rule overriding works correctly without leak when `copyWith` is used in parallel validation runs.
2. Verify that `loadConfig` works when called multiple times without affecting previous parsed states.
