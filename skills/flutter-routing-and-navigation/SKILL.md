---
name: "flutter-routing-and-navigation"
description: "Move between or deep link to different screens or routes within a Flutter application"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 17:39:28 GMT"

---
# Implementing-Flutter-Navigation-and-Routing

## When to Use
* The agent needs to move users between different screens (referred to as "routes" in Flutter, which are simply widgets) within an application.
* The project requires deep linking to open the app directly to a specific location or "deep" inside the app when a URL is received (e.g., from an advertisement).
* The application requires passing data to a new screen or returning data from a screen.
* The UI design involves nested navigation flows, adding tabs to an app, or adding a drawer to a screen.
* The agent must choose between imperative navigation (`Navigator`) and declarative navigation (`Router` / `go_router`).

## Instructions

**Interaction Rule:** Evaluate the current project context for routing complexity, deep linking requirements, and existing routing packages (e.g., `go_router`). If missing, ask the user for clarification before proceeding with implementation.

1. **Plan:** Analyze the application's navigation requirements. Determine if the app needs simple stack-based navigation or advanced declarative routing with deep linking support.
2. **Evaluate:** Check if the app targets the web. If running in a web browser, no additional setup is required for deep linking, but URL strategies may need configuration.
3. **Select:** Choose the appropriate navigation API based on the Decision Logic below. 
4. **Define:** Create self-documenting constants for route paths (e.g., `const String routeHome = '/';`).
5. **Execute:** Implement the navigation logic. Use `Navigator.push()` to go to a new route and `Navigator.pop()` to return to the previous route for simple tasks.
6. **Integrate:** If passing data, define strongly typed classes for the arguments and pass them via widget constructors.

## Decision Logic

Follow this decision tree to select the correct navigation approach:

* **Does the app require deep linking, web URL synchronization, or advanced routing?**
  * **Yes:** Use the `Router` API. It is highly recommended to use a declarative routing package like `go_router` to parse route paths and configure the `Navigator` automatically.
  * **No:** Proceed to the next question.
* **Does the app require independent, nested navigation stacks (e.g., a setup flow or persistent bottom navigation bar)?**
  * **Yes:** Implement a nested `Navigator` widget with its own `GlobalKey<NavigatorState>` and `onGenerateRoute` logic.
  * **No:** Proceed to the next question.
* **Is the navigation simple, linear, and strictly stack-based?**
  * **Yes:** Use the imperative `Navigator` API (`Navigator.push()` and `Navigator.pop()`) with `MaterialPageRoute` or `CupertinoPageRoute`.
  * **No:** Re-evaluate the app's architecture; default to `go_router` for scalable navigation.

*(Note: While named routes via `MaterialApp.routes` can be used for deep linking, they are generally not recommended for most applications due to limitations with customization and browser forward-button support.)*

## Best Practices

* **Prefer Declarative Routing:** Use the `Router` API (via packages like `go_router`) for applications requiring deep linking and web support. It ensures the same screens are displayed when a deep link is received.
* **Avoid Named Routes:** Do not use `Navigator.pushNamed` or `MaterialApp.routes` for most applications. They lack advanced deep link customization and break browser forward-button behavior.
* **Pass Data via Constructors:** Pass data to new screens using strongly typed constructor arguments rather than relying on `RouteSettings.arguments`. This improves type safety and readability.
* **Use Platform-Specific Transitions:** Use `CupertinoPageRoute` for iOS-style slide-in transitions and `MaterialPageRoute` for standard Android-style transitions.
* **Handle Hardware Back Buttons:** Implement the `PopScope` widget to intercept hardware back button presses, especially in nested flows or forms, to prevent accidental data loss.
* **Define Route Constants:** Always use self-documenting constants for route paths (e.g., `const String routeDeviceSetup = '/setup';`) to prevent typos and centralize route definitions.

## Examples

### Gold Standard: Basic Imperative Navigation with Data Passing

Use this pattern for simple, non-deep-linked navigation where data must be passed between screens.

```dart
// lib/models/todo.dart
class Todo {
  final String title;
  final String description;

  const Todo({required this.title, required this.description});
}

// lib/screens/todos_screen.dart
import 'package:flutter/material.dart';
import '../models/todo.dart';
import 'detail_screen.dart';

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

// lib/screens/detail_screen.dart
import 'package:flutter/material.dart';
import '../models/todo.dart';

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

### Gold Standard: Nested Navigation Flow

Use this pattern when a sub-flow (like a setup wizard) requires its own navigation stack independent of the global app navigation.

```dart
// lib/screens/setup_flow.dart
import 'package:flutter/material.dart';

const String routeSetupStart = 'start';
const String routeSetupConnecting = 'connecting';

class SetupFlow extends StatefulWidget {
  final String initialRoute;

  const SetupFlow({super.key, required this.initialRoute});

  @override
  State<SetupFlow> createState() => _SetupFlowState();
}

class _SetupFlowState extends State<SetupFlow> {
  final GlobalKey<NavigatorState> _nestedNavigatorKey = GlobalKey<NavigatorState>();

  void _exitSetup() {
    // Pops the entire setup flow off the root navigator
    Navigator.of(context).pop();
  }

  Future<bool> _confirmExit() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Setup?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
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
          title: const Text('Device Setup'),
        ),
        body: Navigator(
          key: _nestedNavigatorKey,
          initialRoute: widget.initialRoute,
          onGenerateRoute: (RouteSettings settings) {
            Widget page;
            switch (settings.name) {
              case routeSetupStart:
                page = StartPage(
                  onNext: () => _nestedNavigatorKey.currentState!.pushNamed(routeSetupConnecting),
                );
                break;
              case routeSetupConnecting:
                page = ConnectingPage(onComplete: _exitSetup);
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

// lib/screens/start_page.dart
import 'package:flutter/material.dart';

class StartPage extends StatelessWidget {
  final VoidCallback onNext;

  const StartPage({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: onNext,
        child: const Text('Find Devices'),
      ),
    );
  }
}

// lib/screens/connecting_page.dart
import 'package:flutter/material.dart';

class ConnectingPage extends StatelessWidget {
  final VoidCallback onComplete;

  const ConnectingPage({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: onComplete,
        child: const Text('Finish Setup'),
      ),
    );
  }
}
```
