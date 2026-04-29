# Agent Skills for Flutter

**NOTE: This repository is currently in development and is not yet ready for use.**

This repository contains agent skills for Flutter.

## Installation

To install all skills into your project, run the following command. 
The `--agent universal` flag puts it in the standard `.agents/skills` 
folder that most agents use.

```bash
npx skills add flutter/skills --skill '*' --agent universal
```

## Updating Skills

To update, run the following command:

```bash
npx skills update
```

## Available Skills

| Skill | Description |
|---|---|
| [flutter-accessibility-audit](skills/flutter-accessibility-audit/SKILL.md) | Triggers an accessibility scan through the widget_inspector and automatically adds Semantics widgets or missing labels to the source code. |
| [flutter-add-integration-test](skills/flutter-add-integration-test/SKILL.md) | Configures Flutter Driver for app interaction and converts MCP actions into permanent integration tests. Use when adding integration testing to a project, exploring UI components via MCP, or automating user flows with the integration_test package. |
| [flutter-add-widget-preview](skills/flutter-add-widget-preview/SKILL.md) | Adds interactive widget previews to the project using the previews.dart system. Use when creating new UI components or updating existing screens to ensure consistent design and interactive testing. |
| [flutter-add-widget-test](skills/flutter-add-widget-test/SKILL.md) | Implement a component-level test using `WidgetTester` to verify UI rendering and user interactions (tapping, scrolling, entering text). Use when validating that a specific widget displays correct data and responds to events as expected. |
| [flutter-apply-architecture-best-practices](skills/flutter-apply-architecture-best-practices/SKILL.md) | Architects a Flutter application using the recommended layered approach (UI, Logic, Data). Use when structuring a new project or refactoring for scalability. |
| [flutter-build-responsive-layout](skills/flutter-build-responsive-layout/SKILL.md) | Use `LayoutBuilder`, `MediaQuery`, or `Expanded/Flexible` to create a layout that adapts to different screen sizes. Use when you need the UI to look good on both mobile and tablet/desktop form factors. |
| [flutter-fix-layout-issues](skills/flutter-fix-layout-issues/SKILL.md) | Fixes Flutter layout errors (overflows, unbounded constraints) using Dart and Flutter MCP tools. Use when addressing "RenderFlex overflowed", "Vertical viewport was given unbounded height", or similar layout issues. |
| [flutter-implement-json-serialization](skills/flutter-implement-json-serialization/SKILL.md) | Create model classes with `fromJson` and `toJson` methods using `dart:convert`. Use when manually mapping JSON keys to class properties for simple data structures. |
| [flutter-setup-declarative-routing](skills/flutter-setup-declarative-routing/SKILL.md) | Configure `MaterialApp.router` using a package like `go_router` for advanced URL-based navigation. Use when developing web applications or mobile apps that require specific deep linking and browser history support. |
| [flutter-setup-localization](skills/flutter-setup-localization/SKILL.md) | Add `flutter_localizations` and `intl` dependencies, enable "generate true" in `pubspec.yaml`, and create an `l10n.yaml` configuration file. Use when initializing localization support for a new Flutter project. |
| [flutter-use-http-package](skills/flutter-use-http-package/SKILL.md) | Use the `http` package to execute GET, POST, PUT, or DELETE requests. Use when you need to fetch from or send data to a REST API. |
## Contributing

To contribute skills, see the instructions in [tool/generator/README.md](tool/generator/README.md).

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for more information.

## Code of Conduct

Please see [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for more information.
