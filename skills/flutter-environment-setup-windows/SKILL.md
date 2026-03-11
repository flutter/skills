---
name: "flutter-environment-setup-windows"
description: "Set up a Windows environment for Flutter development"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 18:02:46 GMT"

---
# Setting-Up-Flutter-On-Windows

## When to Use
* The agent needs to configure a Windows environment for Flutter application development.
* The user requests building, debugging, or deploying a Flutter app specifically for Windows Desktop or Android devices connected to a Windows host.
* The agent must package a compiled Windows desktop Flutter application into a distributable zip file or generate local certificates for MSIX deployment.

## Decision Logic
Evaluate the target deployment platform to determine the required toolchain:
* **If targeting Windows Desktop:** Install Visual Studio (not VS Code) with the "Desktop development with C++" workload.
* **If targeting Android on Windows:** Install Android Studio, configure Android SDK/Command-line Tools, enable hardware acceleration for emulators, and install OEM USB drivers for physical devices.
* **If targeting Web:** No additional local compilation toolchain is required beyond a modern browser.
* **If distributing a Windows Desktop app locally:** Generate a `.pfx` certificate using OpenSSL and install it to the local Certificate store.
* **If distributing a Windows Desktop app via Zip:** Bundle the generated `.exe`, `.dll` files, `data/` directory, and Visual C++ redistributables.

## Instructions

**Interaction Rule:** Evaluate the current project context to determine the target platforms (Windows, Android, Web) and distribution method. If the target platform or distribution method is missing or ambiguous, ask the user for clarification before proceeding with the environment setup.

**Plan -> Execute Workflow:**

1. **Install and Configure the Flutter SDK**
   * Download the latest stable Flutter SDK.
   * Extract the SDK to a directory requiring no elevated privileges (e.g., `C:/src/flutter`).
   * Add the `flutter/bin` directory to the system's `PATH` environment variable.
   * Run `flutter doctor` to verify the base installation.

2. **Configure Development Tooling**
   * Install Visual Studio with the `Desktop development with C++` workload to enable Windows desktop compilation.
   * Install a primary IDE (VS Code or Android Studio) and equip it with the Flutter and Dart extensions.
   * Restart the IDE after enabling new platform support to ensure device detection.

3. **Configure Target Platforms**
   * **Android:** Enable Developer options and USB debugging on physical devices. For emulators, select a "Hardware" graphics acceleration option.
   * **Windows:** Ensure the Visual Studio C++ toolchain is detected by running `flutter doctor -v`.
   * **Disable Unused Platforms:** Suppress warnings for platforms not in use by running `flutter config --no-enable-<platform>-desktop` (e.g., `flutter config --no-enable-linux-desktop`).

4. **Package and Distribute (Windows Desktop)**
   * Compile the application using `flutter build windows`.
   * Locate the executable and dependencies in `build/windows/runner/<build_mode>/`.
   * For zip distribution, package the `.exe`, all adjacent `.dll` files, the `data/` directory, and the required Visual C++ redistributables.
   * For local MSIX testing, generate and trust a `.pfx` certificate using OpenSSL.

## Best Practices
* Always use forward slashes (`/`) for file paths in documentation and cross-platform scripts to maintain consistency.
* Do not install the Flutter SDK in protected system directories (e.g., `C:/Program Files/`) to avoid permission errors during execution and updates.
* Bundle `msvcp140.dll`, `vcruntime140.dll`, and `vcruntime140_1.dll` directly in the application zip file to ensure end-users without the Visual C++ redistributable can run the application.
* Install generated `.pfx` certificates into the "Trusted Root Certification Authorities" store on the local machine prior to installing a locally signed MSIX package.

## Examples

### Updating the PATH Environment Variable (PowerShell)
```powershell
# Define the absolute path to the Flutter bin directory
$FLUTTER_BIN_PATH = "C:/src/flutter/bin"

# Append Flutter to the user's PATH variable
$USER_PATH = [Environment]::GetEnvironmentVariable("Path", "User")
[Environment]::SetEnvironmentVariable("Path", "$USER_PATH;$FLUTTER_BIN_PATH", "User")
```

### Generating a Local Certificate for Windows App Signing
```bash
# Set OpenSSL path (adjust based on actual installation directory)
export OPENSSL_BIN="C:/Program Files/OpenSSL-Win64/bin"
export PATH="$OPENSSL_BIN:$PATH"

# 1. Generate a private key
openssl genrsa -out my_app_key.key 2048

# 2. Generate a Certificate Signing Request (CSR)
openssl req -new -key my_app_key.key -out my_app_csr.csr

# 3. Generate the signed certificate (CRT)
openssl x509 -in my_app_csr.csr -out my_app_cert.crt -req -signkey my_app_key.key -days 10000

# 4. Generate the .pfx file for Windows installation
openssl pkcs12 -export -out my_app_certificate.pfx -inkey my_app_key.key -in my_app_cert.crt
```

### Structuring a Windows Zip Distribution
When preparing a zip file for a Windows release, structure the archive exactly as follows to ensure all dependencies are resolved at runtime:

```text
Release/
├── my_flutter_app.exe
├── flutter_windows.dll
├── msvcp140.dll
├── vcruntime140.dll
├── vcruntime140_1.dll
└── data/
    ├── app.so
    └── icudtl.dat
```
