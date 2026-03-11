---
name: "flutter-testing"
description: "Add Flutter unit tests, widget tests, or integration tests"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 18:13:39 GMT"

---
# Testing-Flutter-Apps

## When to Use
* When a user requests to add, update, or configure automated tests for a Flutter application or plugin.
* When verifying the logic of architectural components such as ViewModels, Repositories, or Services.
* When validating the UI rendering and interaction of individual Flutter widgets.
* When setting up end-to-end (E2E) integration tests to validate app flows, routing, dependency injection, or performance on real devices.
* When testing platform-specific native code and platform channel communication within a Flutter plugin.

## Instructions

**Interaction Rule:** Evaluate the current project context to determine the scope of testing required (e.g., unit, widget, integration, or plugin native tests). If the target component, required dependencies to mock, or testing scope is missing or ambiguous, ask the user for clarification before proceeding with implementation.

**Plan:**
1. Analyze the component under test to determine the appropriate testing category (Unit, Widget, or Integration).
2. Identify external dependencies (e.g., APIs, databases, platform channels) that must be mocked or faked.
3. Determine the required testing packages (`test`, `flutter_test`, `integration_test`, `mockito`, `mocktail`).

**Execute:**
1. Add necessary dependencies to the `dev_dependencies` section of `pubspec.yaml`.
2. Create the test file in the appropriate directory (`/test/` for unit/widget tests, `/integration_test/` for integration tests).
3. Implement the test setup, execution, and verification steps using the appropriate testing APIs.
4. For plugins, configure native test directories (`/android/src/test/`, `/example/ios/RunnerTests/`, etc.) if native unit testing is required.

## Decision Logic

Use the following decision tree to determine the appropriate test type:

* **Is the target a single function, method, or class (e.g., ViewModel, Service, Repository)?**
  * **Yes:** Implement a **Unit Test**. Mock external dependencies. Do not involve disk I/O or screen rendering.
* **Is the target a single UI component or View?**
  * **Yes:** Implement a **Widget Test**. Provide a test environment with the appropriate widget lifecycle context.
* **Is the target a complete app flow, routing logic, dependency injection, or performance metric?**
  * **Yes:** Implement an **Integration Test**. Use the `integration_test` package and run on a real device or emulator.
* **Is the target a Flutter plugin containing native code?**
  * **Yes:** 
    * For the Dart-facing API: Implement **Dart Unit/Widget Tests** with mocked platform channels.
    * For native logic: Implement **Native Unit Tests** (JUnit, XCTest, GoogleTest).
    * For Dart-to-Native communication: Implement **Integration Tests** or synthesized E2E tests.

## Best Practices

* Write unit tests for every service, repository, and ViewModel class. Test the logic of each method individually.
* Mock or fake all external dependencies in unit and widget tests to ensure deterministic execution and fast feedback loops.
* Write widget tests specifically for views to ensure the UI looks and interacts as expected without requiring a full app launch.
* Use the `integration_test` package for E2E testing. Always add it as a dependency for the Flutter app's test file.
* Design architectural components with observability and testability in mind. Ensure components have well-defined inputs and outputs to make them easily fakeable.
* For plugins, implement at least one integration test for each platform channel call to validate communication between Dart and native languages.
* Group related tests using the `group()` function to organize test suites logically and improve test output readability.

## Examples

### Unit Test: ViewModel with Mocked Repository
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_app/viewmodels/user_viewmodel.dart';
import 'package:my_app/repositories/user_repository.dart';
import 'package:my_app/models/user.dart';

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  group('UserViewModel Tests', () {
    late UserViewModel viewModel;
    late MockUserRepository mockUserRepository;

    setUp(() {
      mockUserRepository = MockUserRepository();
      viewModel = UserViewModel(userRepository: mockUserRepository);
    });

    test('fetchUser updates state to loaded on success', () async {
      // Arrange
      final testUser = User(id: '1', name: 'Test User');
      when(() => mockUserRepository.getUser(any()))
          .thenAnswer((_) async => testUser);

      // Act
      await viewModel.fetchUser('1');

      // Assert
      expect(viewModel.isLoading, false);
      expect(viewModel.user, testUser);
      verify(() => mockUserRepository.getUser('1')).called(1);
    });
  });
}
```

### Widget Test: View Interaction
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/views/login_view.dart';

void main() {
  group('LoginView Widget Tests', () {
    testWidgets('displays error message on invalid login', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const MaterialApp(home: LoginView()));

      final emailField = find.byKey(const Key('email_input'));
      final passwordField = find.byKey(const Key('password_input'));
      final loginButton = find.byKey(const Key('login_button'));

      // Act
      await tester.enterText(emailField, 'invalid_email');
      await tester.enterText(passwordField, 'short');
      await tester.tap(loginButton);
      await tester.pumpAndSettle(); // Wait for animations/state updates

      // Assert
      expect(find.text('Invalid email or password'), findsOneWidget);
    });
  });
}
```

### Integration Test: End-to-End App Flow
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/main.dart' as app;

void main() {
  // Initialize the integration test environment
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End App Flow', () {
    testWidgets('User can log in and navigate to home screen', (WidgetTester tester) async {
      // Arrange: Start the app
      app.main();
      await tester.pumpAndSettle();

      // Act: Perform login
      final emailField = find.byKey(const Key('email_input'));
      final passwordField = find.byKey(const Key('password_input'));
      final loginButton = find.byKey(const Key('login_button'));

      await tester.enterText(emailField, 'user@example.com');
      await tester.enterText(passwordField, 'securepassword123');
      await tester.tap(loginButton);
      
      // Trigger frames until navigation and animations complete
      await tester.pumpAndSettle();

      // Assert: Verify routing to Home Screen
      expect(find.text('Welcome, User!'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
```
