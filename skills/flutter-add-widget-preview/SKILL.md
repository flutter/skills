---
name: flutter-add-widget-preview
description: Adds interactive widget previews to the project using the previews.dart system. Use when creating new UI components or updating existing screens to ensure consistent design and interactive testing.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Tue, 21 Apr 2026 20:05:23 GMT
---
# Previewing Flutter Widgets

## Contents
- [Preview Guidelines](#preview-guidelines)
- [Handling Limitations](#handling-limitations)
- [Workflows](#workflows)
- [Examples](#examples)

## Preview Guidelines

Use the Flutter Widget Previewer to render widgets in real-time, isolated from the full application context. 

- **Target Elements:** Apply the `@Preview` annotation to top-level functions, static methods within a class, or public widget constructors/factories that have no required arguments and return a `Widget` or `WidgetBuilder`.
- **Imports:** Always import `package:flutter/widget_previews.dart` to access the preview annotations.
- **Custom Annotations:** Extend the `Preview` class to create custom annotations that inject common properties (e.g., themes, wrappers) across multiple widgets.
- **Multiple Configurations:** Apply multiple `@Preview` annotations to a single target to generate multiple preview instances. Alternatively, extend `MultiPreview` to encapsulate common multi-preview configurations.
- **Runtime Transformations:** Override the `transform()` method in custom `Preview` or `MultiPreview` classes to modify preview configurations dynamically at runtime (e.g., generating names based on dynamic values, which is impossible in a `const` context).

## Handling Limitations

Adhere to the following constraints when authoring previewable widgets, as the Widget Previewer runs in a web environment:

- **No Native APIs:** Do not use native plugins or APIs from `dart:io` or `dart:ffi`. Widgets with transitive dependencies on `dart:io` or `dart:ffi` will throw exceptions upon invocation. Use conditional imports to mock or bypass these in preview mode.
- **Asset Paths:** Use package-based paths for assets loaded via `dart:ui` `fromAsset` APIs (e.g., `packages/my_package_name/assets/my_image.png` instead of `assets/my_image.png`).
- **Public Callbacks:** Ensure all callback arguments provided to preview annotations are public and constant to satisfy code generation requirements.
- **Constraints:** Apply explicit constraints using the `size` parameter in the `@Preview` annotation if your widget is unconstrained, as the previewer defaults to constraining them to approximately half the viewport.

## Workflows

### Creating a Widget Preview
Copy and track this checklist when implementing a new widget preview:

- [ ] Import `package:flutter/widget_previews.dart`.
- [ ] Identify a valid target (top-level function, static method, or parameter-less public constructor).
- [ ] Apply the `@Preview` annotation to the target.
- [ ] Configure preview parameters (`name`, `group`, `size`, `theme`, `brightness`, etc.) as needed.
- [ ] If applying the same configuration to multiple widgets, extract the configuration into a custom class extending `Preview`.

### Interacting with Previews
Follow the appropriate conditional workflow to launch and interact with the Widget Previewer:

**If using a supported IDE (Android Studio, IntelliJ, VS Code with Flutter 3.38+):**
1. Launch the IDE. The Widget Previewer starts automatically.
2. Open the "Flutter Widget Preview" tab in the sidebar.
3. Toggle "Filter previews by selected file" at the bottom left if you want to view previews outside the currently active file.

**If using the Command Line:**
1. Navigate to the Flutter project's root directory.
2. Run `flutter widget-preview start`.
3. View the automatically opened Chrome environment.

**Feedback Loop: Preview Iteration**
1. Modify the widget code or preview configuration.
2. Observe the automatic update in the Widget Previewer.
3. If global state (e.g., static initializers) was modified: Click the global hot restart button at the bottom right.
4. If only the local widget state needs resetting: Click the individual hot restart button on the specific preview card.
5. Review errors in the IDE/CLI console -> fix -> repeat.

## Examples

### Basic Preview
```dart
import 'package:flutter/widget_previews.dart';
import 'package:flutter/material.dart';

@Preview(name: 'My Sample Text', group: 'Typography')
Widget mySampleText() {
  return const Text('Hello, World!');
}
```

### Custom Preview with Runtime Transformation
```dart
import 'package:flutter/widget_previews.dart';
import 'package:flutter/material.dart';

final class TransformativePreview extends Preview {
  const TransformativePreview({
    super.name,
    super.group,
  });

  PreviewThemeData _themeBuilder() {
    return PreviewThemeData(
      materialLight: ThemeData.light(),
      materialDark: ThemeData.dark(),
    );
  }

  @override
  Preview transform() {
    final originalPreview = super.transform();
    final builder = originalPreview.toBuilder();
    
    builder
      ..name = 'Transformed - ${originalPreview.name}'
      ..theme = _themeBuilder;

    return builder.toPreview();
  }
}

@TransformativePreview(name: 'Custom Themed Button')
Widget myButton() => const ElevatedButton(onPressed: null, child: Text('Click'));
```

### MultiPreview Implementation
```dart
import 'package:flutter/widget_previews.dart';
import 'package:flutter/material.dart';

/// Creates light and dark mode previews automatically.
final class MultiBrightnessPreview extends MultiPreview {
  const MultiBrightnessPreview({required this.name});

  final String name;

  @override
  List<Preview> get previews => const [
        Preview(brightness: Brightness.light),
        Preview(brightness: Brightness.dark),
      ];

  @override
  List<Preview> transform() {
    final previews = super.transform();
    return previews.map((preview) {
      final builder = preview.toBuilder()
        ..group = 'Brightness'
        ..name = '$name - ${preview.brightness!.name}';
      return builder.toPreview();
    }).toList();
  }
}

@MultiBrightnessPreview(name: 'Primary Card')
Widget cardPreview() => const Card(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Content')));
```
