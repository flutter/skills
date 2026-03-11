---
name: "flutter-plugins"
description: "Build a Flutter plugin that provides native interop for other Flutter apps to use"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 17:46:47 GMT"

---
# Developing-Flutter-Plugins

## When to Use
* The user needs to create a new Flutter plugin, FFI package, or Dart package.
* The user needs to integrate native platform APIs (Android, iOS, macOS, Windows, Linux) with Dart code.
* The user is migrating an older Android plugin to the v2 embedding (`FlutterPlugin`, `ActivityAware`).
* The user is adding Swift Package Manager (SPM) support to an iOS/macOS plugin.
* The user needs to implement type-safe platform channels using Pigeon.
* The user needs to test a Flutter plugin across Dart and native environments.

## Decision Logic
Evaluate the required native integration to determine the package type:

1. **Does the package require native C/C++ code without method channels?**
   * **Yes:** Use an **FFI Plugin**. It supports bundling native code and method channel registration code, but not method channels themselves. Useful for accessing the Flutter Plugin API, configuring Google Play services, or static linking on iOS/macOS.
2. **Does the package require platform-specific APIs (Java/Kotlin/Swift/Obj-C/C++)?**
   * **Yes:** Use a **Standard Plugin**. It uses platform channels to communicate between Dart and native code.
3. **Does the package require pure Dart logic only?**
   * **Yes:** Use a **Dart Package**.
4. **Does the plugin need to support multiple platforms managed by different teams/experts?**
   * **Yes:** Use a **Federated Plugin** architecture. Split the API into an app-facing interface, a platform interface, and independent platform implementations.

## Instructions

**Interaction Rule:** Evaluate the current project context for target platforms, organization name (`--org`), and preferred native languages (`-i`, `-a`). If missing, ask the user for clarification before proceeding with implementation.

### 1. Create the Package
Execute the appropriate creation command based on the decision logic.

* **Standard Plugin:**
  Run `flutter create --template=plugin --platforms=<platforms> --org <org_name> <plugin_name>`.
  * Specify supported platforms using a comma-separated list (e.g., `--platforms=android,ios,web,linux,macos,windows`). If omitted, the project will not support any platforms.
  * Specify the organization using reverse domain name notation (e.g., `--org com.example`).
  * By default, plugins use Swift (iOS) and Kotlin (Android). Specify Objective-C or Java using the `-i objc` and `-a java` flags respectively.
* **FFI Plugin:**
  Run `flutter create --template=plugin_ffi <plugin_name>`. This creates Dart code in `lib` using `dart:ffi` and native source code in `src` with a `CMakeLists.txt` file.
* **Add Platforms to Existing Plugin:**
  Run `flutter create --template=plugin --platforms=<new_platforms> .` inside the existing project directory.

### 2. Implement the Dart API
Define the public-facing API in Dart, typically located in `lib/<package_name>.dart`. Connect the Dart API with platform-specific implementations using a platform channel or through interfaces defined in a platform interface package.

### 3. Implement Native Platform Code
Build the code at least once before editing native files to ensure dependencies are resolved.

* **Android:**
  1. Run `cd example/android && ./gradlew build`.
  2. Open `example/android/build.gradle` or `example/android/build.gradle.kts` in Android Studio.
  3. Edit the platform code located in `android/src/main/java/<org_path>/<PluginName>.kt` (or `.java`).
* **Windows:**
  1. Run `flutter build windows` in the example directory.
  2. Open `example/build/windows/<plugin_name>_example.sln` in Visual Studio.
  3. Edit code in `<plugin_name>_plugin/Source Files` and `Header Files`.
  4. **Crucial:** You must rebuild the solution in Visual Studio after making changes to plugin code.
* **iOS/macOS:**
  1. Run `flutter build ios --no-codesign --config-only` (or `macos`).
  2. Open `example/ios/Runner.xcworkspace` in Xcode.
  3. Update the `podspec` file to set dependencies and deployment targets.

