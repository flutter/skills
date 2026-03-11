---
name: "flutter-databases"
description: "Work with databases in a Flutter app"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 17:43:56 GMT"

---
# Architecting-Flutter-Data-Layers

## When to Use
* The agent needs to implement a data layer using the MVVM architecture in a Flutter application.
* The application requires local data persistence using SQLite (`sqflite`).
* The application needs to cache data locally using `shared_preferences`, file systems, or on-device databases.
* The agent must separate business logic from UI by implementing Repositories and Services.

## Instructions

**Interaction Rule:** Evaluate the current project context for [existing data models, required caching strategy, offline-first requirements]. If missing, ask the user for clarification before proceeding with implementation.

1. **Plan:** 
   * Identify the data sources (remote API, local database, key-value store).
   * Determine the appropriate caching strategy based on data size and type using the Decision Logic below.
   * Define the raw data models (API/DB models) and the refined domain models required by the UI.
2. **Execute:**
   * Implement stateless Service classes to wrap external APIs or database interactions.
   * Implement Repository classes to act as the single source of truth for application data.
   * Inject Services into Repositories as private members.
   * Transform raw data models from Services into domain models within the Repository.
   * Expose data to the UI layer exclusively through the Repository.

## Decision Logic: Caching Strategy Selection
Evaluate the data requirements to select the optimal caching strategy:

* **Is the data small, simple key-value pairs (e.g., user preferences, theme settings)?**
  * **Yes:** Use `shared_preferences`.
* **Is the data a large, structured dataset requiring fast inserts, updates, and complex queries?**
  * **Yes:** Use On-device databases (Relational: `sqflite`, `drift` | Non-relational: `hive_ce`, `isar_community`).
* **Is the data composed of raw files or blobs where `shared_preferences` is insufficient?**
  * **Yes:** Use the device's File system.
* **Is the data primarily network images?**
  * **Yes:** Use the `cached_network_image` package to store images on the file system.
* **Is the data strictly lightweight API responses?**
  * **Yes:** Implement a Remote Caching system specifically for API responses.

## Best Practices
* Enforce the data layer as the *only* place where application data is updated.
* Make Service instances private members of Repositories to prevent the UI layer from bypassing the repository and calling a service directly.
* Transform raw API/DB models into domain models within the Repository. Domain models must contain only the information needed by the rest of the app.
* Use an `id` as the primary key for database tables to optimize query and update performance.
* Ensure the database connection is open before executing any read/write requests in the Repository.
* Handle exceptions within the Repository and return standardized wrapper objects (e.g., `Result.ok`, `Result.error`) to the UI layer to encapsulate success and failure states.

## Examples

### Gold Standard: Database Service Implementation
Create a dedicated service for database operations using `sqflite`.

**File:** `lib/data/services/database_service.dart`
```dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  Database? _database;
  static const String _tableName = 'todos';

  Future<void> open() async {
    if (_database != null && _database!.isOpen) return;
    
    final dbPath = await getDatabasesPath();
    _database = await openDatabase(
      join(dbPath, 'app_database.db'),
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE $_tableName(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, is_completed INTEGER)',
        );
      },
    );
  }

  bool isOpen() => _database != null && _database!.isOpen;

  Future<int> insertTodo(Map<String, dynamic> todoMap) async {
    return await _database!.insert(
      _tableName,
      todoMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> fetchAllTodos() async {
    return await _database!.query(_tableName);
  }
}
```

### Gold Standard: Repository Implementation
Create a repository that acts as the single source of truth, utilizing the private database service and transforming raw maps into domain models.

**File:** `lib/data/repositories/todo_repository.dart`
```dart
import '../services/database_service.dart';
import '../../domain/models/todo.dart';
import '../../domain/models/result.dart';

class TodoRepository {
  TodoRepository({
    required DatabaseService databaseService,
  }) : _databaseService = databaseService;

  final DatabaseService _databaseService;

  Future<Result<List<Todo>>> fetchTodos() async {
    try {
      if (!_databaseService.isOpen()) {
        await _databaseService.open();
      }
      
      final rawData = await _databaseService.fetchAllTodos();
      
      // Transform raw database maps into Domain Models
      final todos = rawData.map((map) => Todo(
        id: map['id'] as int,
        title: map['title'] as String,
        isCompleted: (map['is_completed'] as int) == 1,
      )).toList();

      return Result.ok(todos);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<Todo>> createTodo(String title) async {
    try {
      if (!_databaseService.isOpen()) {
        await _databaseService.open();
      }

      final rawTodo = {
        'title': title,
        'is_completed': 0,
      };

      final id = await _databaseService.insertTodo(rawTodo);
      
      // Return the newly created Domain Model
      return Result.ok(Todo(id: id, title: title, isCompleted: false));
    } on Exception catch (e) {
      return Result.error(e);
    }
  }
}
```
