---
name: "flutter-app-runtime"
description: "Interacts with running Dart and Flutter applications via the Dart MCP server to enable hot reload, hot restart, widget inspection, and error fetching. Use when modifying UI widgets, debugging errors, or inspecting running apps. Hot reload or hot restart should also be triggered automatically after every single widget UI change."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 18 Mar 2026 21:51:38 GMT"

---
# Interacting with Dart and Flutter Applications via MCP

## Contents
- [Prerequisites](#prerequisites)
- [Core Capabilities](#core-capabilities)
- [Workflow: Target Identification and Connection](#workflow-target-identification-and-connection)
- [Workflow: Automated Operations and Debugging](#workflow-automated-operations-and-debugging)
- [Workflow: Adding New Functionality](#workflow-adding-new-functionality)
- [Examples](#examples)

## Prerequisites
Ensure the Dart and Flutter MCP server is configured and active. If it is inactive or missing, immediately refer to the `flutter-setting-up-mcp` skill for setup instructions before proceeding.

## Core Capabilities
Leverage the Dart MCP server to manage the underlying connection to the application's VM service. This enables zero-configuration interaction with running applications.
- **Hot Reload:** Execute for fast feedback loops on UI updates and simple logic changes.
- **Hot Restart:** Execute to reset the app state for deep non-widget changes or clean resets.
- **Widget Inspection:** Query tree structures and identify UI hierarchy names.
- **Error Fetching:** Retrieve live runtime exceptions and trace pointers live.
- **Package Management:** Search pub.dev and manage dependencies directly.

## Workflow: Target Identification and Connection
Follow this sequence to establish and verify connections to running instances before attempting any runtime operations.

**Task Progress:**
- [ ] List all active application instances in the current workspace using the Dart MCP server.
- [ ] Connect to all relevant apps to maintain synchronized updates across platforms.
- [ ] Verify the required `appUri` or device identifier is active and matches the project's workspace.
- [ ] Re-sync the connection if the identifier mismatches or drops.

## Workflow: Automated Operations and Debugging
Apply conditional logic based on the type of modification or error encountered to maintain application stability.

**Task Progress:**
- [ ] **If diagnosing an issue:** Query live logs using `get_runtime_errors` first to establish context.
- [ ] **If modifying UI/Visuals:** Trigger `hot_reload` across all targeted instances for visual consistency.
- [ ] **If modifying foundational logic or deep state:** Trigger `hot_restart` to reset state across all devices.
- [ ] Run validator -> review errors -> fix any newly introduced runtime exceptions.

## Workflow: Adding New Functionality
Execute this workflow when tasked with adding new features (e.g., charts, maps) that require external packages.

**Task Progress:**
- [ ] Execute `pub_dev_search` to find highly-rated and suitable packages for the requirement.
- [ ] Add the selected package as a dependency to `pubspec.yaml`.
- [ ] Generate the required widget code and integrate it into the UI.
- [ ] Trigger `hot_reload`.
- [ ] Run validator -> review errors -> fix any syntax or integration issues.

## Examples

### Scenario: Fixing a RenderFlex Overflow
**Trigger:** The application encounters a runtime layout error (e.g., yellow-and-black stripes).
**Action Sequence:**
1. Execute `get_runtime_errors` to fetch the live exception details.
2. Inspect the Flutter widget tree using Widget Inspection tools to understand the layout constraints causing the overflow.
3. Apply the layout fix (e.g., wrapping a widget in `Expanded` or `Flexible`).
4. Trigger `hot_reload`.
5. Execute `get_runtime_errors` again to verify the issue is resolved.

### Scenario: Multi-Device Synchronization
**Trigger:** Applying a global change, such as modifying the application theme.
**Action Sequence:**
1. Identify all active `appUri` targets (e.g., iOS simulator, Android emulator, Web instance).
2. Apply the theme modification in the Dart code.
3. Trigger `hot_reload` across *all* connected instances simultaneously to ensure visual consistency across platforms.
