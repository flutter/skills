---
name: "flutter-environment-setup-macos"
description: "Set up a macOS environment for Flutter development"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 18:02:21 GMT"

---
# Setting-Up-Flutter-macOS

## When to Use
* The agent needs to configure a macOS environment to build, run, and deploy Flutter desktop applications.
* The user requests integration with native macOS code or embedding native macOS views in a Flutter project.
* The system requires validation or troubleshooting of an existing Xcode and Flutter macOS toolchain.

## Instructions

**Interaction Rule:** Evaluate the current system context to confirm the operating system is macOS and check if Flutter is already installed. If the OS is not macOS, or if the user's intent regarding the target platform is ambiguous, ask the user for clarification before proceeding.

1. **Verify Flutter Installation:** Ensure the Flutter SDK is installed and added to the system `PATH`. If missing, instruct the user to install Flutter first.
2. **Configure Xcode Tooling:** Ensure Xcode is installed. Configure the Xcode command-line tools to point to the active Xcode installation.
3. **Accept Licenses:** Programmatically accept the Xcode developer licenses to allow builds to proceed without UI prompts.
4. **Install CocoaPods:** Install CocoaPods to support Flutter plugins that rely on native macOS code (Swift/Objective-C).
5. **Validate Environment:** Run the Flutter diagnostic tool to verify the macOS toolchain is correctly configured and detect available macOS devices.

## Decision Logic

Follow this decision tree when configuring the macOS environment:

* **Is Flutter installed?**
  * **No:** Halt and instruct the user to install the Flutter SDK.
  * **Yes:** Proceed to Xcode verification.
* **Is Xcode installed?**
  * **No:** Instruct the user to download and install Xcode from the Mac App Store or Apple Developer site.
  * **Yes:** Proceed to configure command-line tools.
* **Does `flutter doctor` report Xcode errors?**
  * **Yes:** Re-run the Xcode path selection and license acceptance commands.
  * **No:** Proceed to device verification.
* **Does `flutter devices` list "macos"?**
  * **No:** Verify that macOS desktop support is enabled in Flutter (`flutter config --enable-macos-desktop`).
  * **Yes:** The environment is ready for macOS development.

## Best Practices

* Always execute `flutter doctor -v` after modifying the environment to ensure all toolchain requirements are satisfied.
* Use absolute paths (e.g., `/Applications/Xcode.app`) when setting the Xcode directory to prevent ambiguity.
* Ensure CocoaPods is kept up to date, as outdated versions frequently cause native dependency resolution failures during the macOS build phase.
* Run `xcodebuild -runFirstLaunch` immediately after selecting the Xcode path to install any pending initialization packages.

## Examples

### Configuring the Xcode Toolchain

Execute the following commands in the terminal to configure Xcode for Flutter macOS development:

```bash
# 1. Set the path to the active Xcode developer directory and run first-launch tasks
sudo sh -c 'xcode-select -s /Applications/Xcode.app/Contents/Developer && xcodebuild -runFirstLaunch'

# 2. Review and accept the Xcode license agreements
sudo xcodebuild -license accept

# 3. Install CocoaPods for native plugin dependency management
sudo gem install cocoapods
```

### Validating the macOS Environment

Run these diagnostic commands to ensure the system is ready to compile and run macOS desktop applications:

```bash
# 1. Check the overall health of the Flutter installation and Xcode toolchain
flutter doctor -v

# 2. Verify that the "macos" platform is recognized as an available device
flutter devices
```
