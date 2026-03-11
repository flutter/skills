---
name: "flutter-databases"
description: "Work with databases in a Flutter app"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 18:10:03 GMT"

---
# Architecting-Flutter-Data-Layers

## When to Use
*   Designing or implementing the data layer (Model in MVVM) for a Flutter application.
*   Establishing a single source of truth for application data.
*   Separating business logic into Repositories and Services.
*   Implementing local data persistence using SQLite (`sqflite`).
*   Selecting and implementing a caching strategy (e.g., `shared_preferences`, file system, or on-device databases).
*   Building offline-first applications that require data synchronization between local and remote sources.

## Instructions

**Interaction Rule:** Evaluate the current project context for existing data layer patterns, state management choices, and persistence requirements. If the required persistence strategy or API structure is missing or ambiguous, ask the user for clarification before proceeding with implementation.

1.  **Plan the Data Layer Architecture:**
    *   Identify the domain models required by the UI.
    *   Identify the external data sources (REST APIs, device sensors) and define corresponding Service classes.
    *   Identify local storage requirements and select the appropriate persistence strategy (see Decision Logic below).
    *   Map out the Repositories needed to orchestrate between Services and local storage, ensuring they output clean Domain Models.

2.  **Decision Logic: Selecting a Caching/Persistence Strategy:**
    *   *Condition:* Is the data small, simple key-value pairs (e.g., user preferences, theme settings)?
        *   *Action:* Use `shared_preferences`.
    *   *Condition:* Is the data a large, structured, relational dataset requiring fast inserts, updates, and queries?
        *   *Action:* Use an on-device relational database like `sqflite` (with the `path` package) or `drift`.
    *   *Condition:* Is the data a large dataset but non-relational?
        *   *Action:* Use a NoSQL local database like `hive_ce` or `isar_community`.
    *   *Condition:* Are you caching network images?
        *   *Action:* Use the `cached_network_image` package to store images on the file system.
    *   *Condition:* Are you caching raw files or blobs where `shared_preferences` is insufficient?
        *   *Action:* Use the device's file system directly.

3.  **Execute Service Implementation:**
    *   Create stateless Service classes to wrap external APIs or database plugins.
    *   Ensure Services return raw data models (API models or Data Transfer Objects).

4.  **Execute Repository Implementation:**
    *   Create Repository classes for each distinct data type.
    *   Inject required Services into the Repository as *private* members.
    *   Implement data fetching, caching, and synchronization logic within the Repository.
    *   Transform raw API/Database models into Domain Models before returning them to the UI layer.

## Best Practices

*   **Enforce the Single Source of Truth:** Never mutate application data in the UI layer. All data mutations must occur within the Repository.
*   **Keep Services Stateless:** Do not store application state in Service classes. Their only job is to wrap external APIs or database transactions.
*   **Hide Services from the UI:** Always make Service instances private members of the Repository (e.g., `final ApiClient _apiClient;`). The UI layer must never bypass the Repository to call a Service directly.
*   **Separate API Models from Domain Models:** Use API models for raw JSON serialization. Transform these into Domain Models in the Repository so the UI only receives the data it actually needs.
*   **Use Result Wrappers for Error Handling:** Wrap asynchronous Repository returns in a `Result` type (e.g., `Future<Result<DomainModel>>`) to safely pass data and errors to the view model without relying on `try/catch` blocks in the UI layer.
*   **Optimize Database Queries:** Always use an `id` as the primary key for SQLite tables to improve query and update times. Ensure the database is open before executing requests.

## Examples

### Example 1: SQLite Database Service
Implement a dedicated service to handle SQLite operations using `sqflite`.

```dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static const String _dbName = 'app_database.db';
  static const String _tableName = 'todos';
  
  Database? _database;

  Future<void> open() async {
    if (_database != null && _database!.isOpen) return;
    
    final dbPath = await getDatabasesPath();
    _database = await openDatabase(
      join(dbPath, _dbName),
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE $_tableName(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, isCompleted INTEGER)',
        );
      },
    );
  }

  bool isOpen() => _database != null && _database!.isOpen;

  Future<List<Map<String, dynamic>>> getAllTodos() async {
    return await _database!.query(_tableName);
  }

  Future<int> insertTodo(Map<String, dynamic> todoMap) async {
    return await _database!.insert(
      _tableName, 
      todoMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteTodo(int id) async {
    return await _database!.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
```

### Example 2: Repository with Offline-First Logic
Implement a Repository that uses the `DatabaseService` as the source of truth, transforming raw maps into Domain Models.

```dart
import 'package:my_app/data/services/database_service.dart';
import 'package:my_app/domain/models/todo.dart';
import 'package:my_app/domain/utils/result.dart'; // Assume a custom Result<T> class exists

class TodoRepository {
  TodoRepository({
    required DatabaseService databaseService,
  }) : _dbService = databaseService;

  final DatabaseService _dbService;

  /// Fetches Todos from the local database, ensuring it is open first.
  Future<Result<List<Todo>>> fetchTodos() async {
    try {
      if (!_dbService.isOpen()) {
        await _dbService.open();
      }
      
      final rawData = await _dbService.getAllTodos();
      
      // Transform raw database maps into Domain Models
      final todos = rawData.map((map) => Todo(
        id: map['id'] as int,
        title: map['title'] as String,
        isCompleted: (map['isCompleted'] as int) == 1,
      )).toList();

      return Result.ok(todos);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  /// Creates a new Todo in the local database.
  Future<Result<Todo>> createTodo(String title) async {
    try {
      if (!_dbService.isOpen()) {
        await _dbService.open();
      }

      final todoMap = {
        'title': title,
        'isCompleted': 0,
      };

      final id = await _dbService.insertTodo(todoMap);
      
      return Result.ok(Todo(
        id: id,
        title: title,
        isCompleted: false,
      ));
    } on Exception catch (e) {
      return Result.error(e);
    }
  }
}
```
