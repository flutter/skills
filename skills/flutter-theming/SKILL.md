---
name: "flutter-theming"
description: "How to customize your app's theme using Flutter's theming system"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 18:04:38 GMT"

---
# Implementing-Flutter-Theming-And-Adaptive-UI

## When to Use
* The agent is configuring app-wide or component-specific styling in a Flutter application.
* The agent is migrating a legacy Flutter app to Material 3.
* The agent is updating deprecated theme properties (e.g., `accentColor`, `AppBarTheme.color`, legacy buttons).
* The agent is building adaptive interfaces that must conform to specific platform idioms (Windows, macOS, Linux, iOS, Android).

## Instructions

**Interaction Rule:** Evaluate the current project context for existing `ThemeData` configurations, target platforms, and branding requirements. If target platforms or base brand colors are missing, ask the user for clarification before proceeding with implementation.

1. **Plan the Color Scheme:** Use `ColorScheme.fromSeed` to generate a Material 3 compliant color palette based on the primary brand color.
2. **Normalize Component Themes:** Define component overrides inside `ThemeData` using the normalized `*ThemeData` classes (e.g., `CardThemeData`, `AppBarThemeData`).
3. **Replace Legacy Components:** Swap deprecated Material 2 widgets (e.g., `RaisedButton`, `BottomNavigationBar`) with their Material 3 equivalents (`ElevatedButton`, `NavigationBar`).
4. **Implement Platform Idioms:** Apply conditional logic for scrollbar visibility, text selection, and button ordering based on the target operating system.
5. **Execute Implementation:** Apply the theme to the `MaterialApp` and use `Theme.of(context)` for local widget overrides.

## Decision Logic

Use the following decision trees to resolve deprecations and apply correct Material 3 patterns:

**Legacy Button Migration:**
* If `FlatButton` -> Use `TextButton`.
* If `RaisedButton` -> Use `ElevatedButton`.
* If `OutlineButton` -> Use `OutlinedButton`.

**Theme Property Normalization:**
* If overriding `CardTheme` -> Use `CardThemeData`.
* If overriding `DialogTheme` -> Use `DialogThemeData`.
* If overriding `TabBarTheme` -> Use `TabBarThemeData`.
* If overriding `AppBarTheme` -> Use `AppBarThemeData`.
* If overriding `BottomAppBarTheme` -> Use `BottomAppBarThemeData`.
* If overriding `InputDecorationTheme` -> Use `InputDecorationThemeData`.

**Deprecated Color Properties:**
* If `accentColor` -> Use `colorScheme.secondary`.
* If `accentColorBrightness` -> Use `ThemeData.estimateBrightnessForColor()`.
* If `accentTextTheme` -> Use `textTheme` with `colorScheme.onSecondary`.
* If `AppBarTheme.color` -> Use `AppBarTheme.backgroundColor`.

**Platform-Specific Button Ordering (Dialogs):**
* If `Platform.isWindows` -> Place the confirmation button on the left (Start).
* If `Platform.isMacOS` / `Platform.isLinux` / Mobile -> Place the confirmation button on the right (End).

## Best Practices

* **Enforce Material 3:** Rely on Material 3 as the default. Do not set `useMaterial3: false` unless explicitly instructed to maintain a legacy design system.
* **Use `styleFrom` for Simple Button Styling:** When overriding button styles without state dependencies, use the static `styleFrom()` method (e.g., `ElevatedButton.styleFrom(backgroundColor: Colors.red)`).
* **Use `MaterialStateProperty` for Complex Button Styling:** When button visuals must change based on state (hovered, pressed, disabled), construct a `ButtonStyle` object using `MaterialStateProperty.resolveWith`.
* **Adapt Scrollbars for Desktop:** Always wrap scrollable areas in a `Scrollbar` widget and set `thumbVisibility: true` when the app is running on a desktop platform.
* **Make Text Selectable:** Use `SelectableText` instead of `Text` for static content in web and desktop applications to meet user expectations.
* **Avoid Hardcoded Colors:** Always derive colors from `Theme.of(context).colorScheme` to ensure seamless transitions between light and dark modes.

## Examples

### Example 1: Modern Material 3 App Theme Configuration

```dart
import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF6200EE),
    brightness: Brightness.light,
  ),
  // Use normalized *ThemeData classes
  appBarTheme: const AppBarThemeData(
    backgroundColor: Color(0xFF6200EE), // Replaces deprecated 'color'
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  cardTheme: const CardThemeData(
    elevation: 2,
    margin: EdgeInsets.all(8),
  ),
  inputDecorationTheme: const InputDecorationThemeData(
    border: OutlineInputBorder(),
    filled: true,
  ),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Modern Theme App',
      theme: lightTheme,
      home: const HomeScreen(),
    );
  }
}
```

### Example 2: State-Dependent Button Styling

```dart
import 'package:flutter/material.dart';

class CustomOutlinedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;

  const CustomOutlinedButton({
    super.key,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return OutlinedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        // Use MaterialStateProperty to handle different interaction states
        side: MaterialStateProperty.resolveWith<BorderSide>((Set<MaterialState> states) {
          if (states.contains(MaterialState.pressed)) {
            return BorderSide(color: colorScheme.primary, width: 2);
          }
          if (states.contains(MaterialState.disabled)) {
            return BorderSide(color: colorScheme.onSurface.withOpacity(0.12), width: 1);
          }
          return BorderSide(color: colorScheme.outline, width: 1);
        }),
        overlayColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
          if (states.contains(MaterialState.hovered)) {
            return colorScheme.primary.withOpacity(0.04);
          }
          if (states.contains(MaterialState.focused) || states.contains(MaterialState.pressed)) {
            return colorScheme.primary.withOpacity(0.12);
          }
          return null; // Defer to the widget's default
        }),
      ),
      child: Text(label),
    );
  }
}
```

### Example 3: Adaptive Dialog Button Ordering

```dart
import 'dart:io';
import 'package:flutter/material.dart';

class AdaptiveDialogActionRow extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const AdaptiveDialogActionRow({
    super.key,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    // Windows places the confirmation button on the left.
    // macOS/Linux/Mobile place the confirmation button on the right.
    final bool isWindows = Platform.isWindows;
    final TextDirection btnDirection = isWindows ? TextDirection.rtl : TextDirection.ltr;

    return Row(
      children: [
        const Spacer(),
        Row(
          textDirection: btnDirection,
          children: [
            TextButton(
              onPressed: onCancel,
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onConfirm,
              child: const Text('Confirm'),
            ),
          ],
        ),
      ],
    );
  }
}
```
