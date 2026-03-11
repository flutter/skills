---
name: "flutter-app-size"
description: "Measure and reduce the size of the Flutter app bundle, APK, or IPA"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 18:14:57 GMT"

---
# Optimizing-App-Size

## When to Use
* The agent needs to measure the production size of a compiled Flutter application (APK, App Bundle, IPA, or desktop binaries).
* The user requests an analysis of the app's code size breakdown, including Dart AOT artifacts, native libraries, and assets.
* The agent is tasked with reducing the overall download or install size of the application.
* The user wants to compare the size differences between two different application builds.

## Instructions

**Interaction Rule:** Evaluate the current project context to determine the target platform (Android, iOS, desktop) and the specific size reduction goals. If the target platform or build flavor is missing, ask the user for clarification before proceeding with implementation.

**Plan:**
1. Identify the target platform for the size analysis.
2. Select the appropriate build command and flags to generate size analysis artifacts.
3. Determine if a deep-dive analysis (via DevTools) or an App Store estimate (via Xcode) is required.
4. Formulate a strategy to reduce the app size based on the analysis.

**Execute:**
1. Run the targeted `flutter build` command with the `--analyze-size` flag.
2. Locate the generated `*-code-size-analysis_*.json` file.
3. Launch DevTools to inspect the JSON file, utilizing the treemap or dominator tree to identify large dependencies or assets.
4. Apply size reduction techniques (e.g., obfuscation, asset compression) and rebuild to verify the size reduction.

## Decision Logic

Use the following decision tree to determine the correct measurement and analysis path:

* **Is the target platform Android?**
  * Yes: Run `flutter build apk --analyze-size` or `flutter build appbundle --analyze-size`.
* **Is the target platform iOS?**
  * *Goal: Quick relative size analysis of Dart code and assets?*
    * Run `flutter build ios --analyze-size`.
  * *Goal: Accurate estimate of end-user download/install size?*
    * Run `flutter build ipa --export-method development`.
    * Open the archive in Xcode.
    * Select "Distribute App" -> "Development".
    * Enable "All compatible device variants" in App Thinning.
    * Enable "Strip Swift symbols".
    * Export and review the `App Thinning Size Report.txt`.
* **Is the goal to analyze the breakdown of the app size?**
  * Run `dart devtools`.
  * Open the "App Size Tool".
  * Upload the generated `*-code-size-analysis_*.json` file.
* **Is the goal to compare two different builds?**
  * Generate size analysis JSON files for both the old and new builds.
  * Open DevTools -> App Size Tool -> "Diff" tab.
  * Upload both JSON files to visualize the delta.

## Best Practices

* **Never use debug builds for size measurement.** Always compile in release mode, as debug builds contain overhead for hot reload and source-level debugging that drastically inflates the app size.
* **Strip debug symbols.** Implement the `--split-debug-info` and `--obfuscate` flags during the release build process to extract debug symbols from the compiled binary, significantly reducing code size.
* **Optimize assets.** Compress all PNG and JPEG files before bundling them. Remove unused resources and minimize heavy resource imports from third-party libraries.
* **Leverage tree-shaking.** Rely on the Dart AOT compiler's tree-shaking capabilities in profile or release modes. Avoid dynamic invocations or excessive reflection-like patterns that prevent the compiler from identifying and removing dead code.
* **Use platform-specific code checks.** Wrap platform-specific imports and logic in `if (Platform.isWindows)` (or similar) blocks. The Dart compiler will remove unreachable code for the target platform during the release build.

## Examples

### Example 1: Generating Size Analysis for Android
Execute the following command to build an Android App Bundle and generate the size analysis JSON file.

```bash
# Build the release app bundle and generate the size analysis file
flutter build appbundle --target-platform android-arm,android-arm64,android-x64 --analyze-size

# The output will print a high-level summary to the terminal and generate a file at:
# build/app/outputs/bundle/release/app-release-code-size-analysis_01.json
```

### Example 2: Applying Size Reduction Strategies
Implement obfuscation and debug-info splitting to reduce the final binary size. Define a path to store the extracted debug symbols.

```bash
# Define the output directory for debug symbols
DEBUG_INFO_PATH="build/debug_info"

# Create the directory if it does not exist
mkdir -p $DEBUG_INFO_PATH

# Build the APK with size reduction flags
flutter build apk --release --obfuscate --split-debug-info=$DEBUG_INFO_PATH --analyze-size
```

### Example 3: Launching DevTools for Deep Analysis
Once the JSON analysis file is generated, launch DevTools to inspect the dominator tree and call graph.

```bash
# Launch Dart DevTools
dart devtools

# 1. Open the provided localhost URL in a browser.
# 2. Navigate to the "App Size" tab.
# 3. Drag and drop the generated `*-code-size-analysis_*.json` file into the UI.
# 4. Use the Treemap to identify large assets and the Dominator Tree to find the root cause of large package inclusions.
```
