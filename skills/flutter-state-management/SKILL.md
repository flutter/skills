---
name: "flutter-state-management"
description: "Manage state in your Flutter application"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 17:42:30 GMT"

---
# Managing-Flutter-State-And-Architecture

## When to Use
* The agent is tasked with building or refactoring a Flutter application's architecture.
* The agent needs to implement state management for sharing data across multiple widgets.
* The agent must separate business logic from UI components using the Model-View-ViewModel (MVVM) pattern.
* The agent is implementing Unidirectional Data Flow (UDF) and a Single Source of Truth (SSOT) for application data.

## Instructions

**Interaction Rule:** Evaluate the current project context for existing state management dependencies (e.g., `provider`), defined architectural layers (Data, Logic, UI), and the scope of the state (ephemeral vs. app-wide). If this information is missing or ambiguous, ask the user for clarification before proceeding with implementation.

1. **Plan the Architecture:**
   * Divide the application into three distinct layers: UI (Views), Logic (ViewModels), and Data (Repositories/Services).
   * Identify the Single Source of Truth (SSOT) for the feature's data.
2. **Determine State Scope:**
   * Classify required state as either *ephemeral* (local to a single widget) or *app state* (shared across widgets).
3. **Implement the Data Layer:**
   * Create Repository classes to handle low-level tasks (HTTP requests, caching) and expose data to the Logic layer.
4. **Implement the Logic Layer (ViewModel):**
   * Create ViewModel classes that extend `ChangeNotifier`.
   * Write methods to mutate data via Repositories and call `notifyListeners()` to trigger UI rebuilds.
5. **Implement the UI Layer (View):**
   * Build declarative UIs that reflect the current state.
   * Use `StatelessWidget` combined with `Consumer` or `ListenableBuilder` to listen to ViewModel changes.
   * Route user events from the UI to the ViewModel commands.

## Decision Logic

Use the following decision tree to determine the appropriate state management and architectural approach:

* **Step 1: Is the state contained within a single widget and temporary (e.g., current tab index, animation progress)?**
  * **Yes:** Use Ephemeral State. Implement a `StatefulWidget` and use `setState()`.
  * **No:** Proceed to Step 2.
* **Step 2: Does the state need to be shared across multiple widgets or persist across sessions?**
  * **Yes:** Use App State. Proceed to Step 3.
* **Step 3: How complex is the business logic?**
  * **Low Complexity (Simple prop drilling):** Pass data through widget constructors.
  * **Medium to High Complexity:** Implement the MVVM pattern.
    * Use `ChangeNotifier` for the ViewModel.
    * Use `provider` (or a similar wrapper around `InheritedWidget`) to inject the ViewModel into the widget tree.
    * Use `Consumer` or `ListenableBuilder` to rebuild specific UI components when `notifyListeners()` is called.

## Best Practices

* **Enforce Unidirectional Data Flow (UDF):** Ensure state flows from the Data layer, through the Logic layer, to the UI layer. Ensure user events flow in the opposite direction (UI -> Logic -> Data).
* **Maintain a Single Source of Truth (SSOT):** Centralize data mutation within the Data layer (Repositories). Never mutate data directly within the UI layer.
* **Separate Concerns:** Keep UI logic out of widgets. Widgets must only contain layout, styling, and simple routing logic. Delegate all data formatting and business rules to the ViewModel.
* **Think Declaratively:** Build the UI as a function of state (`UI = f(state)`). Do not attempt to imperatively modify widgets (e.g., `widget.update()`). Instead, update the state and allow the framework to rebuild the widget.
* **Optimize Rebuilds:** Place `Consumer` or `ListenableBuilder` widgets as deep in the widget tree as possible to prevent unnecessary rebuilds of large UI portions.
* **Use the Right Widget:** Default to `StatelessWidget`. Only use `StatefulWidget` when managing local, ephemeral state that requires `setState()`.
* **Handle Errors Gracefully:** Catch exceptions in the ViewModel, update an error state property, and call `notifyListeners()` so the UI can display an appropriate error message (e.g., a Snackbar).

## Examples

### Gold Standard: MVVM with ChangeNotifier and Provider

This example demonstrates a complete vertical slice of a feature using MVVM, Unidirectional Data Flow, and the `provider` package.

**1. Data Layer: `lib/data/repositories/subscription_repository.dart`**
```dart
import 'dart:async';

class SubscriptionRepository {
  // Single Source of Truth for subscription status
  bool _isSubscribed = false;

  bool get isSubscribed => _isSubscribed;

  Future<void> subscribeUser() async {
    // Simulate network request
    await Future.delayed(const Duration(seconds: 1));
    
    // Simulate a random network error for demonstration
    if (DateTime.now().second % 2 == 0) {
      throw Exception('Network error: Failed to connect to server.');
    }
    
    _isSubscribed = true;
  }
}
```

**2. Logic Layer: `lib/logic/view_models/subscription_view_model.dart`**
```dart
import 'package:flutter/foundation.dart';
import '../data/repositories/subscription_repository.dart';

class SubscriptionViewModel extends ChangeNotifier {
  final SubscriptionRepository _repository;

  SubscriptionViewModel({required SubscriptionRepository repository}) 
      : _repository = repository;

  bool _isLoading = false;
  String? _errorMessage;

  // Expose state to the UI
  bool get isSubscribed => _repository.isSubscribed;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Command triggered by the UI
  Future<void> subscribe() async {
    if (isSubscribed || _isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Trigger UI rebuild for loading state

    try {
      await _repository.subscribeUser();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners(); // Trigger UI rebuild for success or error state
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
```

**3. UI Layer: `lib/ui/views/subscription_view.dart`**
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/view_models/subscription_view_model.dart';
import '../../data/repositories/subscription_repository.dart';

// Entry point injecting the dependencies
class SubscriptionFeature extends StatelessWidget {
  const SubscriptionFeature({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SubscriptionViewModel(
        repository: SubscriptionRepository(),
      ),
      child: const SubscriptionView(),
    );
  }
}

// The View reacting to state changes
class SubscriptionView extends StatefulWidget {
  const SubscriptionView({super.key});

  @override
  State<SubscriptionView> createState() => _SubscriptionViewState();
}

class _SubscriptionViewState extends State<SubscriptionView> {
  @override
  void initState() {
    super.initState();
    // Listen for errors to show Snackbars (Ephemeral UI effect based on App State)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionViewModel>().addListener(_onErrorChanged);
    });
  }

  void _onErrorChanged() {
    final viewModel = context.read<SubscriptionViewModel>();
    if (viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage!)),
      );
      viewModel.clearError();
    }
  }

  @override
  void dispose() {
    // Clean up listener in a real app scenario
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscribe Now')),
      body: Center(
        // Consumer placed deep in the tree to minimize rebuilds
        child: Consumer<SubscriptionViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const CircularProgressIndicator();
            }

            return ElevatedButton(
              onPressed: viewModel.isSubscribed ? null : viewModel.subscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: viewModel.isSubscribed ? Colors.green : Colors.blue,
              ),
              child: Text(
                viewModel.isSubscribed ? 'Subscribed' : 'Subscribe',
              ),
            );
          },
        ),
      ),
    );
  }
}
```
