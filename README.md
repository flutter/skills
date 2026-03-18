# Agent Skills for Flutter

**NOTE: This repository is currently in development and is not yet ready for use.**

This repository contains agent skills for Flutter.

## Installation

To install the skills into your project, run the following command:

```bash
npx skills add flutter/skills
```

## Updating Skills

To update, run the following command:

```bash
npx skills update flutter/skills
```

## Available Skills

| Skill | Description |
|---|---|
| [flutter-adding-home-screen-widgets](skills/flutter-adding-home-screen-widgets/SKILL.md) | Adds home screen widgets to a Flutter app for Android and iOS. Use when providing glanceable app information or quick actions on the device home screen. |
| [flutter-animating-apps](skills/flutter-animating-apps/SKILL.md) | Implements animated effects, transitions, and motion in a Flutter app. Use when adding visual feedback, shared element transitions, or physics-based animations. |
| [flutter-app-runtime](skills/flutter-app-runtime/SKILL.md) | Interacts with running Dart and Flutter applications via the Dart MCP server to enable hot reload, hot restart, widget inspection, and error fetching. Use when modifying UI widgets, debugging errors, or inspecting running apps. Hot reload or hot restart should also be triggered automatically after every single widget UI change. |
| [flutter-architecting-apps](skills/flutter-architecting-apps/SKILL.md) | Architects a Flutter application using the recommended layered approach (UI, Logic, Data). Use when structuring a new project or refactoring for scalability. |
| [flutter-building-forms](skills/flutter-building-forms/SKILL.md) | Builds Flutter forms with validation and user input handling. Use when creating login screens, data entry forms, or any multi-field user input. |
| [flutter-building-layouts](skills/flutter-building-layouts/SKILL.md) | Builds Flutter layouts using the constraint system and layout widgets. Use when creating or refining the UI structure of a Flutter application. |
| [flutter-building-plugins](skills/flutter-building-plugins/SKILL.md) | Builds Flutter plugins that provide native interop for other apps to use. Use when creating reusable packages that bridge Flutter with platform-specific functionality. |
| [flutter-caching-data](skills/flutter-caching-data/SKILL.md) | Implements caching strategies for Flutter apps to improve performance and offline support. Use when retaining app data locally to reduce network requests or speed up startup. |
| [flutter-embedding-native-views](skills/flutter-embedding-native-views/SKILL.md) | Embeds native Android, iOS, or macOS views into a Flutter app. Use when integrating complex native components like maps or web views. |
| [flutter-handling-concurrency](skills/flutter-handling-concurrency/SKILL.md) | Executes long-running tasks in background isolates to keep the UI responsive. Use when performing heavy computations or parsing large datasets. |
| [flutter-handling-http-and-json](skills/flutter-handling-http-and-json/SKILL.md) | Executes HTTP requests and handles JSON serialization in a Flutter app. Use when integrating with REST APIs or parsing structured data from external sources. |
| [flutter-implementing-navigation-and-routing](skills/flutter-implementing-navigation-and-routing/SKILL.md) | Handles routing, navigation, and deep linking in a Flutter application. Use when moving between screens or setting up URL-based navigation. |
| [flutter-improving-accessibility](skills/flutter-improving-accessibility/SKILL.md) | Configures a Flutter app to support assistive technologies like Screen Readers. Use when ensuring an application is usable for people with disabilities. |
| [flutter-interoperating-with-native-apis](skills/flutter-interoperating-with-native-apis/SKILL.md) | Interoperates with native platform APIs on Android, iOS, and the web. Use when accessing device-specific features not available in Dart or calling existing native code. |
| [flutter-localizing-apps](skills/flutter-localizing-apps/SKILL.md) | Configures a Flutter app to support multiple languages and regions. Use when preparing an application for international markets and diverse user locales. |
| [flutter-managing-state](skills/flutter-managing-state/SKILL.md) | Manages application and ephemeral state in a Flutter app. Use when sharing data between widgets or handling complex UI state transitions. |
| [flutter-reducing-app-size](skills/flutter-reducing-app-size/SKILL.md) | Measures and optimizes the size of Flutter application bundles for deployment. Use when minimizing download size or meeting app store package constraints. |
| [flutter-setting-up-mcp](skills/flutter-setting-up-mcp/SKILL.md) | Sets up the Dart and Flutter MCP server to enable AI assistants to interact with Dart and Flutter tools. Use when configuring an MCP client (like Antigravity, Claude Code, or Cursor) to use the Dart and Flutter MCP server. |
| [flutter-setting-up-on-linux](skills/flutter-setting-up-on-linux/SKILL.md) | Sets up a Linux environment for Flutter development. Use when configuring a Linux machine to run, build, or deploy Flutter applications. |
| [flutter-setting-up-on-macos](skills/flutter-setting-up-on-macos/SKILL.md) | Sets up a macOS environment for Flutter development. Use when configuring a macOS machine to run, build, or deploy Flutter applications for iOS or macOS. |
| [flutter-setting-up-on-windows](skills/flutter-setting-up-on-windows/SKILL.md) | Sets up a Windows environment for Flutter development. Use when configuring a Windows machine to run, build, or deploy Flutter applications for Windows desktop or Android. |
| [flutter-testing-apps](skills/flutter-testing-apps/SKILL.md) | Implements unit, widget, and integration tests for a Flutter app. Use when ensuring code quality and preventing regressions through automated testing. |
| [flutter-theming-apps](skills/flutter-theming-apps/SKILL.md) | Customizes the visual appearance of a Flutter app using the theming system. Use when defining global styles, colors, or typography for an application. |
| [flutter-working-with-databases](skills/flutter-working-with-databases/SKILL.md) | Manages local data persistence using SQLite or other database solutions. Use when a Flutter app needs to store, query, or synchronize large amounts of structured data on the device. |
## Contributing

To contribute skills, see the instructions in [tool/README.md](tool/README.md).

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for more information.

## Code of Conduct

Please see [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for more information.
