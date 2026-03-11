---
name: "flutter-plugins"
description: "Build a Flutter plugin that provides native interop for other Flutter apps to use"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 18:12:59 GMT"

---
# Developing-Flutter-Plugins

## When to Use
* When the agent needs to create a modular, reusable Flutter package or plugin.
* When a project requires access to platform-specific native APIs (Android, iOS, macOS, Windows, Linux) from Dart code.
* When integrating C/C++ native libraries using `dart:ffi`.
* When architecting a federated plugin to split implementations across multiple packages and teams.
* When migrating or updating existing Android plugins to the v2 embedding or declarative Gradle plugin application.
* When configuring Swift Package Manager (SPM) support for iOS/macOS plugins.

## Decision Logic
Before creating a package, determine the correct template and architecture using the following logic:

1. **Does the package require platform-specific native code (e.g., Kotlin, Swift, C++)?**
   * **No:** Create a pure Dart package (`flutter create --template=package`).
   * **Yes, it binds to C/C++ native libraries:** Create an FFI plugin (`flutter create --template=plugin_ffi`).
   * **Yes, it accesses OS-level APIs (e.g., Camera, Bluetooth):** Create a standard plugin (`flutter create --template=plugin`).
2. **Does the standard plugin support multiple platforms?**
   * **Yes:** Use a **Federated Plugin Architecture**. Split the plugin into an app-facing package, a platform interface package, and individual platform implementation packages.
   * **No:** Keep the implementation within a single plugin package.

## Instructions

**Interaction Rule:** Evaluate the current project context to determine the required platforms, programming languages (e.g., Kotlin vs. Java, Swift vs. Objective-C), and plugin type (Standard vs. FFI). If this information is missing or ambiguous, ask the user for clarification before executing the creation commands.

**Plan -> Execute Workflow:**

1. **Create the Package:**
   * Execute the Flutter CLI command to generate the plugin scaffold.
   * Specify supported platforms using `--platforms=android,ios,web,linux,macos,windows`.
   * Specify the organization using `--org <reverse-domain>`.
   * Specify languages if deviating from defaults (Swift/Kotlin) using `-i objc` or `-a java`.
2. **Define the Dart API:**
   * Write the public-facing Dart interface in `lib/<package_name>.dart`.
   * For federated plugins, define the `PlatformInterface` in a separate package.
3. **Implement Platform-Specific Code:**
   * **Android:** Build the example app once, then open `example/android/build.gradle` in Android Studio. Edit the plugin code in `android/src/main/...`.
   * **iOS/macOS:** Build the example app once, then open `example/ios/Runner.xcworkspace` in Xcode. Edit the plugin code in the `Classes` directory.
   * **Windows:** Build the example app once, then open `example/build/windows/<project>.sln` in Visual Studio.
4. **Connect API to Native Code:**
   * Use `MethodChannel` or `EventChannel` for standard plugins.
   * Use `dart:ffi` bindings for FFI plugins.
5. **Write Tests:**
   * Implement Dart unit tests for the public API.
   * Implement integration tests in `example/integration_test/` to verify Dart-to-Native communication.
   * Implement native unit tests (JUnit, XCTest, GoogleTest) for platform-specific logic.

## Best Practices

* **Federated Architecture:** Split multi-platform plugins into `<plugin>`, `<plugin>_platform_interface`, and `<plugin>_<platform>` packages. This isolates dependencies and allows independent platform scaling.
* **Android v2 Embedding:** Implement the `FlutterPlugin` interface. If the plugin requires UI interaction, implement `ActivityAware`. If it runs in the background, implement `ServiceAware`.
* **Android Lifecycle:** Extract plugin registration logic into a private method. Call this private method from both the legacy `registerWith()` and the modern `onAttachedToEngine()` to maintain backward compatibility without duplicating code.
* **Android Gradle:** Use the declarative `plugins {}` block in `build.gradle` files instead of the legacy imperative `apply plugin:` syntax.
* **iOS/macOS Shared Source:** If iOS and macOS share identical native implementations, use the `sharedDarwinSource: true` option in `pubspec.yaml` to utilize a single `darwin/` directory.
* **Swift Package Manager (SPM):** Support SPM alongside CocoaPods by including a `Package.swift` file in the `ios/` or `darwin/` directory.
* **Testing Guardrails:** Do not rely on real platform channels in Dart unit tests. Wrap plugin calls in a Dart interface and mock the interface, or use `TestDefaultBinaryMessenger` to mock the channel responses.
* **FFI Constraints:** Use FFI plugins to bundle native C/C++ code and method channel registration, but do not use FFI plugins if you need to pass messages via `MethodChannel`. Use standard plugins for `MethodChannel` communication.

## Examples

### Creating a Standard Plugin
```bash
# Create a plugin supporting Android, iOS, and Web using Kotlin and Swift
flutter create --org com.example --template=plugin --platforms=android,ios,web my_advanced_plugin
```

### Creating an FFI Plugin
```bash
# Create an FFI plugin for Windows and Linux
flutter create --template=plugin_ffi --platforms=windows,linux my_native_bindings
```

### Android v2 Embedding Implementation (Kotlin)
Demonstrates implementing `FlutterPlugin` and `ActivityAware` while maintaining legacy compatibility.

```kotlin
package com.example.my_advanced_plugin

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

class MyAdvancedPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel : MethodChannel

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    setupChannel(flutterPluginBinding.binaryMessenger)
  }

  // Legacy compatibility
  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val plugin = MyAdvancedPlugin()
      plugin.setupChannel(registrar.messenger())
    }
  }

  private fun setupChannel(messenger: io.flutter.plugin.common.BinaryMessenger) {
    channel = MethodChannel(messenger, "com.example.my_advanced_plugin")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    // Handle Activity attachment (e.g., for permissions)
  }

  override fun onDetachedFromActivityForConfigChanges() {}
  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}
  override fun onDetachedFromActivity() {}
}
```

### Federated Plugin `pubspec.yaml` Setup
Demonstrates how an app-facing package endorses platform-specific implementations.

```yaml
name: my_advanced_plugin
description: App-facing package for my_advanced_plugin.
version: 1.0.0
environment:
  sdk: ^3.0.0
  flutter: ">=3.0.0"

dependencies:
  flutter:
    sdk: flutter
  my_advanced_plugin_platform_interface: ^1.0.0
  my_advanced_plugin_windows: ^1.0.0
  my_advanced_plugin_web: ^1.0.0

flutter:
  plugin:
    platforms:
      android:
        package: com.example.my_advanced_plugin
        pluginClass: MyAdvancedPlugin
      ios:
        pluginClass: MyAdvancedPlugin
      windows:
        default_package: my_advanced_plugin_windows
      web:
        default_package: my_advanced_plugin_web
```
