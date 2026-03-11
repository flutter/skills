---
name: "flutter-architecture"
description: "Build an app using the Flutter team's recommended app architecture"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 18:03:18 GMT"

---
# Architecting-Flutter-Apps

## Goal
The agent implements a scalable, maintainable, and testable Flutter application architecture using the Model-View-ViewModel (MVVM) pattern, unidirectional data flow, and strict separation of concerns across UI, Domain, and Data layers.

## When to Use
* Bootstrapping a new Flutter project intended for scale.
* Refactoring a monolithic Flutter codebase into a layered architecture.
* Implementing state management, data fetching, and local caching.
* Structuring project directories for a growing team and codebase.

## Instructions

**Interaction Rule:** Evaluate the current project context for architectural requirements (e.g., preferred state management solution, API endpoints, local storage needs). If missing or ambiguous, ask the user for clarification before proceeding with implementation.

1. **Plan:**
   * Identify the feature scope and required data sources.
   * Map out the required Services (external APIs), Repositories (single source of truth), ViewModels (UI state), and Views (Widgets).
2. **Execute Data Layer:**
   * Implement stateless Service classes to wrap external APIs or local storage.
   * Implement Repository classes to consume Services, handle caching/retry logic, and expose immutable Domain Models.
3. **Execute Domain Layer (Optional):**
   * Implement Use-Cases (Interactors) only if the business logic is exceedingly complex or requires merging data from multiple Repositories.
4. **Execute UI Layer:**
   * Implement ViewModels (using `ChangeNotifier` or similar) to manage UI state and expose Commands for user interactions.
   * Implement Views (Widgets) that listen to ViewModels and render the UI declaratively.
5. **Wire Dependencies:**
   * Inject Services into Repositories, and Repositories into ViewModels using a dependency injection container (e.g., `provider`).

## Decision Logic

Use the following logic to determine architectural boundaries and folder structures:

* **Do you need a Domain Layer (Use-Cases)?**
  * *If* the feature requires merging data from multiple repositories, contains exceedingly complex business logic, or shares logic across multiple ViewModels -> **Yes**. Create `lib/domain/usecases/`.
  * *If* the feature simply reads/writes data from a single repository -> **No**. The ViewModel should interact with the Repository directly.
* **How should the project directories be structured?**
  * *UI Layer* -> Group by feature (e.g., `lib/ui/auth/view_models/`, `lib/ui/auth/widgets/`).
  * *Data/Domain Layer* -> Group by type (e.g., `lib/data/repositories/`, `lib/data/services/`, `lib/domain/models/`).
  * *Shared UI* -> Place reusable widgets and themes in `lib/ui/core/`.

## Best Practices

* **Enforce Unidirectional Data Flow:** Ensure data flows strictly from the Data Layer -> UI Layer. Events must flow from the UI Layer -> Data Layer.
* **Keep Views "Dumb":** Restrict View logic to simple UI conditionals, animations, and routing. Delegate all business and state logic to the ViewModel.
* **Use Immutable Data Models:** Define all domain and API models as immutable. Use code generation packages like `freezed` or `built_value` to generate `copyWith`, equality, and serialization methods.
* **Implement the Command Pattern:** Wrap ViewModel actions in Command objects to standardize how the UI layer sends events to the data layer and to safely handle loading/error states.
* **Use Result Objects for Error Handling:** Return `Result<T>` or `Either<L, R>` from Services and Repositories to handle errors explicitly. Do not rely on unhandled exceptions crossing architectural boundaries.
* **Inject Dependencies:** Pass dependencies via constructors. Never instantiate Repositories or Services directly inside a ViewModel.

## Examples

### 1. Data Layer: Service and Repository
Define a stateless service to handle external calls, and a repository to act as the single source of truth.

**File:** `lib/data/services/shared_preferences_service.dart`
```dart
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static const String _kDarkMode = 'darkMode';

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkMode, value);
  }

  Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDarkMode) ?? false;
  }
}
```

**File:** `lib/data/repositories/theme_repository.dart`
```dart
import 'dart:async';
import 'package:my_app/data/services/shared_preferences_service.dart';
import 'package:my_app/utils/result.dart'; // Assume a standard Result/Either implementation

class ThemeRepository {
  ThemeRepository(this._service);

  final SharedPreferencesService _service;
  final _darkModeController = StreamController<bool>.broadcast();

  Future<Result<bool>> isDarkMode() async {
    try {
      final value = await _service.isDarkMode();
      return Result.ok(value);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> setDarkMode(bool value) async {
    try {
      await _service.setDarkMode(value);
      _darkModeController.add(value);
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Stream<bool> observeDarkMode() => _darkModeController.stream;
}
```

### 2. UI Layer: ViewModel and View
Define a ViewModel to manage state and expose commands, and a View to render the UI.

**File:** `lib/ui/settings/view_models/theme_switch_viewmodel.dart`
```dart
import 'package:flutter/foundation.dart';
import 'package:my_app/data/repositories/theme_repository.dart';
import 'package:my_app/utils/command.dart'; // Assume a standard Command implementation

class ThemeSwitchViewModel extends ChangeNotifier {
  ThemeSwitchViewModel(this._themeRepository) {
    load = Command0(_load)..execute();
    toggle = Command0(_toggle);
  }

  final ThemeRepository _themeRepository;
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  late final Command0<void> load;
  late final Command0<void> toggle;

  Future<Result<void>> _load() async {
    final result = await _themeRepository.isDarkMode();
    if (result is Ok<bool>) {
      _isDarkMode = result.value;
      notifyListeners();
    }
    return result;
  }

  Future<Result<void>> _toggle() async {
    _isDarkMode = !_isDarkMode;
    final result = await _themeRepository.setDarkMode(_isDarkMode);
    notifyListeners();
    return result;
  }
}
```

**File:** `lib/ui/settings/widgets/theme_switch.dart`
```dart
import 'package:flutter/material.dart';
import 'package:my_app/ui/settings/view_models/theme_switch_viewmodel.dart';

class ThemeSwitch extends StatelessWidget {
  const ThemeSwitch({super.key, required this.viewmodel});

  final ThemeSwitchViewModel viewmodel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Dark Mode'),
          ListenableBuilder(
            listenable: viewmodel,
            builder: (context, _) {
              return Switch(
                value: viewmodel.isDarkMode,
                onChanged: (_) {
                  viewmodel.toggle.execute();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
```
