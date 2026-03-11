---
name: "flutter-localization"
description: "Configure your Flutter app to support different languages and regions"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 18:06:58 GMT"

---
# Internationalizing-Flutter-Apps

## When to Use
* The agent needs to add multi-language support, regional formatting (dates, currencies), or right-to-left (RTL) layout support to a Flutter application.
* The project requires extracting hardcoded strings into App Resource Bundle (`.arb`) files for translation.
* The agent encounters assertion errors indicating a missing `MaterialLocalizations` ancestor (e.g., when using `TextField`) or a missing `Localizations` parent (e.g., when using `CupertinoTabBar`).
* The application targets iOS and requires localized App Store metadata.

## Decision Logic
Evaluate the current localization requirements to determine the correct implementation path:

1. **Is the app missing core localization dependencies?**
   * **Yes:** Add `flutter_localizations` and `intl` to `pubspec.yaml`. Enable `generate: true`.
2. **Does the app need custom translated strings?**
   * **Yes:** Create an `l10n.yaml` configuration file and define `.arb` files in `lib/l10n/`. Use `AppLocalizations.delegate`.
3. **Are you localizing for languages with multiple scripts/regions (e.g., Chinese, French)?**
   * **Yes:** Use `Locale.fromSubtags(languageCode, scriptCode, countryCode)` instead of the default `Locale` constructor.
4. **Is a widget (like `TextField` or `CupertinoTabBar`) throwing a `Localizations` assertion error?**
   * **Yes:** Ensure the widget is a descendant of `MaterialApp`/`CupertinoApp`. If it cannot be, wrap the widget in a `Localizations` widget with the required delegates (`DefaultMaterialLocalizations.delegate`, etc.).
5. **Is the app being deployed to iOS?**
   * **Yes:** You must update `ios/Runner.xcodeproj` to include the supported languages so the App Store displays them correctly.

## Instructions

**Interaction Rule:** Evaluate the `pubspec.yaml` and project structure for existing localization configurations (`l10n.yaml`, `.arb` files). If the target locales are missing or ambiguous, ask the user for the required supported languages before proceeding.

**Plan:**
1. Configure dependencies and enable code generation.
2. Set up the localization configuration and translation files.
3. Inject the generated delegates and supported locales into the app root.
4. Configure native platform settings (iOS).

**Execute:**
1. Add `flutter_localizations` (SDK dependency) and `intl` to `pubspec.yaml`. Set `generate: true` under the `flutter` section.
2. Create `l10n.yaml` in the project root to define the input directory, template file, and output class.
3. Create the template `.arb` file (e.g., `lib/l10n/app_en.arb`) and subsequent translation files (e.g., `lib/l10n/app_es.arb`).
4. Import the generated `AppLocalizations` class and apply `AppLocalizations.localizationsDelegates` and `AppLocalizations.supportedLocales` to the `MaterialApp` or `CupertinoApp`.
5. For iOS, instruct the user or modify the `ios/Runner.xcodeproj/project.pbxproj` to add the supported languages to the `Info` tab.

## Best Practices

* **Use Code Generation:** Always use the `gen-l10n` tool via `l10n.yaml` rather than manually creating localization delegates.
* **Define Advanced Locales Precisely:** For languages like Chinese, fully differentiate variants using `Locale.fromSubtags` (e.g., `languageCode: 'zh', scriptCode: 'Hans', countryCode: 'CN'`).
* **Handle Plurals and Placeholders in ARB:** Utilize ICU message syntax in `.arb` files for plurals, genders, and formatted parameters (e.g., `compactCurrency`, `yMd`) to offload formatting logic from Dart code.
* **Provide Fallback Localizations:** Always include `GlobalMaterialLocalizations.delegate`, `GlobalWidgetsLocalizations.delegate`, and `GlobalCupertinoLocalizations.delegate` to ensure base Flutter widgets are localized.
* **Isolate Widget Testing:** When testing widgets that require localizations (like `TextField`), wrap them in a `MaterialApp` or a `Localizations` widget to prevent assertion failures.

## Examples

### 1. Configuration and ARB Setup

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
```

**`lib/l10n/app_en.arb`**
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
  "itemCount": "{count, plural, =0{No items} =1{1 item} other{{count} items}}",
  "@itemCount": {
    "description": "A pluralized message",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}
```

### 2. App Initialization with Advanced Locales

**`lib/main.dart`**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.helloWorld,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // English (US)
        Locale('es', 'ES'), // Spanish (Spain)
        // Advanced locale definition for Chinese variants
        Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans', countryCode: 'CN'), // Simplified Chinese
        Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW'), // Traditional Chinese
      ],
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(title: Text(l10n.helloWorld)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.greeting('Alice')),
            Text(l10n.itemCount(5)),
            // TextField requires MaterialLocalizations, provided by MaterialApp
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(labelText: 'Enter text'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 3. Standalone Localizations Wrapper (For Isolated Widgets)

Use this pattern if a widget like `TextField` or `CupertinoTabBar` must be used outside of a `MaterialApp` or `CupertinoApp` root.

**`lib/isolated_widget.dart`**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class IsolatedTextField extends StatelessWidget {
  const IsolatedTextField({super.key});

  @override
  Widget build(BuildContext context) {
    return Localizations(
      locale: const Locale('en', 'US'),
      delegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      child: const Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: TextField(),
        ),
      ),
    );
  }
}
```
