---
name: "flutter-caching"
description: "Cache data in a Flutter app"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 18:10:44 GMT"

---
# Implementing-Flutter-Caching-And-Offline-First-Architecture

## When to Use
*   The application requires offline functionality or temporary data access without network connectivity.
*   The application needs to minimize Flutter initialization time on Android using `FlutterEngine` caching.
*   The UI suffers from jank or slow rendering, requiring widget, raster, or image caching optimizations.
*   Large datasets or binary files need to be persisted locally using SQLite or file system storage.
*   The application requires state restoration to persist user session aspects (navigation stacks, scroll positions) across app restarts.

## Instructions
1.  **Interaction Rule:** Evaluate the current project context for caching requirements (e.g., data size, persistence needs, platform targets, performance bottlenecks). If the required caching strategy or data lifecycle is missing or ambiguous, ask the user for clarification before proceeding with implementation.
2.  **Plan the Data Layer:** Determine the appropriate local caching mechanism based on the Decision Logic below.
3.  **Implement the Repository:** Create a repository class that acts as the single source of truth, combining remote API calls with local database/file reads.
4.  **Configure Engine Caching (Android):** If embedding Flutter into an existing Android app, pre-warm and cache the `FlutterEngine` to eliminate initialization delays.
5.  **Optimize UI Rendering:** Apply caching to expensive UI operations (e.g., `RepaintBoundary` for static complex views) and update deprecated scrolling cache extents to use `ScrollCacheExtent`.
6.  **Implement Synchronization:** Create background or user-triggered tasks to sync offline-written data with the remote server.

## Decision Logic: Caching Strategy Selection
Follow this decision tree to select the appropriate caching mechanism:

1.  **Is the goal to optimize Android app initialization?**
    *   Yes -> Use `FlutterEngineCache` to pre-warm and store the engine.
2.  **Is the goal to optimize UI rendering?**
    *   Yes -> Are you caching complex, static widget hierarchies?
        *   Yes -> Use `RepaintBoundary` (Raster caching).
        *   No -> Cache leaf widgets. *Do not* override `operator ==` as it degrades performance.
3.  **Is the goal to store application data?**
    *   Yes -> Does the data need to persist across app launches?
        *   No -> Use **In-memory caching** (variables, state management).
        *   Yes -> What is the size and structure of the data?
            *   Small, simple key-value pairs -> Use `shared_preferences`.
            *   Large binary data or files (e.g., images) -> Use **File system caching** (`path_provider`) or `cached_network_image`.
            *   Large, structured, or relational datasets -> Use **On-device databases** (SQLite, Drift, Isar).

## Best Practices

### Architecture & Offline-First
*   **Use a Single Source of Truth:** Implement repositories that handle the logic of fetching from the local cache first, then updating from the network.
*   **Use Streams for Reactive UI:** Return a `Stream` from the repository that first yields the local cached data (cache hit), performs the network request, updates the local cache, and then yields the fresh remote data.
*   **Flag Unsynchronized Data:** Add a `synchronized` boolean flag to local database models to track offline writes that need to be pushed to the server.

### Performance & UI Caching
*   **Avoid Excessive `saveLayer` Calls:** Do not use `Opacity`, `ShaderMask`, or `Clip.antiAliasWithSaveLayer` at the top of large widget trees. Apply them to individual leaf widgets to prevent expensive offscreen buffer allocations.
*   **Manage Image Cache Size:** Do not permanently increase `ImageCache.maxByteSize` to accommodate large images. Adjust your image loading logic to fit the cache size, or subclass `ImageCache` for custom eviction logic.
*   **Use Modern Scroll Caching:** Replace deprecated `cacheExtent` and `cacheExtentStyle` properties with `scrollCacheExtent` (e.g., `ScrollCacheExtent.pixels(500.0)` or `ScrollCacheExtent.viewport(0.5)`).
*   **Lazy Load Lists:** Always use lazy builder methods (e.g., `ListView.builder`) for large lists to ensure only visible portions are built and cached.

### Android Engine Caching
*   **Pre-warm the Engine:** Instantiate and execute the Dart entrypoint on a `FlutterEngine` in the Android `Application` class before the UI requires it.
*   **Manage Engine Lifecycle:** Remember that a cached `FlutterEngine` outlives the `FlutterActivity` or `FlutterFragment`. Explicitly destroy it with `FlutterEngine.destroy()` when it is no longer needed to free resources.

## Examples

### Example 1: Offline-First Repository using Streams and SQLite
This example demonstrates how to combine a local SQLite database and a remote API using a Stream to provide immediate cached data followed by fresh data.

