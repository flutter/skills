---
name: "flutter-state-management"
description: "Manage state in your Flutter application"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 18:08:25 GMT"

---
# Architecting-Flutter-Apps

## When to Use
* The agent is tasked with bootstrapping or structuring a new Flutter project.
* The agent needs to implement state management, data fetching, or data flow in a Flutter application.
* The agent is refactoring a Flutter app to improve separation of concerns, testability, or performance.
* The agent must resolve UI jank caused by heavy synchronous computations.
* The agent is migrating a React Native application to Flutter and needs to map component states to Flutter's reactive model.

## Decision Logic
When determining how to handle state and architecture, apply the following decision trees:

**1. State Management Selection**
* **Is the state contained entirely within a single widget (e.g., current tab index, animation progress, form input)?**
  * **Yes:** Use Ephemeral State. Implement a `StatefulWidget` and mutate state using `setState()`.
  * **No:** Use App State. Implement a state management solution like `Provider` with `ChangeNotifier`.

**2. Architectural Layering**
* **Does the app perform simple CRUD operations without complex data merging?**
  * **Yes:** Use a 2-layer architecture: UI Layer (Views/ViewModels) and Data Layer (Repositories/Services).
  * **No:** Introduce a Domain Layer. Create Use-Cases (Interactors) to encapsulate complex business logic and merge data from multiple repositories.

**3. Concurrency and Performance**
* **Does a data parsing or processing task exceed the 16ms frame budget (causing UI jank)?**
  * **Yes:** Offload the computation to a background thread using `Isolate.run()`.
  * **No:** Execute synchronously on the main thread.

## Instructions

1. **Evaluate Context:** Scan the repository for existing architectural patterns and state management packages (e.g., `provider`, `riverpod`, `flutter_bloc`). If the state management approach is undefined or ambiguous, ask the user for their preferred package before proceeding.
2. **Establish the Data Layer:** 
   * Create Service classes to handle raw external interactions (HTTP, local storage).
   * Create Repository classes to act as the Single Source of Truth (SSOT). Repositories must consume Services and output strongly-typed Domain Models.
3. **Establish the UI Layer (MVVM):**
   * Create ViewModels that extend `ChangeNotifier`. ViewModels must consume Repositories, hold UI state, and expose Commands (methods) for user interactions.
   * Create Views (Widgets) that consume ViewModels. Keep Views devoid of business logic.
4. **Implement Unidirectional Data Flow (UDF):** Ensure events flow from the View to the ViewModel, which mutates the Repository. The Repository updates the ViewModel, which calls `notifyListeners()` to rebuild the View.
5. **Apply Optimistic State (If applicable):** For network-dependent UI actions (like liking a post or subscribing), immediately update the ViewModel state and call `notifyListeners()`. Revert the state and catch the error only if the Repository operation fails.

## Best Practices

* **Treat UI as a function of state:** Never mutate state directly within a `StatelessWidget` or bypass `setState()` in a `StatefulWidget`. The UI must strictly reflect the current data state.
* **Enforce Unidirectional Data Flow (UDF):** Data flows down (Data -> Logic -> UI), events flow up (UI -> Logic -> Data).
* **Use `ChangeNotifier` efficiently:** Call `notifyListeners()` only when the state has actually changed to avoid unnecessary widget rebuilds.
* **Optimize `Consumer` placement:** Place `Consumer` widgets as deep in the widget tree as possible. Do not wrap entire screens in a `Consumer` if only a small text field needs to update.
* **Read state without listening:** Use `Provider.of<T>(context, listen: false)` when you only need to trigger an action (like a button press) without subscribing the widget to state changes.
* **Use Isolates for heavy lifting:** Use `Isolate.run()` for parsing large JSON payloads or processing images to prevent blocking the main UI thread.

## Examples

### High-Fidelity MVVM Architecture with Provider and Isolates

**File: `lib/data/models/article_model.dart`**
```dart
class Article {
  final String id;
  final String title;
  final String content;

  const Article({required this.id, required this.title, required this.content});

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
    );
  }
}
```

