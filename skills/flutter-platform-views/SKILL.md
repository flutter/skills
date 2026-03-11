---
name: "flutter-platform-views"
description: "Add a native view into your Flutter app"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 18:11:26 GMT"

---
# Integrating-Platform-Views-and-Embedding-Flutter

## When to Use
* The agent needs to embed native Android (`View`), iOS (`UIView`), or macOS (`NSView`) components directly into a Flutter application (Platform Views).
* The agent needs to embed a Flutter application into an existing native Android, iOS, or Web application (Add-to-App).
* The agent is tasked with configuring multi-view (Web) or multi-engine (Mobile) Flutter instances.
* The agent must optimize performance or resolve rendering glitches related to native view composition in Flutter.

## Instructions

**Interaction Rule:** Evaluate the current project context to determine the target platforms (Android, iOS, Web, macOS) and the embedding direction (Native-in-Flutter vs. Flutter-in-Native). If the specific platform view rendering mode (e.g., Hybrid Composition vs. Texture Layer for Android) or the host element configuration for Web is missing or ambiguous, ask the user for clarification before proceeding with implementation.

**Plan:**
1. Identify the integration type: Platform View (Native inside Flutter) or Add-to-App (Flutter inside Native/Web).
2. Consult the Decision Logic section to select the appropriate rendering mode or embedding strategy based on the target platform.
3. Define the communication channel (`MethodChannel` or `StandardMessageCodec`) for passing creation parameters between Dart and the native platform.

**Execute:**
1. **For Platform Views:** 
   * Implement the Dart-side widget (`AndroidView`, `UiKitView`, `AppKitView`, or `PlatformViewLink`).
   * Implement the platform-side view and factory (`PlatformView`, `PlatformViewFactory`).
   * Register the view factory with the platform's plugin registry.
2. **For Web Embedding:** 
   * Configure the engine initializer in JavaScript with `multiViewEnabled: true`.
   * Replace `runApp` with `runWidget` in the Dart entrypoint.
   * Manage views using `WidgetsBinding.instance.platformDispatcher.views`.
3. **For Mobile Add-to-App:** 
   * Use `FlutterEngineGroup` to spawn multiple engines efficiently.

## Decision Logic

Use the following logic to determine the correct implementation path:

* **Is the goal to embed Native Views inside Flutter?**
  * **Target = Android (Requires API 23+):**
    * *Does the app require the best Flutter rendering performance and transform support?* -> Use **Texture Layer** (`AndroidView`). Note: Quick scrolling may be janky, and accessibility/text magnifiers may break with `SurfaceView`.
    * *Does the app require the best native Android view fidelity (e.g., Google Maps)?* -> Use **Hybrid Composition** (`PlatformViewLink` + `AndroidViewSurface`). Note: This lowers overall Flutter FPS. Prior to Android 10, this copies graphics memory per frame; on Android 10+, it copies only once.
  * **Target = iOS:** -> Use **Hybrid Composition** (`UiKitView`). Note: `ShaderMask` and `ColorFiltered` are not supported.
  * **Target = macOS:** -> Use **Hybrid Composition** (`AppKitView`). Note: Gesture support is not fully functional in the current release.
* **Is the goal to embed Flutter inside an existing App?**
  * **Target = Web:** -> Use **Embedded Mode (Multi-view)**. Initialize the engine with `multiViewEnabled: true` and use `runWidget` in Dart.
  * **Target = Mobile (Android/iOS):** -> Use **Multi-engine** via `FlutterEngineGroup` to share resources (GPU context, font metrics) and minimize memory footprint (~180kB per additional instance).

## Best Practices

* **Mitigate Animation Jank:** Use a placeholder texture during heavy Dart animations. If an animation is slow while a platform view is rendered, take a screenshot of the native view and render it as a texture until the animation completes.
* **Avoid SurfaceViews on Android:** Handling `SurfaceView` is problematic for Flutter. Avoid it when possible. If you must use `SurfaceView` or `SurfaceTexture` within a Platform View, manually invalidate the view (call `invalidate()` on the View or its parent) whenever its content changes, as they do not invalidate themselves.
* **Respect iOS Composition Limits:** Never wrap a `UiKitView` with `ShaderMask` or `ColorFiltered` widgets. Be aware that `BackdropFilter` has severe limitations when applied over iOS platform views.
* **Use runWidget for Web Multi-view:** Never use `runApp` when `multiViewEnabled` is true on the web. `runApp` assumes an `implicitView` which does not exist in multi-view mode. Always use `runWidget` and explicitly map `FlutterView` objects to widgets using `View` and `ViewCollection`.
* **Manage Web View Constraints:** When adding a Flutter view via JavaScript (`app.addView`), pass explicit `viewConstraints` if the host element's CSS relies on intrinsic sizing.

