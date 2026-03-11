---
name: "flutter-environment-setup-macos"
description: "Set up a macOS environment for Flutter development"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 17:36:08 GMT"

---
# Setting-Up-Flutter-macOS

## When to Use
* The agent needs to configure a macOS environment to run, build, and deploy Flutter applications for macOS desktop devices.
* The system requires validation of the macOS toolchain (Xcode, CocoaPods) for a Flutter project.
* The agent encounters missing dependency errors related to Xcode or CocoaPods during a macOS build process.

## Instructions

**Interaction Rule:** Evaluate the current system context for Flutter SDK installation, Xcode presence, and CocoaPods configuration. If any of these requirements are missing or ambiguous, ask the user for clarification or permission to install before proceeding with implementation.

**Plan:**
1. Verify Flutter SDK installation and update status.
2. Configure Xcode and its command-line tools.
3. Install CocoaPods for native macOS plugin support.
4. Validate the setup using Flutter CLI tools.

**Execute:**
1. Ensure Flutter is installed and added to the system `PATH`.
2. Install the latest version of Xcode from the Mac App Store or Apple Developer portal.
3. Point the Xcode command-line tools to the installed Xcode application path.
4. Accept the Xcode license agreements globally.
5. Install CocoaPods to manage native dependencies.
6. Run environment validation checks to confirm the `macos` target is available.

## Decision Logic

Use the following decision tree to navigate the macOS environment setup:

1. **Check Flutter SDK:**
   * If installed: Proceed to step 2.
   * If missing: Prompt user to install Flutter SDK and add `/bin` to `PATH`.
2. **Check Xcode:**
   * If installed: Proceed to step 3.
   * If missing: Prompt user to install Xcode.
3. **Configure Xcode CLI Tools:**
   * Run path configuration command.
   * Run license acceptance command.
4. **Check CocoaPods:**
   * If installed: Proceed to step 5.
   * If missing: Install via `sudo gem install cocoapods` or Homebrew.
5. **Validate Environment:**
   * Run `flutter doctor -v`.
   * If Xcode/macOS errors exist: Resolve specific errors -> Re-run `flutter doctor -v`.
   * If clean: Run `flutter devices`.
   * If `macos` is listed: Setup complete.

## Best Practices
* Always execute `xcodebuild -runFirstLaunch` when configuring the Xcode command-line tools path to ensure all background initialization completes.
* Use `sudo xcodebuild -license` to accept licenses globally, preventing build interruptions during automated tasks.
* Run `flutter doctor -v` (verbose mode) rather than the standard command to expose underlying toolchain paths and hidden configuration warnings.
* Verify device connectivity explicitly using `flutter devices` before attempting to execute `flutter run -d macos`.
* Maintain CocoaPods at the latest version to ensure compatibility with modern Flutter plugins utilizing Swift Package Manager or updated native APIs.

## Examples

### Gold Standard Toolchain Configuration

Execute the following sequential commands to configure the macOS toolchain deterministically:

```bash
# 1. Configure Xcode command-line tools path and trigger first launch
sudo sh -c 'xcode-select -s /Applications/Xcode.app/Contents/Developer && xcodebuild -runFirstLaunch'

# 2. Accept Xcode licenses globally
sudo xcodebuild -license accept

# 3. Install CocoaPods (assuming Ruby environment is configured)
sudo gem install cocoapods

# 4. Validate the Flutter toolchain setup
flutter doctor -v

# 5. Verify the macOS desktop device is recognized
flutter devices
```
