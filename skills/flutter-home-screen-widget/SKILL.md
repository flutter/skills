---
name: "flutter-home-screen-widget"
description: "Adding a Home Screen widget to your Flutter App"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 18:16:18 GMT"

---
# Implementing-Flutter-Home-Screen-Widgets

## When to Use
* The agent needs to display app data directly on the user's device home screen without opening the app.
* The project requires sharing data, custom fonts, or rendered UI components between a Flutter application and native iOS (SwiftUI) or Android (XML/Kotlin) widgets.
* The user requests integration of the `home_widget` package to facilitate communication between Flutter and native home screen widgets.

## Decision Logic
Evaluate the required widget features and target platforms to determine the implementation path:

* **Target Platform:**
  * **iOS:** Create a Widget Extension target in Xcode -> Configure App Groups for both targets -> Read data using `UserDefaults` -> Build UI with SwiftUI.
  * **Android:** Create an App Widget in Android Studio -> Configure `AppWidgetProvider` -> Read data using `SharedPreferences` -> Build UI with XML.
* **Content Type:**
  * **Simple Text/Data:** Pass data via `HomeWidget.saveWidgetData` in Dart and read natively.
  * **Custom Fonts:** (iOS only) Register the Flutter asset font URL in SwiftUI using `CTFontManagerRegisterFontsForURL`.
  * **Complex UI/Charts:** Render the Flutter widget to an image using `HomeWidget.renderFlutterWidget` -> Save to a shared container -> Load the image file natively.

## Instructions

**Interaction Rule:** Evaluate the current project context (`pubspec.yaml`, `ios/Runner.xcodeproj`, `android/app/src/main/AndroidManifest.xml`). If the `home_widget` package is missing, or if the iOS App Group ID / Android Widget Class Name is undefined, ask the user for clarification before proceeding with implementation.

**Plan:**
1. Define the shared data schema.
2. Configure native widget targets and shared storage containers.
3. Implement Dart logic to push data and trigger widget updates.
4. Implement native UI to consume and display the shared data.

**Execute:**
1. Add `home_widget` to `pubspec.yaml`.
2. **iOS Setup:** Open `ios/Runner.xcworkspace`. Add a "Widget Extension" target. Enable "App Groups" capability for both the Runner and the Widget Extension. Ensure the App Group ID is identical.
3. **Android Setup:** Add an `AppWidgetProvider` class and corresponding XML layout in `android/app/src/main/res/layout/`. Register the receiver in `AndroidManifest.xml`.
4. **Dart Implementation:** Use `HomeWidget.setAppGroupId()` during initialization. Use `HomeWidget.saveWidgetData()` to write key-value pairs, and `HomeWidget.updateWidget()` to notify the OS.
5. **Native Implementation:** Read the saved keys using `UserDefaults(suiteName:)` (iOS) or `HomeWidgetPlugin.getData(context)` (Android).

## Best Practices
* Prefix the iOS widget bundle identifier with the parent app's bundle identifier.
* Always provide fallback values in native code when reading from `UserDefaults` or `SharedPreferences` to prevent crashes on initial load.
* Use a `GlobalKey` to capture the exact logical size and pixel ratio when rendering Flutter widgets to images.
* Store rendered images in a shared container accessible by both the app and the widget extension.
* Call `HomeWidget.updateWidget()` immediately after saving new data or rendering a new image in Dart.

## Examples

### Dart: Updating Data and Rendering a Widget to Image
`/lib/home_screen.dart`
```dart
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

const String appGroupId = 'group.com.mydomain.newsapp';
const String iOSWidgetName = 'NewsWidgets';
const String androidWidgetName = 'NewsWidget';

class WidgetUpdater {
  static Future<void> updateHeadline(String title, String description) async {
    await HomeWidget.setAppGroupId(appGroupId);
    await HomeWidget.saveWidgetData<String>('headline_title', title);
    await HomeWidget.saveWidgetData<String>('headline_description', description);
    
    await HomeWidget.updateWidget(
      iOSName: iOSWidgetName,
      androidName: androidWidgetName,
    );
  }

  static Future<void> renderChartToWidget(GlobalKey chartKey) async {
    if (chartKey.currentContext == null) return;
    
    await HomeWidget.setAppGroupId(appGroupId);
    
    // Render the Flutter widget to an image and save to shared storage
    final path = await HomeWidget.renderFlutterWidget(
      const LineChart(),
      fileName: 'chart_screenshot',
      key: 'chart_image_path',
      logicalSize: chartKey.currentContext!.size,
      pixelRatio: MediaQuery.of(chartKey.currentContext!).devicePixelRatio,
    );
    
    await HomeWidget.updateWidget(
      iOSName: iOSWidgetName,
      androidName: androidWidgetName,
    );
  }
}
```

### iOS: Reading Data and Displaying the Image (SwiftUI)
`/ios/NewsWidgets/NewsWidgets.swift`
```swift
import WidgetKit
import SwiftUI

struct NewsArticleEntry: TimelineEntry {
    let date: Date
    let title: String
    let description: String
    let imagePath: String
    let displaySize: CGSize
}

struct Provider: TimelineProvider {
    func getSnapshot(in context: Context, completion: @escaping (NewsArticleEntry) -> ()) {
        let userDefaults = UserDefaults(suiteName: "group.com.mydomain.newsapp")
        let title = userDefaults?.string(forKey: "headline_title") ?? "No Title"
        let description = userDefaults?.string(forKey: "headline_description") ?? "No Description"
        let imagePath = userDefaults?.string(forKey: "chart_image_path") ?? ""
        
        let entry = NewsArticleEntry(date: Date(), title: title, description: description, imagePath: imagePath, displaySize: context.displaySize)
        completion(entry)
    }
    // ... placeholder and getTimeline omitted for brevity
}

struct NewsWidgetsEntryView : View {
    var entry: Provider.Entry

    var chartImage: some View {
        if let uiImage = UIImage(contentsOfFile: entry.imagePath) {
            return AnyView(Image(uiImage: uiImage)
                .resizable()
                .scaledToFit())
        }
        return AnyView(EmptyView())
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(entry.title).font(.headline)
            Text(entry.description).font(.subheadline)
            chartImage
        }
        .padding()
    }
}
```

### Android: Reading Data and Displaying the Image (Kotlin)
`/android/app/src/main/java/com/mydomain/newsapp/NewsWidget.kt`
```kotlin
package com.mydomain.newsapp

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.io.File

class NewsWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.news_widget).apply {
                
                val title = widgetData.getString("headline_title", "No Title")
                setTextViewText(R.id.headline_title, title)

                val description = widgetData.getString("headline_description", "No Description")
                setTextViewText(R.id.headline_description, description)

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
