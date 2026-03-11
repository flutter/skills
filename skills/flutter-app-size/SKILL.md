---
name: "flutter-app-size"
description: "Measure and reduce the size of the Flutter app bundle, APK, or IPA"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 17:48:58 GMT"

---
# Optimizing-Flutter-App-Size

## When to Use
* The user requests an analysis or reduction of the Flutter application's compiled size.
* The compiled APK, App Bundle, or IPA exceeds platform size constraints (e.g., Android Instant Apps).
* The project requires optimization for faster download speeds and a smaller device storage footprint.
* The user wants to compare the size differences between two different builds or commits.

## Instructions

**Interaction Rule:** Evaluate the current project context for target platforms (e.g., Android, iOS, Web) and current build configurations. If the target platform or the specific size constraint is missing, ask the user for clarification before proceeding with implementation.

1. **Establish the Baseline:** Never use debug builds to measure app size. Debug builds include hot-reload overhead and source-level debugging tools. Always compile a release build.
2. **Measure Total App Size:** Use platform-specific tools to get an accurate representation of the end-user download and install size, as app stores filter redundant architectures and assets.
3. **Generate Size Analysis Data:** Compile the application using the `--analyze-size` flag to generate a detailed JSON breakdown of the Dart AOT artifact.
4. **Analyze the Data:** Use Dart DevTools to inspect the generated JSON file, identifying large packages, libraries, or assets.
5. **Implement Reduction Strategies:** Apply build flags, asset compression, and code-level tree-shaking to reduce the final binary size.

### Decision Logic

Use the following decision tree to determine the correct measurement and analysis path:

* **If the goal is to find the exact end-user download size for Android:**
  * Execute `flutter build appbundle`.
  * Instruct the user to upload the `.aab` file to the Google Play Console.
  * Read the size from the **Android vitals -> App size** tab.
* **If the goal is to find the exact end-user download size for iOS:**
  * Execute `flutter build ipa --export-method development`.
  * Open the `.xcarchive` in Xcode.
  * Select **Distribute App** -> **Development** -> **All compatible device variants** (App Thinning) -> **Strip Swift symbols**.
  * Read the projected sizes from the generated `App Thinning Size Report.txt`.
* **If the goal is to analyze the internal breakdown of the app (Dart code, assets, native libraries):**
  * Execute `flutter build <platform> --analyze-size`.
  * Launch DevTools using `dart devtools`.
  * Open the **App Size Tool** and upload the generated `*-code-size-analysis_*.json` file.
* **If the goal is to compare two different builds:**
  * Generate the JSON analysis file for both the old and new builds.
  * Open the **Diff** tab in the DevTools App Size Tool and upload both files.

## Best Practices

* **Use Build Flags:** Always use the `--split-debug-info` and `--obfuscate` flags when building release versions. This dramatically reduces code size and makes reverse engineering difficult.
* **Optimize Assets:** Compress all PNG and JPEG files before bundling them. Remove any unused resources and minimize heavy assets imported from third-party libraries.
* **Leverage Tree-Shaking:** Rely on the Dart AOT compiler's tree-shaking capabilities. Write platform-specific code using `Platform.isX` checks so the compiler can automatically remove unreachable code for the target platform.
* **Avoid Redundant Fonts:** Limit the number of custom fonts and font weights included in the `pubspec.yaml` file.
* **Review Dependencies:** Regularly audit `pubspec.yaml` for large or unnecessary packages. Use the DevTools dominator tree to identify which dependencies are contributing the most to the compiled size.

## Examples

### Gold Standard Build Commands

To generate a release APK with size analysis, obfuscation, and separated debug info:

```bash
# Define the path for debug symbols
DEBUG_INFO_PATH="build/app/outputs/symbols"
mkdir -p $DEBUG_INFO_PATH

# Build the APK with size analysis and size reduction flags
flutter build apk \
  --release \
  --target-platform=android-arm64 \
  --analyze-size \
  --obfuscate \
  --split-debug-info=$DEBUG_INFO_PATH
```

To generate an iOS build for App Thinning analysis:

```bash
# Build the IPA configured for development export
flutter build ipa \
  --release \
  --export-method development \
  --obfuscate \
  --split-debug-info=build/ios/symbols
```

### Tree-Shaking Platform-Specific Code

The Dart compiler automatically removes unreachable code. Use explicit `Platform` checks to ensure unused platform-specific logic is stripped from the final binary.

```dart
import 'dart:io' show Platform;
import 'package:flutter/material.dart';

// Gold Standard: The compiler will tree-shake the Windows-specific 
// code when building for Android or iOS, reducing the app size.
class AdaptiveFeature extends StatelessWidget {
  const AdaptiveFeature({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isWindows) {
      return _buildWindowsSpecificFeature();
    }
    return _buildMobileFeature();
  }

  Widget _buildWindowsSpecificFeature() {
    // Heavy Windows-specific implementation
    return const Text('Windows Feature');
  }

  Widget _buildMobileFeature() {
    // Mobile implementation
    return const Text('Mobile Feature');
  }
}
```
