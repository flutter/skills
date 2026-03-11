---
name: "flutter-testing"
description: "Add Flutter unit tests, widget tests, or integration tests"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 17:47:34 GMT"

---
# Testing-Flutter-Apps

## When to Use
* The agent is tasked with implementing automated tests for a Flutter application or plugin.
* The user requests verification of business logic within ViewModels, services, or repositories.
* The user requires UI validation for specific widgets or screens.
* The project requires end-to-end (E2E) integration testing to validate app behavior, routing, or performance on a real device or emulator.
* The agent needs to test communication between Dart and native code in a Flutter plugin.

## Decision Logic
Evaluate the testing requirement to determine the appropriate test category:
* **If** verifying a single function, method, ViewModel, or Repository in isolation:
  * **Then** implement a **Unit Test**. Mock or fake all external dependencies.
* **If** verifying the visual appearance, lifecycle, or user interaction of a single UI component:
  * **Then** implement a **Widget Test**. Use `WidgetTester` to pump the widget and `Finder` to locate elements.
* **If** verifying the complete app flow, routing, dependency injection, or performance on a real device:
  * **Then** implement an **Integration Test**. Use the `integration_test` package.
* **If** testing a Flutter plugin:
  * **Then** implement **Dart Unit/Widget Tests** for the Dart API, **Integration Tests** for platform channel communication, and **Native Unit Tests** (JUnit/XCTest/GoogleTest) for the native platform implementations.

## Instructions

**Interaction Rule:** Evaluate the current project context for existing test setups, state management choices (e.g., Provider, Riverpod, Bloc), and mocking frameworks (e.g., `mocktail`, `mockito`). If this information is missing or ambiguous, ask the user for clarification before proceeding with implementation.

1. **Plan the Test Strategy:** Identify the architectural layer being tested (UI layer vs. Data layer). Determine the inputs, expected outputs, and dependencies that require faking or mocking.
2. **Configure Dependencies:** Ensure `flutter_test` is in `dev_dependencies`. For integration tests, add `integration_test: sdk: flutter`.
3. **Create Fakes and Mocks:** Generate or manually write fake implementations for repositories (when testing ViewModels) or API clients (when testing Repositories).
4. **Implement the Test:**
   * For unit tests, use the `test()` function and `expect()` assertions.
   * For widget tests, use `testWidgets()`, `tester.pumpWidget()`, and `tester.pumpAndSettle()`.
   * For integration tests, initialize `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` before defining tests.
5. **Structure the Test File:** Place unit and widget tests in the `/test/` directory. Place integration tests in the `/integration_test/` directory. Suffix all test files with `_test.dart`.

## Best Practices

* **Test Architectural Components Separately:** Write unit tests for every service, repository, and ViewModel class. Test the logic of each method individually.
* **Use Fakes for Dependencies:** Inject fake or mocked repositories into ViewModels to isolate UI logic from data fetching.
* **Keep Widgets Dumb:** Do not put business logic in widgets. Encapsulate logic in ViewModels and test the ViewModel directly via unit tests.
* **Group Related Tests:** Use the `group()` function to categorize related tests within a single file for better readability and execution control.
* **Verify Unidirectional Data Flow:** Ensure tests validate that data flows from the repository to the ViewModel, and events flow from the UI to the ViewModel.
* **Test Plugin Channels:** When building plugins, write at least one integration test for each platform channel call to verify Dart-to-Native communication.
* **Use pumpAndSettle Carefully:** In widget and integration tests, use `await tester.pumpAndSettle()` to wait for all animations to complete before asserting UI states.

## Examples

### Gold Standard: ViewModel Unit Test (Logic Layer)
This example demonstrates testing a ViewModel by injecting a fake repository.

```dart
// test/view_models/home_view_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/view_models/home_view_model.dart';
import 'package:my_app/models/booking.dart';

// Fake implementation of the dependency
class FakeBookingRepository implements BookingRepository {
  List<Booking> bookings = [];

  @override
  Future<void> createBooking(Booking booking) async {
    bookings.add(booking);
  }

  @override
  Future<List<Booking>> getBookings() async {
    return bookings;
  }
}

void main() {
  group('HomeViewModel Tests', () {
    late HomeViewModel viewModel;
    late FakeBookingRepository fakeRepository;

    setUp(() {
      fakeRepository = FakeBookingRepository();
      viewModel = HomeViewModel(bookingRepository: fakeRepository);
    });

    test('should load bookings successfully', () async {
      // Arrange
      final testBooking = Booking(id: '1', title: 'Test Booking');
      await fakeRepository.createBooking(testBooking);

      // Act
      await viewModel.loadBookings();

      // Assert
      expect(viewModel.bookings.isNotEmpty, true);
      expect(viewModel.bookings.first.title, 'Test Booking');
    });
  });
}
```

### Gold Standard: Widget Test (UI Layer)
This example demonstrates testing a UI component using `WidgetTester`.

```dart
// test/ui/home_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/ui/home_screen.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    testWidgets('should display title and increment counter on tap', (WidgetTester tester) async {
      // Arrange: Pump the widget into the test environment
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(title: 'Test Home'),
        ),
      );

      // Assert: Verify initial state
      expect(find.text('Test Home'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);

      // Act: Find the FAB and tap it
      final fabFinder = find.byKey(const Key('increment_fab'));
      await tester.tap(fabFinder);

      // Trigger a frame to process the state change
      await tester.pump();

      // Assert: Verify the counter incremented
      expect(find.text('1'), findsOneWidget);
    });
  });
}
```

### Gold Standard: Integration Test (End-to-End)
This example demonstrates a full integration test running on a device.

```dart
// integration_test/app_flow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/main.dart' as app;

void main() {
  // Initialize the integration test binding
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End App Flow', () {
    testWidgets('should navigate to details screen and verify data', (WidgetTester tester) async {
      // Arrange: Start the app
      app.main();
      await tester.pumpAndSettle();

      // Assert: Verify we are on the home screen
      expect(find.text('Welcome to App'), findsOneWidget);

      // Act: Tap the navigation button
      final navButton = find.byKey(const Key('nav_to_details_button'));
      await tester.tap(navButton);

      // Wait for the navigation animation to finish
      await tester.pumpAndSettle();

      // Assert: Verify we arrived at the details screen
      expect(find.text('Details Screen'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
```
