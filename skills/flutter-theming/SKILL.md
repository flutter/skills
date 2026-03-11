---
name: "flutter-theming"
description: "How to customize your app's theme using Flutter's theming system"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 17:38:43 GMT"

---
# Theming-And-Adapting-Flutter-Apps

## When to Use
* The agent needs to implement or migrate app-wide or component-specific themes in a Flutter application.
* The agent is upgrading a Flutter app to Material 3 (default as of Flutter 3.16).
* The agent is replacing deprecated Material 2 widgets (e.g., `FlatButton`, `RaisedButton`, `BottomNavigationBar`).
* The agent is adapting UI behaviors and idioms for specific platforms (e.g., desktop vs. mobile, Windows vs. macOS).

## Instructions

**Interaction Rule:** Evaluate the current project context for target Flutter version, Material 3 opt-in status, and target platforms (iOS, Android, Web, Desktop). If missing, ask the user for clarification before proceeding with implementation.

1. **Plan the Theme Hierarchy:** Determine the global `colorScheme` and `textTheme`. Material 3 relies heavily on `ColorScheme` rather than individual accent colors.
2. **Normalize Component Themes:** Audit the `ThemeData` configuration. Replace all deprecated component theme classes with their normalized `*ThemeData` equivalents (e.g., `CardTheme` to `CardThemeData`).
3. **Migrate Legacy Widgets:** Scan the codebase for deprecated Material 2 widgets and replace them with their Material 3 counterparts.
4. **Apply Platform Idioms:** Implement platform-aware logic for scrollbars, text selection, and button ordering to match native user expectations.
5. **Execute Implementation:** Apply the updated `ThemeData` to the `MaterialApp` and verify component overrides using `Theme.of(context)`.

## Decision Logic

Use the following decision tree to guide widget migration and theme configuration:

* **Is the app using Material 3?**
  * **Yes:** Proceed with standard `ThemeData`. (Material 3 is default in Flutter >= 3.16).
  * **No:** Set `useMaterial3: true` in `ThemeData` to force migration.
* **Are you styling a Button?**
  * **Legacy `FlatButton`:** Use `TextButton`.
  * **Legacy `RaisedButton`:** Use `ElevatedButton` or `FilledButton`.
  * **Legacy `OutlineButton`:** Use `OutlinedButton`.
* **Are you configuring a Component Theme in `ThemeData`?**
  * **Card:** Use `CardThemeData` (NOT `CardTheme`).
  * **Dialog:** Use `DialogThemeData` (NOT `DialogTheme`).
  * **TabBar:** Use `TabBarThemeData` (NOT `TabBarTheme`).
  * **AppBar:** Use `AppBarThemeData` and configure `backgroundColor` (NOT `color`).
  * **BottomAppBar:** Use `BottomAppBarThemeData`.
  * **InputDecoration:** Use `InputDecorationThemeData`.
* **Are you building for Desktop/Web?**
  * **Text:** Use `SelectableText` instead of `Text` for readable content.
  * **Scrollbars:** Set `thumbVisibility: true` on `Scrollbar` for desktop platforms.
  * **Dialog Buttons:** Check `Platform.isWindows`. If true, place the confirmation button on the left. Otherwise, place it on the right.

## Best Practices

* **Generate Color Schemes:** Use `ColorScheme.fromSeed(seedColor: Colors.blue)` to automatically generate accessible, Material 3-compliant color palettes.
* **Avoid Deprecated Accent Properties:** Never use `accentColor`, `accentColorBrightness`, `accentTextTheme`, or `accentIconTheme`. Use `colorScheme.secondary` and `colorScheme.onSecondary` instead.
* **Use Normalized Theme Data:** Always use the `*ThemeData` suffix classes when defining component themes inside the global `ThemeData` object to ensure API consistency.
* **Style Buttons Semantically:** Use the static `styleFrom()` method (e.g., `TextButton.styleFrom()`) for simple button styling. Use `ButtonStyle` with `MaterialStateProperty.resolveWith` only when you need state-dependent visual properties (e.g., hover, pressed, disabled).
* **Respect Platform Idioms:** Implement adaptive layouts that respect platform norms. Use `DeviceType` or `Platform` checks to adjust scrollbar visibility, multi-select modifier keys (Ctrl vs. Cmd), and horizontal button ordering.

## Examples

### Gold Standard: Material 3 Theme Setup with Normalized Components

```dart
import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    brightness: Brightness.light,
  ),
  // Use normalized *ThemeData classes
  cardTheme: const CardThemeData(
    elevation: 2.0,
    margin: EdgeInsets.all(8.0),
  ),
  dialogTheme: DialogThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
    ),
  ),
  appBarTheme: const AppBarThemeData(
    backgroundColor: Colors.deepPurple, // Use backgroundColor, NOT color
    elevation: 4.0,
    centerTitle: true,
  ),
  tabBarTheme: const TabBarThemeData(
    tabAlignment: TabAlignment.center,
  ),
  inputDecorationTheme: const InputDecorationThemeData(
    border: OutlineInputBorder(),
    filled: true,
  ),
);

void main() {
  runApp(
    MaterialApp(
      title: 'M3 Normalized Theme',
      theme: appTheme,
      home: const Scaffold(),
    ),
  );
}
```

### Gold Standard: Button Migration and Styling

```dart
import 'package:flutter/material.dart';

class ModernButtons extends StatelessWidget {
  const ModernButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Replaces FlatButton
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () {},
          child: const Text('Text Button'),
        ),
        
        // Replaces RaisedButton
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            elevation: 2.0,
          ),
          onPressed: () {},
          child: const Text('Elevated Button'),
        ),

        // Replaces OutlineButton with state-dependent styling
        OutlinedButton(
          style: ButtonStyle(
            side: MaterialStateProperty.resolveWith<BorderSide>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.pressed)) {
                  return BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2.0,
                  );
                }
                return const BorderSide(color: Colors.grey, width: 1.0);
              },
            ),
          ),
          onPressed: () {},
          child: const Text('Outlined Button'),
        ),
      ],
    );
  }
}
```

### Gold Standard: Adaptive Platform Idioms (Dialog Buttons & Text)

```dart
import 'dart:io';
import 'package:flutter/material.dart';

class AdaptiveIdioms extends StatelessWidget {
  const AdaptiveIdioms({super.key});

  @override
  Widget build(BuildContext context) {
    // Windows places confirmation buttons on the left (start).
    // macOS/Linux/Mobile place confirmation buttons on the right (end).
    final TextDirection btnDirection = Platform.isWindows 
        ? TextDirection.rtl 
        : TextDirection.ltr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Use SelectableText for desktop/web environments
        const SelectableText(
          'This text can be selected by a mouse cursor, matching web/desktop expectations.',
        ),
        const SizedBox(height: 24.0),
        Row(
          children: [
            const Spacer(),
            Row(
              textDirection: btnDirection,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
```