```dart
// lib/src/data/repositories/user_profile_repository.dart
import 'dart:async';
import '../models/user_profile.dart';
import '../services/api_client_service.dart';
import '../services/database_service.dart';

class UserProfileRepository {
  final ApiClientService _apiClientService;
  final DatabaseService _databaseService;

  UserProfileRepository(this._apiClientService, this._databaseService);

  /// Returns a Stream that emits cached data first, then fresh API data.
  Stream<UserProfile> getUserProfile() async* {
    // 1. Fetch and emit the user profile from the local SQLite database
    final localProfile = await _databaseService.fetchUserProfile();
    if (localProfile != null) {
      yield localProfile;
    }

    // 2. Fetch fresh data from the API
    try {
      final remoteProfile = await _apiClientService.getUserProfile();
      
      // 3. Update the local cache with the new data
      await _databaseService.updateUserProfile(remoteProfile);
      
      // 4. Emit the fresh data
      yield remoteProfile;
    } catch (e) {
      // If network fails and we have no local data, throw an error.
      if (localProfile == null) {
        throw Exception('Failed to load profile and no local cache available.');
      }
      // Otherwise, silently fail and rely on the already emitted local cache.
    }
  }

  /// Offline-first write operation
  Future<void> updateUserProfile(UserProfile userProfile) async {
    // 1. Write to local cache immediately (Optimistic update)
    final profileToSave = userProfile.copyWith(synchronized: false);
    await _databaseService.updateUserProfile(profileToSave);

    // 2. Attempt to sync with the remote server
    try {
      await _apiClientService.putUserProfile(profileToSave);
      // 3. Mark as synchronized if successful
      await _databaseService.updateUserProfile(
        profileToSave.copyWith(synchronized: true),
      );
    } catch (e) {
      // Leave synchronized = false for a background sync task to pick up later
    }
  }
}
```

### Example 2: Pre-warming and Caching FlutterEngine (Android)
This example shows how to pre-warm a `FlutterEngine` to eliminate initialization latency when adding a Flutter Fragment to an Android app.

```kotlin
// android/app/src/main/kotlin/com/example/MyApplication.kt
package com.example.app

import android.app.Application
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

class MyApplication : Application() {
  lateinit var flutterEngine : FlutterEngine

  override fun onCreate() {
    super.onCreate()

    // 1. Instantiate a FlutterEngine.
    flutterEngine = FlutterEngine(this)

    // 2. Configure an initial route (must be done before executing entrypoint).
    flutterEngine.navigationChannel.setInitialRoute("/cached_route")

    // 3. Start executing Dart code to pre-warm the FlutterEngine.
    flutterEngine.dartExecutor.executeDartEntrypoint(
      DartExecutor.DartEntrypoint.createDefault()
    )

    // 4. Cache the FlutterEngine to be used by FlutterActivity or FlutterFragment.
    FlutterEngineCache
      .getInstance()
      .put("my_cached_engine_id", flutterEngine)
  }
}
```

```kotlin
// android/app/src/main/kotlin/com/example/MyActivity.kt
package com.example.app

import android.os.Bundle
import androidx.fragment.app.FragmentActivity
import io.flutter.embedding.android.FlutterFragment

class MyActivity : FragmentActivity() {
  companion object {
    private const val TAG_FLUTTER_FRAGMENT = "flutter_fragment"
  }

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    setContentView(R.layout.my_activity_layout)

    val fragmentManager = supportFragmentManager
    var flutterFragment = fragmentManager.findFragmentByTag(TAG_FLUTTER_FRAGMENT) as FlutterFragment?

    if (flutterFragment == null) {
      // Use the cached engine ID defined in MyApplication
      flutterFragment = FlutterFragment.withCachedEngine("my_cached_engine_id")
          .shouldAttachEngineToActivity(true)
          .build()

      fragmentManager
        .beginTransaction()
        .add(R.id.fragment_container, flutterFragment, TAG_FLUTTER_FRAGMENT)
        .commit()
    }
  }
}
```

### Example 3: Modern Scroll Caching
Update scrolling views to use the modern `ScrollCacheExtent` API to prevent breaking changes.

```dart
// lib/src/ui/views/cached_list_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class CachedListView extends StatelessWidget {
  final List<String> items;

  const CachedListView({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // Use ScrollCacheExtent instead of the deprecated cacheExtent double
      scrollCacheExtent: const ScrollCacheExtent.pixels(500.0),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(items[index]),
        );
      },
    );
  }
}
```
