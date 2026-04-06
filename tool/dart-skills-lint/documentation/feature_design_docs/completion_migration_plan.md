# Migration Plan: Adding Zsh Command Autocompletion (Approach A)

This document outlines the migration steps to add Zsh tab-autocompletion support to the `dart_skills_lint` CLI tool using Dart packages.

There are two main sub-approaches depending on whether we want to keep the current flat `ArgParser` structure or migrate to a more structured `CommandRunner` architecture.

---

## 🧭 Option A.1: Migrate to `CommandRunner` with `cli_completion` (Recommended)

If we plan to expand this CLI with subcommands in the future (e.g., `dart_skills_lint validate`, `dart_skills_lint init`, `dart_skills_lint check-ignore`), migrating to standard Dart `CommandRunner` is highly recommended.

### 📜 Step-by-step
1. **Add Dependency:**
   ```bash
   dart pub add cli_completion
   ```
2. **Refactor `entry_point.dart` to use `CompletionCommandRunner`:**
   Create a custom runner and commands.
   ```dart
   import 'package:cli_completion/cli_completion.dart';

   class SkillsLintRunner extends CompletionCommandRunner<int> {
     SkillsLintRunner() : super('dart_skills_lint', 'Linter for Agent Skills');

     @override
     Future<int?> runCommand(ArgResults topLevelResults) async {
       // Fast-track completions
       if (topLevelResults.command?.name == 'completion') {
         super.runCommand(topLevelResults);
         return 0;
       }
       return super.runCommand(topLevelResults);
     }
   }
   ```
3. **Move existing flags into a `ValidateCommand`:**
   Instead of top-level `ArgParser`, we encapsulate the validation logic inside a reusable Command class.
   ```dart
   class ValidateCommand extends Command<int> {
     @override
     String get name => 'validate';
     @override
     String get description => 'Validates agent skill directories.';

     ValidateCommand() {
       argParser..addFlag('quiet', negatable: false); // etc...
     }

     @override
     Future<int> run() async {
       // Run validation logic here
       return 0;
     }
   }
   ```
4. **Update `bin/dart_skills_lint.dart`:**
   Change `runApp(args)` to instantiate the new runner instead.

---

## ⚖️ Option A.2: Keep `ArgParser` and use `package:completion` (Simpler)

If we want to keep the tool's monolithic, single-command design without introducing sub-commands, we can use the lightweight `package:completion`.

### 📜 Step-by-step
1. **Add Dependency:**
   ```bash
   dart pub add completion
   ```
2. **Update `lib/src/entry_point.dart` parser runner:**
   Instead of `parser.parse(args)`, intercept the call to let the completion package proposal take precedence.
   ```dart
   import 'package:completion/completion.dart' as completion;

   Future<void> runApp(List<String> args) async {
     final parser = ArgParser();
     // ... add your flags ...

     // Intercept for completions
     completion.tryArgsCompletion(args, parser); 

     final results = parser.parse(args);
     // ... rest of validation logic ...
   }
   ```

---

## 🧪 Verification Plan

Regardless of the option chosen:

### Automated Tests
1. **Completion proposal test:** Verify that running `dart_skills_lint completion zsh` exits success code 0 and outputs setup instructions.
2. **Regression tests:** Run standard suite checks (`test/cli_integration_test.dart`) to ensure normal runs are not disrupted by interjections.

### Manual Verification
1. Install completion script locally using standard terminal evaluation and tap tab on `-d` to ensure directories are displayed.
