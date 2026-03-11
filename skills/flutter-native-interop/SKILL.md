---
name: "flutter-native-interop"
description: "Interoperate with native APIs in a Flutter app on Android, iOS, and the web"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 17:46:06 GMT"

---
# Integrating-Flutter-Platforms

## When to Use
* The agent needs to call native C/C++, Kotlin, Java, Swift, or Objective-C code from Dart.
* The agent needs to embed native Android/iOS views or HTML elements into a Flutter widget tree.
* The agent is configuring WebAssembly (Wasm) or JS interop for Flutter Web.
* The agent is adding Flutter to an existing native application (add-to-app) using multi-engine or multi-view capabilities.

## Instructions

**Interaction Rule:** Evaluate the current project context for target platforms (Android, iOS, Web, macOS, Windows, Linux), required native APIs, and existing plugin availability. If the required native API details, target platforms, or architectural constraints are missing, ask the user for clarification before proceeding with implementation.

1. **Plan:** 
   * Identify the target platforms and the specific native functionality required.
   * Consult the "Decision Logic" section to select the appropriate integration mechanism (FFI, Platform Channels, Platform Views, or Web Interop).
   * Determine if the integration should be a standalone package/plugin or embedded within the app codebase.
2. **Execute:**
   * Generate the necessary boilerplate using `flutter create --template=package_ffi` or `plugin`.
   * Implement the Dart interface (using `dart:ffi`, `MethodChannel`, or `Pigeon`).
   * Implement the native host code (C/C++, Kotlin, Swift, JS).
   * Wire up the build hooks or platform-specific build files (e.g., `hook/build.dart`, `build.gradle`, `Podspec`).

## Decision Logic

Use the following logic tree to determine the correct integration strategy:

* **Requirement: Call C/C++ Code**
  * *Condition:* Need access to the Flutter Plugin API, Google Play services runtime, or static linking?
    * **Action:** Use the legacy `plugin_ffi` template.
  * *Condition:* Standard C/C++ interop?
    * **Action:** Use the `package_ffi` template with build hooks (Recommended since Flutter 3.38).
* **Requirement: Call Platform-Specific APIs (Kotlin, Java, Swift, Obj-C)**
  * *Condition:* Complex data structures or strict type-safety required?
    * **Action:** Use the `Pigeon` package to generate type-safe interfaces.
  * *Condition:* Simple, infrequent message passing?
    * **Action:** Use `MethodChannel` / `FlutterMethodChannel`.
* **Requirement: Display Native UI Components**
  * *Condition:* Android target?
    * **Action:** Use `AndroidView` (Texture Layer Hybrid Composition) for best Flutter rendering performance, or `PlatformViewLink` (Hybrid Composition) for best native view fidelity.
  * *Condition:* iOS target?
    * **Action:** Use `UiKitView`.
  * *Condition:* Web target?
    * **Action:** Use `HtmlElementView.fromTagName` or `HtmlElementView` with `registerViewFactory`.
* **Requirement: Web Integration**
  * *Condition:* Need JS Interop and Wasm support?
    * **Action:** Use `package:web` and `dart:js_interop`. Do NOT use `dart:html` or `package:js`.
  * *Condition:* Targeting iOS browsers?
    * **Action:** Fall back to JS compilation. WasmGC is not supported on iOS browsers due to WebKit limitations.

## Best Practices

* **FFI & Native Code:**
  * Mark C++ symbols with `extern "C" __attribute__((visibility("default"))) __attribute__((used))` to prevent the linker from discarding symbols during link-time optimization.
  * Resolve dynamically linked libraries using `DynamicLibrary.process` when they are automatically loaded at app startup.
  * Use `hook/build.dart` for compiling native code in `package_ffi` to avoid writing OS-specific build files (CMake, build.gradle, Podspec).
* **Platform Channels:**
  * Always invoke channel methods on the platform's main thread (UI thread). 
  * If executing channel handlers on a background thread, use the Task Queue API (`makeBackgroundTaskQueue()`).
  * Handle `PlatformException` gracefully in Dart to prevent app crashes when native calls fail.
* **Web & Wasm:**
  * Migrate all web-specific code to `package:web` and `dart:js_interop` to ensure compatibility with WebAssembly compilation.
  * Ensure the web server sends `Cross-Origin-Embedder-Policy: credentialless` and `Cross-Origin-Opener-Policy: same-origin` headers to enable multi-threading in Wasm.
* **Add-to-App:**
  * Use multi-engine on Android and iOS to allow multiple isolated Flutter instances.
  * Use multi-view on the web to allow multiple `FlutterViews` to share objects within a single Dart program.

## Examples

### Gold Standard: FFI with Build Hooks (`package_ffi`)

**hook/build.dart**
```dart
import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:logging/logging.dart';

void main(List<String> args) async {
  final buildConfig = await BuildConfig.fromArgs(args);
  final buildOutput = BuildOutput();
  
  final cbuilder = CBuilder.library(
    name: 'native_add',
    assetId: 'package:native_add/native_add.dart',
    sources: ['src/native_add.c'],
  );
  
  await cbuilder.run(
    buildConfig: buildConfig,
    buildOutput: buildOutput,
    logger: Logger('')..onRecord.listen((record) => print(record.message)),
  );
  
  await buildOutput.writeToFile(outDir: buildConfig.outDir);
}
```

**lib/native_add.dart**
```dart
import 'dart:ffi';

@Native<Int32 Function(Int32, Int32)>()
external int sum(int a, int b);
```

### Gold Standard: Type-Safe Platform Channels with Pigeon

**pigeons/messages.dart**
```dart
import 'package:pigeon/pigeon.dart';

class BatteryInfo {
  final int level;
  final String status;

  BatteryInfo({required this.level, required this.status});
}

@HostApi()
abstract class BatteryApi {
  BatteryInfo getBatteryInfo();
}
```

**android/app/src/main/kotlin/com/example/app/MainActivity.kt**
```kotlin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        BatteryApi.setup(flutterEngine.dartExecutor.binaryMessenger, BatteryApiImpl(context))
    }
}

class BatteryApiImpl(private val context: Context) : BatteryApi {
    override fun getBatteryInfo(): BatteryInfo {
        // Implement native battery logic here
        return BatteryInfo(100, "Charging")
    }
}
```

### Gold Standard: Web JS Interop (Wasm Compatible)

**lib/web_interop.dart**
```dart
import 'dart:js_interop';
import 'package:web/web.dart' as web;

@JS('window.alert')
external void showAlert(JSString message);

void triggerAlert(String message) {
  // Use .toJS to convert Dart strings to JSStrings
  showAlert(message.toJS);
}

void logUrl() {
  // Use package:web for DOM interactions
  final web.Window window = web.window;
  print(window.location.href);
}
```
