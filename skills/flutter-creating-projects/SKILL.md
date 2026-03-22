---
name: "flutter-creating-projects"
description: "Creates a new Flutter project using the CLI or an IDE. Use when initializing a new application, package, or plugin and understanding the generated project structure."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Sun, 22 Mar 2026 07:50:00 GMT"

---
# Creating a New Project in Flutter

## Contents
- [Core Concepts](#core-concepts)
- [Architecture and Data Flow](#architecture-and-data-flow)
- [Workflow: Creating a Project with the CLI](#workflow-creating-a-project-with-the-cli)
- [Workflow: Creating a Project with an IDE](#workflow-creating-a-project-with-an-ide)
- [Examples](#examples)

## Core Concepts

Flutter development begins with creating a project structure that contains all necessary code, assets, and platform-specific configurations.

*   **Project Types:** Flutter supports multiple project types depending on your goal:
    *   **Application (`app`):** A standard Flutter app for mobile, web, or desktop.
    *   **Package (`package`):** A reusable Dart library (e.g., a state management utility).
    *   **Plugin (`plugin`):** A package that includes native code for platform-specific integration (e.g., accessing camera APIs).
    *   **Module (`module`):** A Flutter component designed to be embedded into an existing native app (Add-to-App).
*   **Creation Tools:** Projects can be initialized via the **Flutter CLI** (platform-agnostic) or **IDE Wizards** (VS Code, Android Studio, IntelliJ).

## Architecture and Data Flow

When a project is created, Flutter generates a standard directory structure. Understanding this structure is essential for organizing code and resources.

*   **`lib/`**: The heart of the project. Contains Dart source code. `main.dart` is the default entry point.
*   **`pubspec.yaml`**: The project's manifest. Manages dependencies, assets (images, fonts), and versioning.
*   **`test/`**: Contains automated unit, widget, and integration tests.
*   **`android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/`**: Platform-specific "runners" that host the Flutter engine and handle native integration.
*   **`analysis_options.yaml`**: Configures linting rules for the project.

## Workflow: Creating a Project with the CLI

Use the Flutter CLI for precise control over project initialization and platform support.

1.  **Open the Terminal** and navigate to your workspace.
2.  **Run `flutter create`**:
    *   Basic command: `flutter create my_app_name`
    *   Specify platforms: `flutter create --platforms=ios,android,web my_app_name`
    *   Specify project type: `flutter create --template=plugin my_plugin_name`
    *   Specify organization (package name): `flutter create --org com.example my_app`
3.  **Navigate to the directory**: `cd my_app_name`
4.  **Verify the setup**: Run `flutter doctor` to ensure your environment is ready for the selected platforms.

## Workflow: Creating a Project with an IDE

IDEs provide a visual, guided experience for project creation.

### Visual Studio Code
1.  Open the **Command Palette** (`Ctrl+Shift+P` or `Cmd+Shift+P`).
2.  Type `Flutter: New Project` and press Enter.
3.  Select the **Application** template (or another type).
4.  Choose a parent folder for the project.
5.  Enter the project name and press Enter.

### Android Studio / IntelliJ
1.  Select **New Flutter Project** from the Welcome screen or `File > New > New Project`.
2.  Select **Flutter** in the left sidebar.
3.  Ensure the **Flutter SDK path** is correct and click Next.
4.  Enter the Project name, location, and select supported platforms.
5.  Click **Finish**.

## Examples

### Basic Application Creation (CLI)
Initialize a project for mobile and web with a custom organization name.

```bash
flutter create --org com.mycompany --platforms=android,ios,web my_awesome_app
```

### Creating a Dart Package (CLI)
Initialize a reusable library without platform-specific code.

```bash
flutter create --template=package my_utility_library
```

### Project Structure Checklist
After creation, verify the presence of these key files:
- [ ] `lib/main.dart` (entry point)
- [ ] `pubspec.yaml` (dependency management)
- [ ] `analysis_options.yaml` (linting)
- [ ] Platform folders for your targets (e.g., `android/`, `ios/`)
