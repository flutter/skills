---
name: "flutter-native-interop"
description: "Interoperate with native APIs in a Flutter app on Android, iOS, and the web"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 18:12:23 GMT"

---
# Integrating-Native-Code-In-Flutter

## When to Use
* The agent needs to bind Flutter applications to native C, C++, Objective-C, or Swift code.
* The agent must invoke platform-specific OS APIs (e.g., Android SDK via Kotlin/Java, iOS SDK via Swift/Objective-C).
* The agent is tasked with embedding native UI components (Platform Views) into a Flutter widget tree.
* The agent is configuring a Flutter Web app for WebAssembly (Wasm) compilation or requires JavaScript interoperability.
* The agent needs to add a Flutter module to an existing native application (Add-to-app).

## Decision Logic
Evaluate the integration requirement to determine the correct technical approach:

1. **Is the target code C/C++?**
   * **Yes:** Use `dart:ffi`.
     * *Sub-decision:* Do you need access to the Flutter Plugin API or static linking?
       * **Yes:** Use the legacy `plugin_ffi` template.
       * **No:** Use the `package_ffi` template with `build.dart` hooks (Recommended since Flutter 3.38).
2. **Is the target code platform-specific OS APIs (Kotlin/Java/Swift/Obj-C)?**
   * **Yes:** Use Platform Channels.
     * *Sub-decision:* Is type safety and structured data required?
       * **Yes:** Use the `pigeon` package to generate type-safe interfaces (Recommended).
       * **No:** Use raw `MethodChannel` / `FlutterMethodChannel`.
3. **Is the target a native UI View (e.g., native Map or Video Player)?**
   * **Yes:** Use Platform Views (`AndroidView` for Android, `UiKitView` for iOS, `HtmlElementView` for Web).
4. **Is the target Web-specific?**
   * **Yes:** Use `package:web` and `dart:js_interop` for Wasm-compatible JS interop. Do not use `dart:html` or `package:js`.

## Instructions

**Interaction Rule:** Evaluate the current project context to determine the target platforms (Android, iOS, Web, macOS, Windows, Linux) and the specific native APIs required. If the target platform or the native dependency is missing or ambiguous, ask the user for clarification before proceeding with implementation.

1. **Plan the Integration:**
   * Identify the native language and framework required.
   * Select the appropriate integration method based on the Decision Logic above.
   * Determine if the integration should be an app-level implementation or extracted into a standalone plugin package.
2. **Execute FFI Integration (C/C++):**
   * Generate the package using `flutter create --template=package_ffi <name>`.
   * Place C/C++ source code in the `src/` directory.
   * Configure the `hook/build.dart` script to compile the native code into a dynamic library.
   * Use `package:ffigen` to generate Dart bindings from the C headers.
3. **Execute Platform Channel Integration (OS APIs):**
   * Define the messaging protocol using `pigeon` in a Dart file.
   * Generate the host (native) and client (Dart) code.
   * Implement the generated native interfaces in the respective `MainActivity.kt` (Android) or `AppDelegate.swift` (iOS).
4. **Execute Web Integration:**
   * Replace legacy `dart:html` imports with `package:web`.
   * Define JS interop interfaces using `@JS()` from `dart:js_interop`.
   * Ensure the web server sends `Cross-Origin-Embedder-Policy: credentialless` and `Cross-Origin-Opener-Policy: same-origin` headers to support Wasm multi-threading.

## Best Practices

* **Prefer `package_ffi` over `plugin_ffi`:** Use the `package_ffi` template with build hooks for C interop unless you explicitly need the Flutter Plugin API or Google Play services runtime configuration.
* **Use Pigeon for Platform Channels:** Always prefer `pigeon` over raw `MethodChannel` to guarantee type safety and prevent runtime crashes due to string-matching typos.
* **Handle Threading Correctly:** Always invoke channel methods destined for Flutter on the platform's main UI thread. Execute heavy native handlers on background threads, then jump back to the main thread before sending the result back to Flutter.
* **Ensure Wasm Compatibility:** Never use `dart:html`, `dart:js`, or `package:js` in modern Flutter web apps. Use `package:web` and `dart:js_interop` exclusively to ensure the app compiles to WebAssembly.
* **Acknowledge Wasm iOS Limitations:** Remember that Flutter compiled to Wasm currently cannot run on the iOS version of any browser due to Apple's WebKit engine limitations. Provide JavaScript fallback compilation.
* **Export C++ Symbols:** When binding to native macOS or iOS code, remember that FFI only binds against C symbols. Mark C++ symbols with `extern "C" __attribute__((visibility("default"))) __attribute__((used))` to prevent linker discarding.

## Examples

### Example 1: FFI Integration using `package_ffi` and `build.dart`
Use this pattern to compile C code without OS-specific build files (CMake, build.gradle, podspec).

```dart
// hook/build.dart
import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:native_assets_cli/native_assets_cli.dart';

void main(List<String> args) async {
  await build(args, (config, output) async {
    final builder = CBuilder.library(
      name: 'native_math',
      assetId: 'native_math/native_math.dart',
      sources: [
        'src/native_math.c',
      ],
    );
    await builder.run(
      buildConfig: config,
      buildOutput: output,
      logger: getLogger(),
    );
  });
}
```

### Example 2: Type-Safe Platform Channels using Pigeon
Use this pattern to define a strict contract between Dart and Native code.

```dart
// pigeons/messages.dart
import 'package:pigeon/pigeon.dart';

class BatteryState {
  final int level;
  final String status;

  BatteryState({required this.level, required this.status});
}

@HostApi()
abstract class BatteryApi {
  @async
  BatteryState getBatteryState();
}
```

### Example 3: Wasm-Compatible Web JS Interop
Use this pattern to interact with browser APIs safely in a Wasm-compiled Flutter Web app.

```dart
// lib/web_interop.dart
import 'dart:js_interop';
import 'package:web/web.dart' as web;

@JS('window.alert')
external void _showAlert(JSString message);

void showBrowserAlert(String message) {
  // Convert Dart String to JSString for Wasm compatibility
  _showAlert(message.toJS);
}

void logCurrentUrl() {
  // Use package:web instead of dart:html
  final web.Window window = web.window;
  print('Current URL: ${window.location.href}');
}
```
