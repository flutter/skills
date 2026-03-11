---
name: "flutter-performance"
description: "Optimize the performance of your Flutter app"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 17:48:17 GMT"

---
# Optimizing-Flutter-Performance

## When to Use
* The user requests performance improvements, jank reduction, or memory optimization in a Flutter application.
* The application experiences dropped frames, stuttering animations, or slow rendering times.
* Setting up integration tests to measure and record performance timelines.
* Debugging excessive widget rebuilds, expensive layout passes, or high CPU/GPU usage.
* Migrating or refactoring UI components to adhere to Flutter performance best practices.

## Instructions

**Interaction Rule:** Evaluate the current project context for target platforms (mobile vs. web), existing performance metrics, and specific symptoms (e.g., UI thread jank vs. Raster thread jank). If missing, ask the user for clarification on the specific performance bottleneck before proceeding with implementation.

1. **Plan:** 
   * Identify the source of the performance issue by running the app in Profile mode on a physical device.
   * Determine if the bottleneck is on the UI thread (Dart code/build methods) or the Raster thread (GPU/rendering).
2. **Execute:** 
   * Apply targeted optimizations based on the identified bottleneck (see Decision Logic).
   * Refactor large widgets, localize state changes, and eliminate expensive rendering operations.
3. **Measure:** 
   * Write an integration test using `traceAction` to capture a performance timeline.
   * Compare the `TimelineSummary` before and after the optimization to quantify improvements.

## Decision Logic

Use the following decision tree to determine the appropriate optimization strategy:

* **If the UI thread is slow (Red bars in UI graph):**
  * Refactor large widgets into smaller, encapsulated `StatelessWidget` classes.
  * Localize `setState()` calls to the smallest possible subtree.
  * Add `const` constructors to widgets wherever possible.
  * Avoid overriding `operator ==` on `Widget` objects.
* **If the Raster thread is slow (Red bars in GPU graph):**
  * Remove or minimize the use of `Opacity` widgets; use `AnimatedOpacity` or `FadeInImage` instead.
  * Eliminate unnecessary clipping (`Clip.antiAliasWithSaveLayer`).
  * Avoid operations that implicitly trigger `saveLayer()` (e.g., `ShaderMask`, `ColorFilter`, overlapping semi-transparent shapes).
  * Pre-calculate and cache static shapes instead of drawing overlapping transparent layers.
* **If lists or grids are causing jank:**
  * Replace explicit lists (`ListView(children: [...])`) with lazy builders (`ListView.builder`).
  * Avoid intrinsic layout passes by setting fixed sizes for cells or using custom `RenderObject` anchors.
* **If profiling a Web App:**
  * Use Chrome DevTools Performance panel instead of Flutter DevTools.
  * Enable `debugProfileBuildsEnabled` or `debugProfileLayoutsEnabled` in the `main()` method to expose timeline events.

## Best Practices

* **Always profile in Profile Mode:** Never measure performance in Debug mode or on an emulator/simulator. Always use a physical device and run `flutter run --profile`.
* **Use `const` extensively:** Enforce the use of `const` constructors to allow the framework to short-circuit widget rebuilds. Enable `flutter_lints` to catch missing `const` declarations.
* **Prefer Widgets over Functions:** Extract reusable UI components into `StatelessWidget` classes rather than helper methods that return `Widget`. This allows the framework to optimize the widget tree.
* **Optimize String Building:** Use `StringBuffer` when concatenating multiple strings inside a loop instead of the `+` operator to prevent excessive memory allocation.
* **Avoid `Opacity` in Animations:** Do not use the `Opacity` widget in animations. Use `AnimatedOpacity` or apply gradual opacity using the GPU's fragment shader via `FadeInImage`.
* **Manage `AnimatedBuilder` Subtrees:** Do not put static widgets inside the `builder` function of an `AnimatedBuilder`. Build the static subtree once and pass it as the `child` parameter.
* **Handle Overlay and Route State:** Ensure that state modifications resulting from `Navigator.pushNamed` or `OverlayEntry` changes are explicitly wrapped in `setState()` to guarantee proper rebuilds.

## Examples

### Gold Standard: Localizing State and Using Const

```dart
import 'package:flutter/material.dart';

// BAD: Calling setState high in the tree rebuilds everything.
// GOOD: Extract the changing part into its own StatefulWidget.
class CounterWidget extends StatefulWidget {
  const CounterWidget({super.key});

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The Text widget rebuilds only when _counter changes.
        Text('Count: $_counter'),
        const SizedBox(width: 16.0), // Use const for static widgets
        ElevatedButton(
          onPressed: () {
            setState(() {
              _counter++;
            });
          },
          child: const Text('Increment'), // Use const for static widgets
        ),
      ],
    );
  }
}

class MyComplexScreen extends StatelessWidget {
  const MyComplexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Performance Example')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('This static text never rebuilds.'),
            SizedBox(height: 20),
            CounterWidget(), // Only this widget rebuilds on tap
          ],
        ),
      ),
    );
  }
}
```

### Gold Standard: Performance Profiling Integration Test

**integration_test/scrolling_test.dart**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/main.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Scroll performance test', (tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(
      MyApp(items: List<String>.generate(10000, (i) => 'Item $i')),
    );

    final listFinder = find.byType(Scrollable);
    final itemFinder = find.byKey(const ValueKey('item_5000_text'));

    // Record the performance timeline
    await binding.traceAction(() async {
      // Scroll until the specific item is visible
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
    responseDataCallback: (data) async {
      if (data != null) {
        final timeline = driver.Timeline.fromJson(
          data['scrolling_timeline'] as Map<String, dynamic>,
        );

        // Convert the Timeline into a TimelineSummary
        final summary = driver.TimelineSummary.summarize(timeline);

        // Write the entire timeline to disk in a json format.
        // This file can be opened in chrome://tracing.
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
