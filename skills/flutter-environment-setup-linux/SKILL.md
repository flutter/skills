---
name: "flutter-environment-setup-linux"
description: "Set up a Linux environment for Flutter development"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 18:01:50 GMT"

---
# Setting-Up-Flutter-Linux

## When to Use
* The agent needs to configure a Linux environment to build, run, or debug Flutter desktop applications.
* The system requires the installation of Flutter SDK prerequisites and C++ toolchains on a Debian-based distribution or ChromeOS.
* The user requests packaging and deploying a Flutter Linux application to the Snap Store.

## Instructions

**Interaction Rule:** Evaluate the current project context and host operating system. Determine if the environment is a standard Linux distribution (e.g., Ubuntu/Debian) or ChromeOS. If the environment type or preferred shell is missing or ambiguous, ask the user for clarification before proceeding with the installation.

**Plan:**
1. Determine the target Linux environment (Debian/Ubuntu vs. ChromeOS).
2. Install system prerequisites and the Linux desktop toolchain.
3. Download and extract the Flutter SDK.
4. Configure the system `PATH`.
5. Validate the installation using Flutter CLI tools.

**Execute:**
1. Update the package manager and install core dependencies (`curl`, `git`, `unzip`, `xz-utils`, `zip`, `libglu1-mesa`).
2. Install the Linux desktop development toolchain (`clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`, `libstdc++-12-dev`).
3. Extract the Flutter SDK tarball to a dedicated directory (e.g., `~/develop/`).
4. Append the Flutter `bin` directory to the user's shell configuration file (`~/.bashrc`, `~/.zshrc`, or `~/.profile`).
5. Run `flutter doctor -v` to resolve any remaining toolchain issues.

## Decision Logic

Follow this decision tree to determine the correct setup path:

* **Is the host OS ChromeOS?**
  * **Yes:** Instruct the user to turn on Linux support in ChromeOS settings. Proceed to install core prerequisites. Desktop toolchain (GTK) may require additional ChromeOS-specific configuration.
  * **No:** Proceed to standard Linux setup.
* **Is the Flutter SDK already installed?**
  * **Yes:** Run `flutter upgrade` to ensure it is up to date.
  * **No:** Download the latest stable Linux release tarball and extract it.
* **Is the goal to publish to the Snap Store?**
  * **Yes:** Install `snapcraft` and `lxd` via snap. Initialize LXD and create a `snap/snapcraft.yaml` configuration file.
  * **No:** Stop after validating the local build environment with `flutter doctor`.

## Best Practices

* Execute package installations non-interactively using the `-y` flag (e.g., `sudo apt-get install -y`).
* Always verify the default shell (`echo $SHELL`) before appending export commands to profile scripts to ensure the `PATH` is updated correctly.
* Use absolute paths when configuring environment variables to prevent resolution errors.
* Run `flutter doctor -v` after any environment change to deterministically validate the integrity of the Linux toolchain.
* When building for release, inspect system library dependencies using `ldd build/linux/x64/release/bundle/<executable_name>` to ensure all required `.so` files are present.

## Examples

### Example 1: Automated Environment Setup Script
Use this script to deterministically install prerequisites, the Linux toolchain, and configure the Flutter SDK.

```bash
#!/bin/bash
# setup_flutter_linux.sh

# 1. Update package lists and upgrade existing packages
sudo apt-get update -y && sudo apt-get upgrade -y

# 2. Install core prerequisites and Linux desktop toolchain
sudo apt-get install -y \
  curl \
  git \
  unzip \
  xz-utils \
  zip \
  libglu1-mesa \
  clang \
  cmake \
  ninja-build \
  pkg-config \
  libgtk-3-dev \
  libstdc++-12-dev

# 3. Create development directory
DEV_DIR="$HOME/develop"
mkdir -p "$DEV_DIR"

# 4. Download and extract Flutter SDK (Replace URL with latest stable release)
FLUTTER_SDK_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.29.3-stable.tar.xz"
curl -L "$FLUTTER_SDK_URL" -o /tmp/flutter.tar.xz
tar -xf /tmp/flutter.tar.xz -C "$DEV_DIR"

# 5. Add Flutter to PATH for Bash (Adapt for Zsh if necessary)
echo "export PATH=\"$DEV_DIR/flutter/bin:\$PATH\"" >> "$HOME/.bashrc"
source "$HOME/.bashrc"

# 6. Validate installation
flutter doctor -v
```

### Example 2: Snapcraft Configuration for Linux Deployment
Implement this `snapcraft.yaml` structure when packaging a Flutter Linux app for the Snap Store. Place it at `<project_root>/snap/snapcraft.yaml`.

```yaml
name: super-cool-app
version: '0.1.0'
summary: Super Cool App
description: Super Cool App that does everything!

confinement: strict
base: core22
grade: stable

slots:
  dbus-super-cool-app:
    interface: dbus
    bus: session
    name: org.bar.super_cool_app

apps:
  super-cool-app:
    command: super_cool_app
    extensions: [gnome]
    plugs:
      - network
    slots:
      - dbus-super-cool-app

parts:
  super-cool-app:
    source: .
    plugin: flutter
    flutter-target: lib/main.dart
```
