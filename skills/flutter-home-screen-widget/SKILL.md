---
name: "flutter-home-screen-widget"
description: "Adding a Home Screen widget to your Flutter App"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 17:50:22 GMT"

---
# Implementing-Flutter-Home-Screen-Widgets

## Goal
This skill enables an AI agent to build and integrate native home screen widgets (iOS and Android) into a Flutter application using the `home_widget` package. It facilitates data sharing, custom font utilization, and rendering complex Flutter UI components as images for native display.

## When to Use
* The user requests a home screen widget for an existing or new Flutter application.
* The project requires surfacing app data directly on the iOS (SwiftUI) or Android (XML) home screen.
* The implementation requires sharing complex Flutter UI (e.g., charts, custom painters) to a native widget by rendering it as an image.
* The user needs to synchronize data between Dart and native local storage (`UserDefaults` for iOS, `SharedPreferences` for Android).

## Decision Logic
Evaluate the required widget complexity to determine the implementation path:
* **If displaying simple text/data:** Pass key-value pairs from Dart using `HomeWidget.saveWidgetData` and reconstruct the UI natively using SwiftUI (iOS) or XML/Kotlin (Android).
* **If using custom Flutter fonts on iOS:** Resolve the font path from the Flutter asset bundle in Swift and register it using `CTFontManagerRegisterFontsForURL`. (Note: Not supported on Android).
* **If displaying complex Flutter UI (e.g., Charts):** Render the Flutter widget to a PNG using `HomeWidget.renderFlutterWidget`, save the file path to local storage, and load the image natively in SwiftUI (`UIImage`) or Kotlin (`BitmapFactory`).

## Instructions

**Interaction Rule:** Evaluate the current project context for target platforms (iOS, Android, or both), the required App Group ID (for iOS), and the specific data/UI to be shared. If missing or ambiguous, ask the user for clarification before proceeding with implementation.

1. **Install Dependencies:** Add `home_widget` to the `pubspec.yaml`.
2. **Configure iOS Native Target:**
   * Open `ios/Runner.xcworkspace`.
   * Add a new **Widget Extension** target.
   * Assign an App Group to both the Runner and the Widget Extension targets to enable `UserDefaults` sharing.
3. **Configure Android Native Target:**
   * Create an `AppWidgetProvider` class in `android/app/src/main/java/...`.
   * Define the widget layout in `android/app/src/main/res/layout/`.
   * Register the receiver in `android/app/src/main/AndroidManifest.xml`.
4. **Implement Dart Synchronization:**
   * Use `HomeWidget.setAppGroupId()` to initialize the iOS App Group.
   * Use `HomeWidget.saveWidgetData()` to write data.
   * Use `HomeWidget.updateWidget()` to trigger native UI refreshes.
5. **Implement Native Consumers:**
   * **iOS:** Read from `UserDefaults(suiteName: "<APP_GROUP>")` in the `TimelineProvider` and render via SwiftUI.
   * **Android:** Read from `HomeWidgetPlugin.getData(context)` in `onUpdate` and render via `RemoteViews`.

## Best Practices
* Always prefix the iOS widget bundle identifier with the parent app's bundle identifier.
* Define the App Group ID as a constant in Dart and ensure it exactly matches the Xcode capability configuration.
* Handle missing data gracefully in native code by providing fallback UI or default text (e.g., `?? "Default Text"`).
* Render complex Flutter widgets off-screen using a `GlobalKey` and `HomeWidget.renderFlutterWidget` rather than attempting to rebuild intricate layouts in native code.
* Use forward slashes (`/`) for all file paths in documentation and code comments.

## Examples

### Dart: Synchronizing Data and Rendering Widgets
```dart
// lib/widget_sync_service.dart
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

const String appGroupId = 'group.com.example.app';
const String iOSWidgetName = 'NewsWidgets';
const String androidWidgetName = 'NewsWidget';

Future<void> updateHomeScreenWidget(String title, String description, GlobalKey chartKey) async {
  // 1. Initialize App Group
  await HomeWidget.setAppGroupId(appGroupId);

  // 2. Save basic text data
  await HomeWidget.saveWidgetData<String>('headline_title', title);
  await HomeWidget.saveWidgetData<String>('headline_description', description);

  // 3. Render complex Flutter widget to image
  if (chartKey.currentContext != null) {
    final imagePath = await HomeWidget.renderFlutterWidget(
      const LineChart(), // Your complex widget
      fileName: 'chart_screenshot',
      key: 'chart_image_path',
      logicalSize: chartKey.currentContext!.size,
      pixelRatio: MediaQuery.of(chartKey.currentContext!).devicePixelRatio,
    );
  }

  // 4. Trigger native update
  await HomeWidget.updateWidget(
    iOSName: iOSWidgetName,
    androidName: androidWidgetName,
  );
}
```

### iOS (Swift): Consuming Data and Images
```swift
// ios/NewsWidgets/NewsWidgets.swift
import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func getSnapshot(in context: Context, completion: @escaping (NewsArticleEntry) -> ()) {
        let userDefaults = UserDefaults(suiteName: "group.com.example.app")
        let title = userDefaults?.string(forKey: "headline_title") ?? "No Title"
        let imagePath = userDefaults?.string(forKey: "chart_image_path") ?? ""
        
        let entry = NewsArticleEntry(date: Date(), title: title, imagePath: imagePath, displaySize: context.displaySize)
        completion(entry)
    }
    // ... placeholder and getTimeline omitted for brevity
}

struct NewsWidgetsEntryView : View {
    var entry: Provider.Entry

    var ChartImage: some View {
        if let uiImage = UIImage(contentsOfFile: entry.imagePath) {
            return AnyView(Image(uiImage: uiImage).resizable().scaledToFit())
        }
        return AnyView(EmptyView())
    }

    var body: some View {
        VStack {
            Text(entry.title).font(.headline)
            ChartImage
        }
    }
}
```

### Android (Kotlin): Consuming Data and Images
```kotlin
// android/app/src/main/java/com/example/app/NewsWidget.kt
package com.example.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.io.File

class NewsWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.news_widget).apply {
                
                // Set Text
                val title = widgetData.getString("headline_title", "No Title")
                setTextViewText(R.id.headline_title, title)

                // Set Image
                val imagePath = widgetData.getString("chart_image_path", null)
                if (imagePath != null) {
                    val imageFile = File(imagePath)
                    if (imageFile.exists()) {
                        val bitmap = BitmapFactory.decodeFile(imageFile.absolutePath)
                        setImageViewBitmap(R.id.widget_image, bitmap)
                    }
                }
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
```
