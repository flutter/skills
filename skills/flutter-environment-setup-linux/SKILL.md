---
name: "flutter-environment-setup-linux"
description: "Set up a Linux environment for Flutter development"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Thu, 26 Feb 2026 23:45:21 GMT"

---
# flutter-linux-setup

## Goal
Configures a Linux environment (Debian/Ubuntu or ChromeOS) for Flutter desktop application development by installing required system prerequisites, managing OS-specific configurations, and validating the toolchain.

## Decision Logic
*   **If OS is ChromeOS:** Require manual enablement of Linux support before proceeding to package installation.
*   **If OS is Debian/Ubuntu:** Proceed directly to `apt-get` package updates and installations.
*   **If OS is non-Debian (e.g., Fedora, Arch):** Halt and inform the user that this skill specifically targets `apt-get` package managers.

## Instructions

1. **Determine the Host Operating System:**
   **STOP AND ASK THE USER:** "Are you setting up this Flutter environment on a standard Debian/Ubuntu Linux distribution, or on a Chromebook (ChromeOS)?"

2. **Handle ChromeOS Prerequisites (Conditional):**
   If the user indicates they are on a Chromebook:
   Instruct the user to navigate to their ChromeOS Settings, turn on "Linux development environment", and ensure it is fully updated. 
   **STOP AND ASK THE USER:** "Please confirm once Linux support is enabled and updated so we can proceed with the package installation."

3. **Update System Packages:**
   Execute the following command to refresh the package lists and upgrade existing packages:
   ```bash
   sudo apt-get update -y && sudo apt-get upgrade -y
   ```

4. **Install Core Prerequisites:**
   Install the base dependencies required for Flutter to operate and build on Linux:
   ```bash
   sudo apt-get install -y curl git unzip xz-utils zip libglu1-mesa
   ```

5. **Install Linux Desktop Toolchain:**
   Install the specific C/C++ toolchain and GTK libraries required to compile Linux desktop applications:
   ```bash
   sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev libstdc++-12-dev
   ```

6. **IDE Configuration Prompt:**
   **STOP AND ASK THE USER:** "For the best experience, an IDE with Flutter support is recommended. Would you like me to provide the installation commands for Visual Studio Code or Android Studio?"
   *   *If VS Code:* Provide the snap installation command: `sudo snap install --classic code`
   *   *If Android Studio:* Provide the snap installation command: `sudo snap install android-studio --classic`

7. **Validate the Environment:**
   Run the Flutter diagnostic tool to verify the Linux toolchain and device availability:
   ```bash
   flutter doctor -v
   flutter devices
   ```
   *Validate-and-Fix:* Analyze the output of `flutter doctor -v`. 
   *   If the "Linux toolchain" section reports missing dependencies, parse the missing package names, construct a new `sudo apt-get install -y <packages>` command, and execute it.
   *   If `flutter devices` does not list a `linux` platform device, verify that the `libgtk-3-dev` package was successfully installed and re-run the validation.

## Constraints
*   Do not include any external URLs, hyperlinks, or references to external documentation.
*   Assume the user has `sudo` privileges and do not explain basic privilege escalation concepts.
*   Do not explain what individual packages (e.g., `curl`, `cmake`) do; assume the user understands standard Linux development tools.
*   Strictly use `apt-get` for package management to ensure non-interactive compatibility (`-y` flags must be present).
*   All terminal commands must be enclosed in `bash` code blocks.
