---
name: "flutter-localization"
description: "Configure your Flutter app to support different languages and regions"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 17:41:02 GMT"

---
# Internationalizing-Flutter-Apps

## When to Use
* The agent needs to add multi-language support to a Flutter application.
* The project requires localized strings, date/time formatting, pluralization, or gender-based text rules.
* The agent encounters assertion errors related to missing `MaterialLocalizations` or `Localizations` parents (e.g., in `TextField` or `CupertinoTabBar`).
* The project is migrating from the synthetic `package:flutter_gen` to generated source files.

## Decision Logic
Evaluate the project requirements to determine the correct localization path:
* **If configuring standard app localization:** Use `flutter_localizations`, `intl`, and `l10n.yaml`.
* **If targeting iOS:** You MUST update the `ios/Runner.xcodeproj` to include supported languages; Flutter does not handle iOS native bundle localization automatically.
* **If rendering widgets outside a `MaterialApp` or `CupertinoApp`:** Wrap the widget tree with a `Localizations` widget and provide the necessary delegates (`DefaultMaterialLocalizations.delegate`, etc.).
* **If supporting languages with multiple scripts (e.g., Chinese):** Use `Locale.fromSubtags` to explicitly define `languageCode`, `scriptCode`, and `countryCode`.

## Instructions

**Interaction Rule:** Evaluate the current project context for `pubspec.yaml` dependencies (`flutter_localizations`, `intl`), `l10n.yaml` configuration, and target platforms (e.g., iOS). If missing or ambiguous, ask the user for clarification before proceeding with implementation.

1. **Configure Dependencies:** Add `flutter_localizations` and `intl` to `pubspec.yaml`. Enable the `generate: true` flag under the `flutter` section.
2. **Configure Code Generation:** Create an `l10n.yaml` file in the project root. Define the input directory, template file, and output file. Set `synthetic-package: false` to generate files directly into the source directory.
3. **Define ARB Files:** Create Application Resource Bundle (`.arb`) files in the designated directory (e.g., `lib/l10n/app_en.arb`). Define key-value pairs, placeholders, plurals, and selects.
4. **Initialize App:** Import the generated `app_localizations.dart` file. Register `AppLocalizations.localizationsDelegates` and `AppLocalizations.supportedLocales` in the root `MaterialApp` or `CupertinoApp`.
5. **Update iOS Bundle:** If iOS is a target, open `ios/Runner.xcodeproj` and add the supported languages in the Info tab under Localizations.

## Best Practices
* **Generate into Source:** Always use `synthetic-package: false` in `l10n.yaml` to generate localization files directly into the `lib/` directory. Do not rely on the legacy `package:flutter_gen` synthetic package.
* **Use ICU Syntax:** Handle pluralization and gender selection directly within the `.arb` files using ICU message syntax rather than writing conditional Dart logic.
* **Explicit Placeholders:** Define placeholders in `.arb` files with explicit types (`String`, `int`, `DateTime`) and formats (e.g., `compactCurrency`, `yMd`).
* **Provide Localizations Context:** Ensure widgets like `TextField` and `CupertinoTabBar` have a `Localizations` ancestor. If they do not descend from `MaterialApp`, inject a `Localizations` widget manually.
* **Differentiate Complex Locales:** Use `Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans', countryCode: 'CN')` instead of simple string locales for languages requiring script differentiation.

## Examples

### Gold Standard Configuration

**`pubspec.yaml`**
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: any

flutter:
  generate: true
```

**`l10n.yaml`**
```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
synthetic-package: false
```

### Gold Standard ARB Definition (`lib/l10n/app_en.arb`)
```json
{
  "@@locale": "en",
  "helloWorld": "Hello World!",
  "@helloWorld": {
    "description": "The conventional newborn programmer greeting"
  },
  "greeting": "Hello {userName}",
  "@greeting": {
    "description": "A message with a single parameter",
    "placeholders": {
      "userName": {
        "type": "String",
        "example": "Bob"
      }
    }
  },
  "wombatCount": "{count, plural, =0{no wombats} =1{1 wombat} other{{count} wombats}}",
  "@wombatCount": {
    "description": "A plural message",
    "placeholders": {
      "count": {
        "type": "int",
        "format": "compact"
      }
    }
  }
}
```

### Gold Standard App Initialization (`lib/main.dart`)
```dart
import 'package:flutter/material.dart';
// Import the generated file directly from the source directory
import 'l10n/app_localizations.dart'; 

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Localized App',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.helloWorld),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(l10n.greeting('Alice')),
            Text(l10n.wombatCount(5)),
          ],
        ),
      ),
    );
  }
}
```

### Standalone Widget Localization (Fixing TextField/CupertinoTabBar Errors)
When rendering a `TextField` or `CupertinoTabBar` outside of a `MaterialApp` or `CupertinoApp`, inject the required delegates manually.

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class StandaloneTextField extends StatelessWidget {
  const StandaloneTextField({super.key});

  @override
  Widget build(BuildContext context) {
    return Localizations(
      locale: const Locale('en', 'US'),
      delegates: const <LocalizationsDelegate<dynamic>>[
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
      ],
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Material(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Enter text here',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```
