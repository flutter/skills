---
name: "flutter-routing-and-navigation"
description: "Move between or deep link to different screens or routes within a Flutter application"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 18:05:22 GMT"

---
# Navigating-And-Routing-Flutter-Apps

## When to Use
* The agent needs to implement screen transitions, dialogs, or deep linking in a Flutter application.
* The user requests passing data or state between different screens.
* The project requires nested navigation flows (e.g., bottom navigation bars with independent stacks, multi-step setup wizards).
* The application needs to support web URL synchronization or mobile deep links.

## Decision Logic
Evaluate the project requirements to determine the appropriate routing strategy:

1. **Routing Architecture:**
   * *If* the app is simple, has no complex deep linking, and does not target the web -> **Use** imperative `Navigator` (`Navigator.push`, `Navigator.pop`).
   * *If* the app requires deep linking, web URL synchronization, or advanced routing -> **Use** the declarative `Router` API (highly recommended to use the `go_router` package).
   * *If* the app currently uses named routes (`MaterialApp.routes`) -> **Migrate** to `go_router` or standard `Navigator` with `MaterialPageRoute`, as named routes are not recommended for deep linking or web.
2. **Passing Data:**
   * *If* passing data to a new screen -> **Prefer** passing strongly typed objects directly via the destination widget's constructor.
   * *If* using named routes or `onGenerateRoute` -> **Use** `RouteSettings.arguments` and extract via `ModalRoute.of(context)!.settings.arguments`.
3. **Nested Navigation:**
   * *If* building a sub-flow (e.g., a multi-step form or persistent bottom nav) -> **Use** a nested `Navigator` widget with its own `GlobalKey<NavigatorState>` and `onGenerateRoute` implementation.

## Instructions
1. **Analyze Context:** Scan the `pubspec.yaml` and `lib/main.dart` to determine the existing routing strategy (e.g., `go_router`, `auto_route`, or vanilla `Navigator`).
2. **Interaction Rule:** If the routing strategy is ambiguous, or if the user requests deep linking but no declarative router is configured, ask the user for clarification on whether to introduce `go_router` before proceeding.
3. **Define Routes:** Extract all route paths into self-documenting constants (e.g., `const String routeHome = '/';`).
4. **Implement Navigation:** Write the navigation logic using the selected strategy. Ensure transitions match the target platform (`MaterialPageRoute` vs `CupertinoPageRoute`).
5. **Handle State:** If passing data, define a dedicated class for the arguments to ensure type safety.
6. **Manage Back Navigation:** Implement `PopScope` to handle hardware back buttons and swipe-to-go-back gestures, especially within nested flows to prevent accidental app exits.

## Best Practices
* **Avoid Named Routes:** Do not use `MaterialApp.routes` for new applications. They lack deep link customization and do not support the browser forward button. Use `go_router` or `Navigator.push` instead.
* **Enforce Type Safety:** Pass data via constructor arguments for compile-time safety rather than relying on dynamic `RouteSettings.arguments`.
* **Optimize Deep Linking:** When using the `Router` API, ensure routes are *page-backed* so they are deep-linkable. Pageless routes (created via `Navigator.push` in a Router app) will be removed if a deep link alters the page-backed route beneath them.
* **Handle Platform Transitions:** Use `CupertinoPageRoute` for iOS-style slide-in transitions and `MaterialPageRoute` for Android-style fade/zoom transitions.
* **Isolate Nested Navigators:** Always assign a `GlobalKey<NavigatorState>` to nested `Navigator` widgets to control them programmatically without affecting the root `Navigator`.

## Examples

### Example 1: Imperative Navigation with Strongly Typed Data
Demonstrates navigating to a detail screen by passing data directly through the constructor.

```dart
import 'package:flutter/material.dart';

// 1. Define the data model
class Todo {
  final String id;
  final String title;
  final String description;

  const Todo({required this.id, required this.title, required this.description});
}

// 2. List Screen
class TodosScreen extends StatelessWidget {
  final List<Todo> todos;

  const TodosScreen({super.key, required this.todos});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todos')),
      body: ListView.builder(
        itemCount: todos.length,
        itemBuilder: (context, index) {
          final todo = todos[index];
          return ListTile(
            title: Text(todo.title),
            onTap: () {
              // Imperative navigation passing data via constructor
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => DetailScreen(todo: todo),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// 3. Detail Screen
class DetailScreen extends StatelessWidget {
  final Todo todo;

  const DetailScreen({super.key, required this.todo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(todo.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(todo.description),
      ),
    );
  }
}
```

### Example 2: Complex Nested Navigation Flow
Demonstrates a nested `Navigator` for a multi-step setup flow, complete with hardware back-button handling via `PopScope`.

```dart
import 'package:flutter/material.dart';

// Route Constants
const String routeSetupStart = '/';
const String routeSetupStepTwo = '/step_two';
const String routeSetupFinished = '/finished';

class SetupFlow extends StatefulWidget {
  const SetupFlow({super.key});

  @override
  State<SetupFlow> createState() => _SetupFlowState();
}

class _SetupFlowState extends State<SetupFlow> {
  // Dedicated key for the nested navigator
  final GlobalKey<NavigatorState> _nestedNavigatorKey = GlobalKey<NavigatorState>();

  Future<bool> _confirmExit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Setup?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Exit')),
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')),
        ],
      ),
    );
    return result ?? false;
  }

  void _exitSetup() {
    // Pops the root navigator, exiting the entire flow
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        
        // Check if nested navigator can pop
        if (_nestedNavigatorKey.currentState?.canPop() ?? false) {
          _nestedNavigatorKey.currentState?.pop();
          return;
        }

        // If at the start of the nested flow, confirm exit
        if (await _confirmExit() && context.mounted) {
          _exitSetup();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (await _confirmExit() && context.mounted) {
                _exitSetup();
              }
            },
          ),
          title: const Text('Setup Wizard'),
        ),
        body: Navigator(
          key: _nestedNavigatorKey,
          initialRoute: routeSetupStart,
          onGenerateRoute: (RouteSettings settings) {
            Widget page;
            switch (settings.name) {
              case routeSetupStart:
                page = StepOnePage(
                  onNext: () => _nestedNavigatorKey.currentState?.pushNamed(routeSetupStepTwo),
                );
                break;
              case routeSetupStepTwo:
                page = StepTwoPage(
                  onNext: () => _nestedNavigatorKey.currentState?.pushNamed(routeSetupFinished),
                );
                break;
              case routeSetupFinished:
                page = FinishedPage(onFinish: _exitSetup);
                break;
              default:
                throw StateError('Unexpected route: ${settings.name}');
            }
            return MaterialPageRoute<void>(
              builder: (context) => page,
              settings: settings,
            );
          },
        ),
      ),
    );
  }
}

// Sub-pages (Implementation details omitted for brevity)
class StepOnePage extends StatelessWidget {
  final VoidCallback onNext;
  const StepOnePage({super.key, required this.onNext});
  @override Widget build(BuildContext context) => Center(child: ElevatedButton(onPressed: onNext, child: const Text('Next')));
}

class StepTwoPage extends StatelessWidget {
  final VoidCallback onNext;
  const StepTwoPage({super.key, required this.onNext});
  @override Widget build(BuildContext context) => Center(child: ElevatedButton(onPressed: onNext, child: const Text('Next')));
}

class FinishedPage extends StatelessWidget {
  final VoidCallback onFinish;
  const FinishedPage({super.key, required this.onFinish});
  @override Widget build(BuildContext context) => Center(child: ElevatedButton(onPressed: onFinish, child: const Text('Finish')));
}
```