## Examples

### Example 1: Android Platform View (Texture Layer)

**Dart Side (`lib/native_view.dart`):**
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomNativeView extends StatelessWidget {
  const CustomNativeView({super.key});

  @override
  Widget build(BuildContext context) {
    const String viewType = 'custom_native_view_type';
    final Map<String, dynamic> creationParams = <String, dynamic>{
      'initialText': 'Hello from Dart!',
    };

    return AndroidView(
      viewType: viewType,
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}
```

**Kotlin Side (`android/app/src/main/kotlin/com/example/NativeView.kt`):**
```kotlin
package com.example.app

import android.content.Context
import android.graphics.Color
import android.view.View
import android.widget.TextView
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

internal class NativeView(context: Context, id: Int, creationParams: Map<String?, Any?>?) : PlatformView {
    private val textView: TextView = TextView(context)

    init {
        textView.textSize = 24f
        textView.setBackgroundColor(Color.WHITE)
        val initialText = creationParams?.get("initialText") as? String ?: "Default Text"
        textView.text = "Native View ($id): $initialText"
    }

    override fun getView(): View = textView
    override fun dispose() {}
}

class NativeViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as? Map<String?, Any?>
        return NativeView(context, viewId, creationParams)
    }
}
```

**Kotlin Registration (`android/app/src/main/kotlin/com/example/MainActivity.kt`):**
```kotlin
package com.example.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory("custom_native_view_type", NativeViewFactory())
    }
}
```

### Example 2: Web Multi-View Embedding

**JavaScript Host (`web/index.html`):**
```html
<!DOCTYPE html>
<html>
<head>
  <title>Flutter Multi-View</title>
  <style>
    .flutter-container { width: 400px; height: 400px; border: 1px solid black; }
  </style>
</head>
<body>
  <div id="flutter-target-1" class="flutter-container"></div>
  <div id="flutter-target-2" class="flutter-container"></div>

  <script src="flutter_bootstrap.js" defer></script>
  <script>
    _flutter.loader.load({
      onEntrypointLoaded: async function(engineInitializer) {
        let engine = await engineInitializer.initializeEngine({
          multiViewEnabled: true,
        });
        let app = await engine.runApp();
        
        app.addView({
          hostElement: document.getElementById('flutter-target-1'),
          initialData: { id: 'view_1' }
        });
        
        app.addView({
          hostElement: document.getElementById('flutter-target-2'),
          initialData: { id: 'view_2' }
        });
      }
    });
  </script>
</body>
</html>
```

**Dart Side (`lib/main.dart`):**
```dart
import 'dart:ui' show FlutterView;
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

void main() {
  // Use runWidget instead of runApp for multi-view web embedding
  runWidget(
    MultiViewApp(
      viewBuilder: (BuildContext context) {
        final int viewId = View.of(context).viewId;
        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Rendering in FlutterView ID: $viewId'),
            ),
          ),
        );
      },
    ),
  );
}

class MultiViewApp extends StatefulWidget {
  const MultiViewApp({super.key, required this.viewBuilder});
  final WidgetBuilder viewBuilder;

  @override
  State<MultiViewApp> createState() => _MultiViewAppState();
}

class _MultiViewAppState extends State<MultiViewApp> with WidgetsBindingObserver {
  Map<Object, Widget> _views = <Object, Widget>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateViews();
  }

  @override
  void didChangeMetrics() {
    _updateViews();
  }

  void _updateViews() {
    final Map<Object, Widget> newViews = <Object, Widget>{};
    for (final FlutterView view in WidgetsBinding.instance.platformDispatcher.views) {
      newViews[view.viewId] = _views[view.viewId] ?? _createViewWidget(view);
    }
    setState(() {
      _views = newViews;
    });
  }

  Widget _createViewWidget(FlutterView view) {
    return View(
      view: view,
      child: Builder(builder: widget.viewBuilder),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ViewCollection(views: _views.values.toList(growable: false));
  }
}
```
