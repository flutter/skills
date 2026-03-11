---
name: "flutter-environment-setup-windows"
description: "Set up a Windows environment for Flutter development"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 17:36:39 GMT"

---
# Setting-Up-Flutter-Windows

## Goal
The agent configures a complete Windows development environment for Flutter, handling SDK installation, PATH configuration, Visual Studio toolchain setup, and platform-specific deployment packaging.

## When to Use
* The user requests initializing or configuring a Flutter environment on a Windows operating system.
* The system needs to compile, build, or package a Flutter Windows desktop application.
* The user encounters toolchain errors related to Visual Studio, Android emulators, or missing C++ redistributables on Windows.

## Decision Logic
Evaluate the target deployment platform to determine the required toolchain:
* **If targeting Windows Desktop:** Install Visual Studio (not VS Code) with the "Desktop development with C++" workload.
* **If targeting Android on Windows:** Install Android Studio. For emulators, enable hardware acceleration. For physical devices, enable USB debugging and install OEM USB drivers.
* **If targeting Web:** No additional local toolchain is required beyond a modern browser.
* **If packaging for Windows distribution:** 
  * *Option A (Zip):* Bundle the `.exe`, `.dll` files, `data` directory, and Visual C++ redistributables.
  * *Option B (MSIX):* Generate a `.pfx` certificate using OpenSSL and sign the package.

## Instructions

**Interaction Rule:** Evaluate the current project context for the intended target platforms (Windows Desktop, Android, Web). If the target platform is missing or ambiguous, ask the user for clarification before proceeding with toolchain installation.

1. **Install the SDK:** Download the Flutter SDK and extract it to a user-writable directory (e.g., `C:/src/flutter`). Do not use protected directories like `C:/Program Files/`.
2. **Configure PATH:** Append the absolute path of the Flutter `bin` directory to the Windows `Path` environment variable.
3. **Install Tooling:** Install Visual Studio and select the `Desktop development with C++` workload.
4. **Configure Platforms:** Enable or disable specific target platforms using the `flutter config` command.
5. **Restart Environment:** Restart all active terminal sessions and IDEs to apply PATH changes and detect new devices.
6. **Validate Setup:** Execute `flutter doctor -v` to verify the toolchain and resolve any missing dependencies.

## Best Practices
* Install the Flutter SDK in a directory that does not require elevated Administrator privileges.
* Always bundle `msvcp140.dll`, `vcruntime140.dll`, and `vcruntime140_1.dll` alongside the executable when distributing a standalone Windows `.zip` build.
* Disable unused platforms to suppress unnecessary `flutter doctor` warnings (e.g., `flutter config --no-enable-linux-desktop`).
* Install self-signed `.pfx` certificates in the local machine's "Trusted Root Certification Authorities" store before attempting to install a custom MSIX app.
* Use forward slashes (`/`) for internal path references in scripts to maintain cross-compatibility where possible, or strictly use standard Windows environment variables (`%USERPROFILE%`) in batch contexts.

## Examples

### Updating Windows PATH via PowerShell
Use PowerShell to append the Flutter `bin` directory to the user's PATH variable deterministically.

```powershell
$FLUTTER_BIN = "C:/src/flutter/bin"
$USER_PATH = [Environment]::GetEnvironmentVariable("Path", "User")

if ($USER_PATH -notmatch [regex]::Escape($FLUTTER_BIN)) {
    [Environment]::SetEnvironmentVariable("Path", "$USER_PATH;$FLUTTER_BIN", "User")
    Write-Host "Flutter bin directory added to User PATH."
}
```

### Generating a Self-Signed Certificate with OpenSSL
Execute these commands to generate a `.pfx` certificate for MSIX packaging.

```bash
# 1. Generate a private key
openssl genrsa -out mykeyname.key 2048

# 2. Generate a certificate signing request (CSR)
openssl req -new -key mykeyname.key -out mycsrname.csr

# 3. Generate the signed certificate (CRT)
openssl x509 -in mycsrname.csr -out mycrtname.crt -req -signkey mykeyname.key -days 10000

# 4. Generate the .pfx file
openssl pkcs12 -export -out CERTIFICATE.pfx -inkey mykeyname.key -in mycrtname.crt
```

### Windows Standalone Zip Packaging Structure
When assembling a Windows build for distribution without an installer, structure the release folder exactly as follows before zipping:

```text
Release/
├── flutter_windows.dll
├── msvcp140.dll
├── vcruntime140.dll
├── vcruntime140_1.dll
├── my_app.exe
└── data/
    ├── app.so
    └── icudtl.dat
```