**File: `lib/data/repositories/article_repository.dart`**
```dart
import 'dart:convert';
import 'dart:isolate';
import 'package:http/http.dart' as http;
import '../models/article_model.dart';

class ArticleRepository {
  final http.Client httpClient;

  ArticleRepository({required this.httpClient});

  Future<List<Article>> fetchArticles() async {
    final response = await httpClient.get(Uri.parse('https://api.example.com/articles'));

    if (response.statusCode == 200) {
      // Offload heavy JSON parsing to a background isolate to prevent UI jank
      return Isolate.run(() {
        final List<dynamic> decodedJson = jsonDecode(response.body);
        return decodedJson.map((json) => Article.fromJson(json)).toList();
      });
    } else {
      throw Exception('Failed to load articles');
    }
  }

  Future<void> subscribeToArticle(String articleId) async {
    // Simulate network request
    await Future.delayed(const Duration(seconds: 1));
    // Simulate potential failure
    if (articleId.isEmpty) throw Exception('Invalid ID');
  }
}
```

**File: `lib/ui/viewmodels/article_viewmodel.dart`**
```dart
import 'package:flutter/foundation.dart';
import '../../data/models/article_model.dart';
import '../../data/repositories/article_repository.dart';

class ArticleViewModel extends ChangeNotifier {
  final ArticleRepository _repository;

  ArticleViewModel({required ArticleRepository repository}) : _repository = repository;

  List<Article> _articles = [];
  List<Article> get articles => _articles;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final Set<String> _subscribedArticleIds = {};

  Future<void> loadArticles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _articles = await _repository.fetchArticles();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isSubscribed(String articleId) => _subscribedArticleIds.contains(articleId);

  // Example of Optimistic State Pattern
  Future<void> toggleSubscription(String articleId) async {
    final wasSubscribed = isSubscribed(articleId);

    // 1. Optimistically update UI state
    if (wasSubscribed) {
      _subscribedArticleIds.remove(articleId);
    } else {
      _subscribedArticleIds.add(articleId);
    }
    notifyListeners();

    // 2. Perform background operation
    try {
      await _repository.subscribeToArticle(articleId);
    } catch (e) {
      // 3. Revert state if operation fails
      if (wasSubscribed) {
        _subscribedArticleIds.add(articleId);
      } else {
        _subscribedArticleIds.remove(articleId);
      }
      _errorMessage = 'Failed to update subscription';
      notifyListeners();
    }
  }
}
```

**File: `lib/ui/views/article_list_view.dart`**
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/article_viewmodel.dart';

class ArticleListView extends StatefulWidget {
  const ArticleListView({super.key});

  @override
  State<ArticleListView> createState() => _ArticleListViewState();
}

class _ArticleListViewState extends State<ArticleListView> {
  @override
  void initState() {
    super.initState();
    // Fetch data once when the widget is inserted into the tree
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ArticleViewModel>(context, listen: false).loadArticles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Articles')),
      body: Consumer<ArticleViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(child: Text('Error: ${viewModel.errorMessage}'));
          }

          if (viewModel.articles.isEmpty) {
            return const Center(child: Text('No articles found.'));
          }

          return ListView.builder(
            itemCount: viewModel.articles.length,
            itemBuilder: (context, index) {
              final article = viewModel.articles[index];
              final isSubscribed = viewModel.isSubscribed(article.id);

              return ListTile(
                title: Text(article.title),
                subtitle: Text(article.content),
                trailing: IconButton(
                  icon: Icon(
                    isSubscribed ? Icons.star : Icons.star_border,
                    color: isSubscribed ? Colors.amber : Colors.grey,
                  ),
                  onPressed: () {
                    // Use listen: false when dispatching actions from the UI
                    Provider.of<ArticleViewModel>(context, listen: false)
                        .toggleSubscription(article.id);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

**File: `lib/main.dart`**
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'data/repositories/article_repository.dart';
import 'ui/viewmodels/article_viewmodel.dart';
import 'ui/views/article_list_view.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<ArticleRepository>(
          create: (_) => ArticleRepository(httpClient: http.Client()),
        ),
        ChangeNotifierProvider<ArticleViewModel>(
          create: (context) => ArticleViewModel(
            repository: Provider.of<ArticleRepository>(context, listen: false),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Architecture Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ArticleListView(),
    );
  }
}
```
