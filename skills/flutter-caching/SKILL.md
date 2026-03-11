---
name: "flutter-caching"
description: "Cache data in a Flutter app"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 17:44:40 GMT"

---
# Implementing-Caching-Strategies

## When to Use
*   The application requires offline-first capabilities to retain and display data without a network connection.
*   The application needs to prevent users from waiting for data to load upon every app launch.
*   The Android host application requires a pre-warmed `FlutterEngine` to eliminate UI initialization delays.
*   The application renders complex images or heavy widget trees that benefit from memory, raster, or file system caching.
*   The application needs to persist user session state (e.g., navigation stacks, scroll positions) across restarts.

## Instructions

**Interaction Rule:** Evaluate the current project context for [data size, persistence requirements, platform targets]. If missing, ask the user for clarification before proceeding with implementation.

1.  **Determine the Caching Scope:** Identify whether the cache should be in-memory (ephemeral) or persistent (survives app restarts).
2.  **Select the Storage Mechanism:** Use the Decision Logic below to pick the appropriate package or technique.
3.  **Implement the Three-Step Cache Operation:** 
    *   Check if the cache contains the desired data (Cache Hit).
    *   If empty (Cache Miss), load the data from the remote source.
    *   Return the value and update the cache.
4.  **Implement Synchronization:** If using an offline-first approach, create a background synchronization task to push local changes to the remote server when connectivity is restored.
5.  **Optimize UI Caching:** Use `const` constructors for leaf widgets and avoid overriding `operator ==`.

## Decision Logic

Evaluate the data type and requirements to select the correct caching strategy:

*   **Is the data small, simple key-value pairs (e.g., user preferences)?**
    *   Yes -> Use `shared_preferences`.
*   **Is the data large, structured, or relational?**
    *   Yes -> Use an On-device database (e.g., `sqflite`, `drift`, `hive`, `isar`).
*   **Is the data raw files or blobs (e.g., downloaded PDFs)?**
    *   Yes -> Use `path_provider` to store in the Documents or Temporary directory.
*   **Are you caching network images?**
    *   Yes -> Use `cached_network_image` to handle file-system image caching automatically.
*   **Are you embedding Flutter into an existing Android app?**
    *   Yes -> Use `FlutterEngineCache` to pre-warm and cache the engine.

## Best Practices

*   **Enforce the Single Source of Truth:** Use the Repository pattern to combine local and remote data sources. The UI should only interact with the Repository.
*   **Prevent SQL Injection:** When using SQLite, always use `whereArgs` to pass arguments to a `where` statement. Never use string interpolation for SQL queries.
*   **Avoid `operator ==` Overrides on Widgets:** Rely on caching widgets via `const` constructors. Overriding `operator ==` on Widgets leads to O(N²) performance degradation during the build phase.
*   **Manage Image Cache Memory:** Raster cache entries are expensive to construct and consume significant GPU memory. Cache images only when absolutely necessary. If manually managing `ImageCache`, monitor and adjust `maxByteSize` to prevent memory bloat.
*   **Use Explicit Scroll Caching:** When caching scroll extents in viewports, use the explicit `ScrollCacheExtent.pixels(value)` or `ScrollCacheExtent.viewport(value)` rather than the deprecated `cacheExtent` double.
*   **Handle Background Sync Safely:** Only perform background synchronization tasks when the network is available and the device is not running low on battery.

## Examples

### Gold Standard: Three-Step Offline-First Repository
This example demonstrates the standard Check -> Load -> Return caching pattern using a local database as the fallback/cache.

```dart
// lib/repositories/user_profile_repository.dart
import 'dart:async';
import '../services/api_client_service.dart';
import '../services/database_service.dart';
import '../models/user_profile.dart';

class UserProfileRepository {
  final ApiClientService _apiClient;
  final DatabaseService _databaseService;

  UserProfileRepository(this._apiClient, this._databaseService);

  /// Implements the 3-step cache operation using a Stream
  Stream<UserProfile> getUserProfile() async* {
    // Step 1: Check cache (Local Database)
    final localProfile = await _databaseService.fetchUserProfile();
    
    if (localProfile != null) {
      // Cache Hit: Yield local data immediately for fast UI rendering
      yield localProfile;
    }

    try {
      // Step 2: Load data from remote source
      final remoteProfile = await _apiClient.getUserProfile();
      
      // Step 3: Update cache and return new value
      await _databaseService.updateUserProfile(remoteProfile);
      yield remoteProfile;
    } catch (e) {
      // On Cache Miss + Network Failure, throw if no local data exists
      if (localProfile == null) {
        throw Exception('User profile not found locally and network request failed.');
      }
    }
  }
}
```

### Gold Standard: SQLite Local Caching
This example demonstrates safe local caching using SQLite, adhering to SQL injection prevention best practices.

```dart
// lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/dog.dart';

class DatabaseService {
  late Database _database;

  Future<void> init() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'app_cache.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE dogs(id INTEGER PRIMARY KEY, name TEXT, age INTEGER)',
        );
      },
      version: 1,
    );
  }

  Future<void> cacheDog(Dog dog) async {
    await _database.insert(
      'dogs',
      dog.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCachedDog(Dog dog) async {
    await _database.update(
      'dogs',
      dog.toMap(),
      where: 'id = ?', // BEST PRACTICE: Use whereArgs to prevent SQL injection
      whereArgs: [dog.id],
    );
  }
}
```

### Gold Standard: Android FlutterEngine Caching
This example demonstrates how to pre-warm and cache a `FlutterEngine` in an Android host application to eliminate initialization latency.

```kotlin
// android/app/src/main/kotlin/com/example/MyApplication.kt
package com.example.hostapp

import android.app.Application
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

class MyApplication : Application() {
  lateinit var flutterEngine : FlutterEngine

  override fun onCreate() {
    super.onCreate()

    // Instantiate a FlutterEngine.
    flutterEngine = FlutterEngine(this)

    // Configure an initial route.
    flutterEngine.navigationChannel.setInitialRoute("/cached_route");

    // Start executing Dart code to pre-warm the FlutterEngine.
    flutterEngine.dartExecutor.executeDartEntrypoint(
      DartExecutor.DartEntrypoint.createDefault()
    )

    // Cache the FlutterEngine to be used by FlutterActivity or FlutterFragment.
    FlutterEngineCache
      .getInstance()
      .put("my_cached_engine_id", flutterEngine)
  }
}
```
