---
name: "flutter-performance"
description: "Optimize the performance of your Flutter app"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 18:14:14 GMT"

---
# Optimizing-Flutter-Performance

## When to Use
* The agent needs to diagnose, measure, or resolve UI jank, slow animations, or high CPU/GPU usage in a Flutter application.
* The agent is implementing complex UI layouts (e.g., long lists, grids, overlapping transparent widgets) and must ensure 60fps or 120fps rendering.
* The agent is writing integration tests to capture and analyze performance timelines.
* The agent is refactoring legacy Flutter code and needs to address state management around `LayoutBuilder`, `SliverLayoutBuilder`, or `OverlayEntry` widgets.

## Instructions
1. **Plan:**
   * Identify the specific performance metric to optimize (e.g., frame build time, rasterization time, app size, or memory usage).
   * Determine the target platform (Mobile, Web, Desktop) as profiling tools differ (e.g., Flutter DevTools for Mobile/Desktop, Chrome DevTools for Web).
   * Review the widget tree for common performance pitfalls (e.g., missing `const`, high-level `setState` calls, excessive `saveLayer` triggers).
2. **Execute:**
   * Run the application in **Profile mode** (`flutter run --profile`). Never measure performance in Debug mode.
   * Use the DevTools Performance View to capture a timeline. Identify whether the bottleneck is on the **UI thread** (Dart code/build methods) or the **Raster thread** (GPU/rendering).
   * Apply targeted optimizations based on the identified bottleneck (see Best Practices).
   * Verify the optimization by running an automated integration test that records a performance timeline.
3. **Interaction Rule:** Evaluate the current project context for existing performance benchmarks or specific target devices. If the target device specifications or the acceptable frame budget (e.g., 16ms vs 8ms) are missing, ask the user for clarification before proceeding with deep optimizations.

## Decision Logic
Use the following decision tree to diagnose and resolve performance issues:

* **Is the app dropping frames (Jank)?**
  * **No:** Continue standard development.
  * **Yes:** Run the app in `--profile` mode and open DevTools Performance View.
    * **Is the UI Thread graph showing red bars (>16ms)?**
      * *Cause:* Dart code is too expensive.
      * *Action:* Localize `setState()` calls, add `const` constructors, extract large `build()` methods into smaller `StatelessWidget` classes, and avoid overriding `operator ==` on widgets.
    * **Is the Raster (GPU) Thread graph showing red bars (>16ms)?**
      * *Cause:* The scene is too complex to render.
      * *Action:* Remove or minimize `Opacity`, `Clip.antiAliasWithSaveLayer`, `ShaderMask`, and `ColorFilter`. Replace `Opacity` with semitransparent colors or `FadeInImage`. Replace clipping with `borderRadius`.
    * **Are both threads showing red bars?**
      * *Action:* Diagnose and fix the UI thread first.
* **Are lists or grids scrolling poorly?**
  * *Action:* Ensure `ListView.builder` or `GridView.builder` is used for lazy loading. Avoid intrinsic layout passes by setting fixed sizes where possible.

## Best Practices

### Widget Building and State Management
* **Localize `setState`:** Call `setState()` only on the lowest possible node in the widget tree to prevent unnecessary rebuilds of ancestor or sibling widgets.
* **Use `const`:** Apply `const` constructors to widgets wherever possible. This allows Flutter to short-circuit rebuild work. Enable `flutter_lints` to enforce this.
* **Prefer `StatelessWidget` over helper methods:** Extract reusable UI components into separate `StatelessWidget` classes rather than returning them from helper functions within a large `build()` method.
* **Explicit State for Overlays and LayoutBuilders:** Always wrap state modifications in `setState()` when driving `LayoutBuilder`, `SliverLayoutBuilder`, or `OverlayEntry` widgets, as the framework no longer implicitly rebuilds them on constraint or route changes.

### Rendering and Painting
* **Avoid `saveLayer()`:** Minimize the use of widgets that trigger `saveLayer()` (e.g., `ShaderMask`, `ColorFilter`, `Text` with `overflowShader`). Precalculate overlapping semi-transparent shapes if possible.
* **Minimize Opacity:** Do not use the `Opacity` widget for simple shapes or text; draw them with a semitransparent color instead. For animating images, use `FadeInImage` or `AnimatedOpacity`.
* **Minimize Clipping:** Clipping is expensive. Instead of wrapping an image in a `ClipRRect`, use the `borderRadius` property available on `Container` or `BoxDecoration`.

### Data and Memory
* **Use `StringBuffer`:** When building strings dynamically (especially in loops), use `StringBuffer` instead of the `+` operator to prevent excessive memory allocation.
* **Cache Images Wisely:** Use `RepaintBoundary` to cache complex, static widget subtrees, but avoid overusing it, as raster cache entries consume significant GPU memory.

## Examples

### Example 1: Automated Performance Profiling via Integration Test
This example demonstrates how to write an integration test that scrolls through a list, captures the performance timeline, and saves the summary to disk.

**integration_test/scrolling_perf_test.dart**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/main.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Scroll performance test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    final listFinder = find.byType(Scrollable);
    final itemFinder = find.byKey(const ValueKey('target_item_100'));

    // Record the performance timeline during the scroll action
    await binding.traceAction(() async {
      await tester.scrollUntilVisible(
        itemFinder,
        500.0,
        scrollable: listFinder,
      );
    }, reportKey: 'scrolling_timeline');
  });
}
```

**test_driver/perf_driver.dart**
```dart
import 'package:flutter_driver/flutter_driver.dart' as driver;
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() {
  return integrationDriver(
    responseDataCallback: (Map<String, dynamic>? data) async {
      if (data != null) {
        final timeline = driver.Timeline.fromJson(
          data['scrolling_timeline'] as Map<String, dynamic>,
        );

        final summary = driver.TimelineSummary.summarize(timeline);

        // Write the timeline and summary to disk for analysis in chrome://tracing
        await summary.writeTimelineToFile(
          'scrolling_timeline',
          pretty: true,
          includeSummary: true,
        );
      }
    },
  );
}
```
*Run command:* `flutter drive --driver=test_driver/perf_driver.dart --target=integration_test/scrolling_perf_test.dart --profile --no-dds`

### Example 2: Optimizing LayoutBuilder with Explicit State
This example demonstrates the correct way to update a `LayoutBuilder` that depends on an `AnimationController`. Relying on implicit relayouts is an anti-pattern.

**lib/widgets/animated_resizing_box.dart**
```dart
import 'package:flutter/material.dart';

class AnimatedResizingBox extends StatefulWidget {
  const AnimatedResizingBox({Key? key}) : super(key: key);

  @override
  State<AnimatedResizingBox> createState() => _AnimatedResizingBoxState();
}

class _AnimatedResizingBoxState extends State<AnimatedResizingBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    // BEST PRACTICE: Explicitly call setState when the animation value changes
    // to ensure the LayoutBuilder and its children rebuild correctly.
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double boxWidth = 100.0 + (_controller.value * 100.0);
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: boxWidth,
              child: ElevatedButton(
                onPressed: () {
                  // BEST PRACTICE: Localize state changes explicitly
                  setState(() {
                    _counter++;
                  });
                },
                child: const Text('Increment'),
              ),
            ),
            SizedBox(
              width: boxWidth,
              child: Center(
                child: Text('Count: $_counter'),
              ),
            ),
          ],
        );
      },
    );
  }
}
```
