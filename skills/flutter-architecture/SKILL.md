---
name: "flutter-architecture"
description: "Build an app using the Flutter team's recommended app architecture"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 17:37:09 GMT"

---
# Architecting-Flutter-Apps

## When to Use
* The agent is initializing a new Flutter project that requires a scalable, maintainable codebase.
* The agent is refactoring an existing Flutter application to separate UI components from business logic and data sources.
* The agent needs to implement data fetching, caching, or state management using the Model-View-ViewModel (MVVM) pattern and layered architecture.

## Instructions

**Plan**
1. Identify the distinct features of the application (e.g., Authentication, Search, User Profile).
2. Determine the external data sources (REST APIs, local databases, device sensors) required for each feature.
3. Map the flow of data from the source to the UI to establish the necessary Services, Repositories, and ViewModels.

**Execute**
1. **Implement the Data Layer:** Create stateless Services to wrap external APIs. Create Repositories to consume Services, handle caching, and transform raw data into domain models.
2. **Implement the Logic Layer:** Create ViewModels to manage UI state, format data for presentation, and expose commands for user interactions.
3. **Implement the UI Layer:** Build lean, declarative Widgets that observe ViewModels and rebuild only when state changes.

**Interaction Rule:** Evaluate the current project context for preferred state management solutions (e.g., `Provider`, `Riverpod`, `Bloc`) and dependency injection setups. If missing or ambiguous, ask the user for clarification before proceeding with implementation.

## Decision Logic

Use the following logic to determine where code belongs within the architecture:

* **Does the code interact with an external API, database, or platform plugin?**
  * **Yes:** Place it in a **Service** class. Keep it stateless and strictly focused on data retrieval/submission.
* **Does the code manage data synchronization, caching, or transform raw API data into application models?**
  * **Yes:** Place it in a **Repository** class. Ensure it acts as the single source of truth for that data type.
* **Does the code format data specifically for the screen or hold temporary UI state (e.g., loading spinners, form input)?**
  * **Yes:** Place it in a **ViewModel** (or Logic/Domain) class.
* **Does the code define the visual layout or handle direct user touch events?**
  * **Yes:** Place it in a **View** (Widget). Ensure it contains zero business logic.
* **Does the business logic require combining data from multiple Repositories or involve highly complex calculations?**
  * **Yes:** Extract it into a **Domain Use-Case** class to prevent ViewModel bloat.

## Best Practices

* **Enforce Unidirectional Data Flow:** Ensure data flows strictly from the Data Layer -> Logic Layer -> UI Layer. User events flow from UI Layer -> Logic Layer -> Data Layer.
* **Keep Widgets Lean:** Strip all business logic, data formatting, and complex conditional statements from Widgets. Delegate these responsibilities to the ViewModel.
* **Use Immutable State:** Define UI state and domain models as immutable objects. When state changes, emit a completely new instance to trigger UI rebuilds predictably.
* **Isolate Dependencies:** Never allow the UI layer to communicate directly with a Service. Always route data requests through a Repository.
* **Implement Dependency Injection:** Inject Services into Repositories, and Repositories into ViewModels. Do not use global singletons for data access.
* **Standardize Error Handling:** Wrap Service and Repository return types in a `Result` (Success/Error) object to force the Logic layer to handle failures explicitly.

## Examples

### Gold Standard: Layered MVVM Architecture

**1. Service (Data Layer)**
Wraps the external API. Stateless and strictly handles network requests.
`lib/data/services/user_api_service.dart`
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class UserApiService {
  static const String _baseUrl = 'https://api.example.com/v1';

  Future<Map<String, dynamic>> fetchUserProfile(String userId) async {
    final response = await http.get(Uri.parse('$_baseUrl/users/$userId'));
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch user profile');
    }
  }
}
```

**2. Repository (Data Layer)**
Consumes the Service, handles errors, and transforms raw data into a Domain Model.
`lib/data/repositories/user_repository.dart`
```dart
import '../services/user_api_service.dart';
import '../../domain/models/user_profile.dart';
import '../../utils/result.dart';

class UserRepository {
  final UserApiService _apiService;
  UserProfile? _cachedProfile;

  UserRepository(this._apiService);

  Future<Result<UserProfile>> getUserProfile(String userId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedProfile != null) {
      return Result.success(_cachedProfile!);
    }

    try {
      final rawData = await _apiService.fetchUserProfile(userId);
      final profile = UserProfile.fromJson(rawData);
      _cachedProfile = profile;
      return Result.success(profile);
    } catch (e) {
      return Result.error(e.toString());
    }
  }
}
```

**3. ViewModel (Logic Layer)**
Manages UI state and exposes commands for the View.
`lib/ui/profile/profile_view_model.dart`
```dart
import 'package:flutter/foundation.dart';
import '../../data/repositories/user_repository.dart';
import '../../domain/models/user_profile.dart';

class ProfileViewModel extends ChangeNotifier {
  final UserRepository _userRepository;
  
  ProfileViewModel(this._userRepository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UserProfile? _userProfile;
  UserProfile? get userProfile => _userProfile;

  Future<void> loadProfile(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _userRepository.getUserProfile(userId);

    if (result.isSuccess) {
      _userProfile = result.value;
    } else {
      _errorMessage = result.error;
    }

    _isLoading = false;
    notifyListeners();
  }
}
```

**4. View (UI Layer)**
Observes the ViewModel and rebuilds when state changes. Contains no business logic.
`lib/ui/profile/profile_view.dart`
```dart
import 'package:flutter/material.dart';
import 'profile_view_model.dart';

class ProfileView extends StatefulWidget {
  final ProfileViewModel viewModel;
  final String userId;

  const ProfileView({
    Key? key, 
    required this.viewModel, 
    required this.userId,
  }) : super(key: key);

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  void initState() {
    super.initState();
    // Execute command on initialization
    widget.viewModel.loadProfile(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          if (widget.viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (widget.viewModel.errorMessage != null) {
            return Center(child: Text('Error: ${widget.viewModel.errorMessage}'));
          }

          final profile = widget.viewModel.userProfile;
          if (profile == null) {
            return const Center(child: Text('No profile data available.'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${profile.name}', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Email: ${profile.email}'),
              ],
            ),
          );
        },
      ),
    );
  }
}
```
