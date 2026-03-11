---
name: "flutter-platform-views"
description: "Add a native view into your Flutter app"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 17:45:21 GMT"

---
# Integrating-Platform-Views

## When to Use
* The application requires embedding native OS views (e.g., Android `View`, iOS `UIView`, macOS `NSView`, or HTML elements) directly into the Flutter widget tree.
* The project needs to integrate native SDKs that provide UI components (e.g., Google Maps, native WebViews, specialized camera previews).
* The application is a web app requiring multi-view embedding into an existing HTML DOM.

## Instructions

**Interaction Rule:** Evaluate the current project context for target platforms (Android, iOS, macOS, Web) and specific native view requirements. If the target platform, minimum SDK version, or performance constraints (e.g., heavy animation vs. high-fidelity native UI) are missing, ask the user for clarification before proceeding with implementation.

1. **Analyze Platform Requirements:** Determine the target platform and select the appropriate composition strategy using the Decision Logic below.
2. **Implement the Dart Interface:** Create the Dart-side widget using `AndroidView`, `UiKitView`, `AppKitView`, or `ViewCollection` (for Web).
3. **Implement the Native Factory:** Write the platform-side factory and view classes (Kotlin/Java, Swift/Obj-C, or JavaScript).
4. **Register the View:** Register the platform view factory with the Flutter engine on the native side.
5. **Optimize Performance:** Apply performance mitigations, such as placeholder textures, during heavy Dart-side animations.

## Decision Logic

Use the following decision tree to determine the correct Platform View implementation strategy:

* **Is the target platform Android?** (Requires API 23+)
  * *Does the app require the best performance and fidelity for the native Android view (e.g., Google Maps)?* -> Use **Hybrid Composition** (`PlatformViewLink`, `AndroidViewSurface`). Note: This may lower overall Flutter FPS.
  * *Does the app require the best performance for Flutter rendering and transformations?* -> Use **Texture Layer** (`AndroidView`). Note: Quick scrolling may be janky, and `SurfaceView` is problematic.
* **Is the target platform iOS?**
  * -> Use **Hybrid Composition** (`UiKitView`).
* **Is the target platform macOS?**
  * -> Use **Hybrid Composition** (`AppKitView`). *Warning: Gesture support is not fully functional in the current release.*
* **Is the target platform Web?**
  * *Does Flutter control the entire browser viewport?* -> Use **Full Page Mode** (default).
  * *Is Flutter being injected into specific HTML elements of an existing web app?* -> Use **Embedded Mode (Multi-view)**.

## Best Practices

* **Mitigate Animation Jank:** Render a screenshot of the native view as a placeholder texture during heavy Dart animations to prevent performance degradation caused by thread synchronization.
* **Avoid SurfaceViews on Android:** Avoid `SurfaceView` when using Texture Layer composition. It forces the view into a virtual display, breaking accessibility and text magnifiers.
* **Invalidate Android Views Manually:** Call `invalidate()` manually on Android views like `SurfaceView` and `SurfaceTexture` when their content changes, as they do not invalidate themselves automatically.
* **Respect iOS Composition Limits:** Do not wrap iOS Platform Views in `ShaderMask` or `ColorFiltered` widgets, as they are not supported. Use `BackdropFilter` with caution due to known limitations.
* **Use runWidget for Web Multi-view:** Replace `runApp` with `runWidget` in `main.dart` when using Web Embedded Mode. `runApp` assumes an `implicitView` exists, which will throw a null error in multi-view mode.

## Examples

### Gold Standard: Android Texture Layer (Dart Side)
Use this pattern for standard Android platform views prioritizing Flutter rendering performance.

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomAndroidView extends StatelessWidget {
  const CustomAndroidView({super.key});

  @override
  Widget build(BuildContext context) {
    const String viewType = 'com.example.app/custom_native_view';
    final Map<String, dynamic> creationParams = <String, dynamic>{
      'initialData': 'Hello from Dart',
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

### Gold Standard: iOS Native View Factory (Swift)
Use this pattern to register and render a native `UIView` in iOS.

```swift
import Flutter
import UIKit

class CustomNativeViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return CustomNativeView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )
    }

    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
          return FlutterStandardMessageCodec.sharedInstance()
    }
}

class CustomNativeView: NSObject, FlutterPlatformView {
    private var _view: UIView

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        _view = UIView()
        super.init()
        createNativeView(view: _view)
    }

    func view() -> UIView {
        return _view
    }

    func createNativeView(view _view: UIView){
        _view.backgroundColor = UIColor.blue
        let nativeLabel = UILabel()
        nativeLabel.text = "Native iOS View"
        nativeLabel.textColor = UIColor.white
        nativeLabel.textAlignment = .center
        nativeLabel.frame = CGRect(x: 0, y: 0, width: 180, height: 48.0)
        _view.addSubview(nativeLabel)
    }
}
```

### Gold Standard: Web Embedded Mode (Multi-view)
Use this pattern to embed Flutter into an existing HTML DOM.

**JavaScript Initialization (`flutter_bootstrap.js`):**
```javascript
_flutter.loader.load({
  onEntrypointLoaded: async function onEntrypointLoaded(engineInitializer) {
    let engine = await engineInitializer.initializeEngine({
      multiViewEnabled: true, 
    });
    let app = await engine.runApp();
    
    // Add view to a specific DOM element
    app.addView({
      hostElement: document.querySelector('#flutter-host-container'),
    });
  }
});
```

**Dart Implementation (`lib/main.dart`):**
```dart
import 'dart:ui' show FlutterView;
import 'package:flutter/widgets.dart';

void main() {
  // Use runWidget instead of runApp for multi-view web
  runWidget(
    MultiViewApp(
      viewBuilder: (BuildContext context) => const Center(
        child: Text('Embedded Flutter View'),
      ),
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
