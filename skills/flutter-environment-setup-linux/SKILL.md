---
name: "flutter-environment-setup-linux"
description: "Set up a Linux environment for Flutter development"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 17:35:43 GMT"

---
# Setting-Up-Flutter-On-Linux

## When to Use
* The agent needs to configure a Linux or ChromeOS environment to build, run, and deploy Flutter desktop applications.
* The system requires installation of Flutter prerequisite packages and C++ toolchains on a Debian-based distribution (e.g., Ubuntu).
* The user needs to resolve "Linux toolchain" errors reported by the `flutter doctor` command.

## Instructions

**Interaction Rule:** Evaluate the current system context for the target OS type (Standard Linux vs. ChromeOS) and the current Flutter installation status. If the OS distribution is unknown or not Debian-based, ask the user for clarification before proceeding with `apt-get` commands.

1. **Plan:** Determine the target environment (ChromeOS requires enabling Linux support first).
2. **Update:** Refresh the local package index and upgrade existing packages to prevent dependency conflicts.
3. **Execute:** Install the required core utilities and the Linux desktop toolchain.
4. **Validate:** Run Flutter diagnostic commands to ensure the environment is correctly configured and devices are recognized.

## Decision Logic

Use the following decision tree to guide the setup process:

* **Is the target device a Chromebook?**
  * **Yes:** Instruct the user to turn on Linux support in ChromeOS settings and ensure it is up to date. Proceed to package installation.
  * **No:** Proceed directly to package installation.
* **Are core utilities (`curl`, `git`, `unzip`) missing?**
  * **Yes:** Include core utilities in the `apt-get install` command.
* **Does `flutter doctor` report Linux toolchain issues?**
  * **Yes:** Ensure `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`, and `libstdc++-12-dev` are explicitly installed.

## Best Practices

* Always chain `apt-get update` and `apt-get upgrade` before installing new packages to ensure system consistency.
* Use the `-y` flag in package manager commands to ensure deterministic, non-interactive execution.
* Install a dedicated editor or IDE with Flutter support (e.g., Visual Studio Code) to maximize development efficiency.
* Run `flutter doctor -v` after any environment change to verify the toolchain status.
* Verify device connectivity by running `flutter devices` to ensure the `linux` platform is detected.

## Examples

### Gold Standard: Complete Ubuntu/Debian Setup Script

Execute the following deterministic script to configure a Debian-based Linux environment for Flutter development.

```bash
#!/bin/bash

# 1. Update and upgrade the package index
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

# 3. Validate the Flutter toolchain installation
flutter doctor -v

# 4. Verify Linux device availability
flutter devices
```