### 4. Upgrade Android Plugins to v2 Embedding
If migrating or building a new Android plugin:
1. Implement the `FlutterPlugin` interface.
2. Move logic from the legacy `registerWith()` method into a private method that both `registerWith()` and `onAttachedToEngine()` can call (only one will be called at runtime).
3. If the plugin needs an `Activity` reference, implement the `ActivityAware` interface.
4. If the plugin is expected to be held in a background `Service`, implement `ServiceAware`.
5. Update the example app's `MainActivity.java` to use the v2 embedding `io.flutter.embedding.android.FlutterActivity`.
6. Ensure the plugin class has a public constructor.

## Best Practices

* **Threading:** Invoke platform channel methods on the platform's main thread (UI thread). If executing heavy workloads, use the Task Queue API to execute channel handlers on a background thread.
* **Type Safety:** Use the `pigeon` package to generate type-safe platform channels instead of relying on raw `MethodChannel` strings and dynamic maps.
* **Documentation:** Document all non-overridden public members in your plugin classes.
* **Dependency Management:** Use declarative `plugins {}` blocks in Android Gradle files rather than the legacy imperative `apply plugin:` syntax.
* **Testing:** 
  * Write Dart unit tests for pure Dart logic.
  * Write native unit tests (JUnit for Android, XCTest for iOS/macOS, GoogleTest for Windows/Linux) to test native code in isolation.
  * Write integration tests in `example/integration_test/` to test the communication between Dart and native code.
* **Federated Endorsement:** When adding new platform implementations to endorsed federated plugins on pub.dev, coordinate with the original plugin author to add your package as a `default_package` in their `pubspec.yaml`.

## Examples

### Gold Standard: Android v2 Embedding Plugin (Kotlin)
Demonstrates implementing `FlutterPlugin`, `ActivityAware`, and sharing initialization logic.

```kotlin
package com.example.battery_plugin

import android.app.Activity
import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class BatteryPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var activity: Activity? = null

    // Public constructor required for v2 embedding
    constructor()

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        setupChannel(flutterPluginBinding.binaryMessenger, flutterPluginBinding.applicationContext)
    }

    // Legacy v1 embedding support
    companion object {
        @JvmStatic
        fun registerWith(registrar: io.flutter.plugin.common.PluginRegistry.Registrar) {
            val plugin = BatteryPlugin()
            plugin.setupChannel(registrar.messenger(), registrar.context())
            plugin.activity = registrar.activity()
        }
    }

    // Shared initialization logic
    private fun setupChannel(messenger: io.flutter.plugin.common.BinaryMessenger, context: Context) {
        this.context = context
        channel = MethodChannel(messenger, "com.example.battery_plugin/battery")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method == "getBatteryLevel") {
            val batteryLevel = getBatteryLevel()
            if (batteryLevel != -1) {
                result.success(batteryLevel)
            } else {
                result.error("UNAVAILABLE", "Battery level not available.", null)
            }
        } else {
            result.notImplemented()
        }
    }

    private fun getBatteryLevel(): Int {
        // Native battery logic here
        return 100
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
    }

    // ActivityAware Implementation
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
```

### Gold Standard: Type-Safe Channels with Pigeon
Define the interface in Dart, then generate the native code.

```dart
// pigeons/battery_api.dart
import 'package:pigeon/pigeon.dart';

class BatteryInfo {
  final int level;
  final String status;

  BatteryInfo({required this.level, required this.status});
}

@HostApi()
abstract class BatteryApi {
  @async
  BatteryInfo getBatteryInfo();
}
```

Generate the code using the CLI:
```bash
flutter pub run pigeon \
  --input pigeons/battery_api.dart \
  --dart_out lib/src/battery_api.g.dart \
  --experimental_kotlin_out android/src/main/kotlin/com/example/battery_plugin/BatteryApi.g.kt \
  --experimental_kotlin_package "com.example.battery_plugin" \
  --experimental_swift_out ios/Classes/BatteryApi.g.swift
```
