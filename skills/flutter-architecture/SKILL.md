---
name: "flutter-architecture"
description: "Build an app using the Flutter team's recommended app architecture"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 17:30:56 GMT"

---
# Architecting-Flutter-Apps

## Goal
The agent structures, organizes, and designs Flutter applications using a layered architecture (MVVM) to ensure maintainability, scalability, and testability as project requirements grow.

## When to Use
* The user requests a new Flutter project setup or feature implementation.
* The user asks to refactor an existing Flutter application to improve scalability or maintainability.
* The agent needs to integrate external APIs or databases into a Flutter UI, requiring clear separation of concerns.

## Instructions
**Interaction Rule:** Evaluate the current project context for [State Management Preference, API/Data Sources, Feature Scope] requirements. If missing, ask the user for clarification before proceeding with implementation.

1. **Plan:** 
   * Identify the feature scope and required data sources.
   * Define the necessary Services (external APIs), Repositories (single source of truth), ViewModels (state management), and Views (UI).
2. **Execute Data Layer:** 
   * Implement stateless Service classes to wrap external APIs.
   * Implement Repository classes to consume Services, handle caching/retry logic, and transform raw data into domain models.
3. **Execute Logic Layer:** 
   * Implement ViewModels to manage UI state, process user events, and interact with Repositories.
4. **Execute UI Layer:** 
   * Implement lean, reusable Widgets that observe ViewModels and render the UI as a function of state.

## Decision Logic
* **Does the feature require external data (HTTP, local database, platform plugins)?**
  * **Yes:** Create a `Service` class to wrap the API. Inject the `Service` into a `Repository`.
  * **No:** Manage the local state directly within the `Repository` or `ViewModel`.
* **Does the feature have highly complex business logic or combine data from multiple repositories?**
  * **Yes:** Implement an optional Domain Layer (Use Cases / Interactors) between the ViewModels and Repositories.
  * **No:** Connect the `ViewModel` directly to the `Repository`.

## Best Practices
* **Enforce Unidirectional Data Flow:** Ensure data flows strictly from Data -> Logic -> UI. Route user events strictly from UI -> Logic -> Data.
* **Maintain a Single Source of Truth:** Update application data only within the Data layer (Repositories). Never mutate domain data directly within the UI layer.
* **Keep Widgets Lean:** Restrict the UI layer to layout, animation, and simple routing logic. Delegate all business logic and data formatting to ViewModels.
* **Isolate External Dependencies:** Wrap all HTTP calls, local storage, and platform plugins in stateless Service classes. Never call an API directly from a Widget or ViewModel.
* **Organize by Feature:** Structure the `/lib` directory by feature (e.g., `/lib/features/authentication/`) containing its own `ui`, `logic`, and `data` subdirectories.
* **Handle Errors Deterministically:** Catch exceptions in the Data layer and return formatted error states or `Result` objects to the Logic layer to prevent UI crashes.

## Examples

### Gold Standard: Feature-Based MVVM Architecture

**1. Service (External API Wrapper)**
File: `/lib/features/users/data/services/user_api_service.dart`
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class UserApiService {
  static const String _baseUrl = 'https://api.example.com/v1';

  Future<Map<String, dynamic>> fetchUserData(String userId) async {
    final response = await http.get(Uri.parse('$_baseUrl/users/$userId'));
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch user data');
    }
  }
}
```

**2. Repository (Single Source of Truth & Data Transformation)**
File: `/lib/features/users/data/repositories/user_repository.dart`
```dart
import '../services/user_api_service.dart';
import '../models/user_domain_model.dart';

class UserRepository {
  final UserApiService _apiService;
  UserDomainModel? _cachedUser;

  UserRepository(this._apiService);

  Future<UserDomainModel> getUser(String userId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedUser != null && _cachedUser!.id == userId) {
      return _cachedUser!;
    }

    try {
      final rawData = await _apiService.fetchUserData(userId);
      _cachedUser = UserDomainModel.fromJson(rawData);
      return _cachedUser!;
    } catch (e) {
      // Handle or rethrow domain-specific errors
      throw Exception('Repository Error: Could not retrieve user.');
    }
  }
}
```

**3. ViewModel (Logic Layer)**
File: `/lib/features/users/logic/user_view_model.dart`
```dart
import 'package:flutter/foundation.dart';
import '../data/repositories/user_repository.dart';
import '../data/models/user_domain_model.dart';

class UserViewModel extends ChangeNotifier {
  final UserRepository _userRepository;

  UserViewModel(this._userRepository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UserDomainModel? _user;
  UserDomainModel? get user => _user;

  Future<void> loadUser(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _userRepository.getUser(userId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

**4. View (UI Layer)**
File: `/lib/features/users/ui/user_view.dart`
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/user_view_model.dart';

class UserView extends StatefulWidget {
  final String userId;

  const UserView({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserView> createState() => _UserViewState();
}

class _UserViewState extends State<UserView> {
  @override
  void initState() {
    super.initState();
    // Defer the load command until after the initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserViewModel>().loadUser(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: Consumer<UserViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(child: Text('Error: ${viewModel.errorMessage}'));
          }

          if (viewModel.user == null) {
            return const Center(child: Text('No user data available.'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${viewModel.user!.name}', style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 8),
                Text('Email: ${viewModel.user!.email}'),
              ],
            ),
          );
        },
      ),
    );
  }
}
```
