---
name: "flutter-http-and-json"
description: "Make HTTP requests and encode / decode JSON in a Flutter app"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 17:43:14 GMT"

---
# Implementing-Networking-And-JSON-Parsing

## When to Use
* The agent needs to fetch, send, update, or delete data over the internet using HTTP.
* The application requires parsing, serializing, or deserializing JSON data.
* The application integrates with an AI model and requires reliable, structured JSON output.
* The application needs to process large JSON payloads without causing UI jank (frame drops).

## Instructions
**Interaction Rule:** Evaluate the current project context for [target platforms (Android/macOS), expected JSON payload size, and API endpoint security (HTTPS)]. If missing, ask the user for clarification before proceeding with implementation.

1. **Configure Platform Permissions:** Ensure the target platforms have the necessary network permissions configured in their respective native files.
2. **Add Dependencies:** Add the `http` package to the `pubspec.yaml` file. If using code generation, add `json_annotation`, `build_runner`, and `json_serializable`.
3. **Define the Data Model:** Create Dart classes representing the data structure. Implement `fromJson` factory constructors and `toJson` methods.
4. **Implement Network Requests:** Create a dedicated Model class (following the MVVM pattern) to handle HTTP operations using `async` and `await`.
5. **Parse the Response:** Decode the JSON response. Delegate parsing to a background isolate if the payload is large.
6. **Handle State in UI:** Use `FutureBuilder` or a state management solution to display loading spinners, error messages, or the parsed data.

## Decision Logic

### JSON Serialization Strategy
* **If the project is small or a prototype:** Use manual serialization with `dart:convert` (`jsonDecode` / `jsonEncode`).
* **If the project is medium to large:** Use automated code generation with the `json_serializable` package to prevent runtime errors and typos.

### JSON Parsing Execution
* **If the JSON payload is small:** Parse synchronously in the main isolate.
* **If the JSON payload is large (takes > 16ms to parse):** Move the parsing logic to a background isolate using the `compute()` function to avoid UI jank.

### Network Protocol Security
* **If connecting to a standard API:** Always use HTTPS. Insecure HTTP connections are disabled by default on iOS and Android.
* **If cleartext HTTP is strictly required (e.g., local debugging):** Explicitly configure `network_security_config.xml` for Android and `NSAppTransportSecurity` in `Info.plist` for iOS.

## Best Practices
* **Use Safe URL Construction:** Always use `Uri.https` or `Uri.http` constructors to safely build URLs. Never use string concatenation, as it fails to handle encoding and formatting reliably.
* **Enforce Platform Permissions:** 
  * For Android, inject `<uses-permission android:name="android.permission.INTERNET" />` into `android/app/src/main/AndroidManifest.xml`.
  * For macOS, inject `<key>com.apple.security.network.client</key><true/>` into `macos/Runner/DebugProfile.entitlements` and `Release.entitlements`.
* **Handle HTTP Errors Explicitly:** Always check `response.statusCode`. Treat `200` (OK) or `201` (Created) as success. Throw explicit exceptions for all other status codes. Do not return `null` on errors.
* **Separate Concerns (MVVM):** Isolate network requests and JSON parsing inside a Model class. Do not place `http.get` calls directly inside UI widgets or `build()` methods.
* **Enforce AI JSON Schemas:** When requesting JSON from an AI model, pass a strict JSON schema in the system prompt and initialize the model instance with the expected `responseMimeType` to guarantee parsable output.

## Examples

### Gold Standard: HTTP GET with Background Parsing (MVVM Model)
This example demonstrates fetching a large list of photos, handling errors, and parsing the JSON in a background isolate to maintain 60fps UI performance.

```dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// 1. Define the Data Model
class Photo {
  final int id;
  final String title;
  final String url;

  const Photo({
    required this.id,
    required this.title,
    required this.url,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as int,
      title: json['title'] as String,
      url: json['url'] as String,
    );
  }
}

// 2. Define the Top-Level Parsing Function (Must be top-level for compute)
List<Photo> parsePhotos(String responseBody) {
  final parsed = (jsonDecode(responseBody) as List<Object?>)
      .cast<Map<String, Object?>>();

  return parsed.map<Photo>(Photo.fromJson).toList();
}

// 3. Define the Model (Data Layer)
class PhotoModel {
  final http.Client client;

  PhotoModel({required this.client});

  Future<List<Photo>> fetchPhotos() async {
    // Safely construct the URL
    final uri = Uri.https('jsonplaceholder.typicode.com', '/photos');
    
    final response = await client.get(uri);

    // Explicit error handling
    if (response.statusCode != 200) {
      throw Exception('Failed to load photos. Status code: ${response.statusCode}');
    }

    // Use compute to parse JSON in a background isolate
    return compute(parsePhotos, response.body);
  }
}
```

### Gold Standard: AI Structured JSON Output
This example demonstrates how to enforce and parse a strict JSON structure when communicating with an AI model.

```dart
import 'dart:convert';
import 'package:firebase_vertexai/firebase_vertexai.dart';

class CrosswordAiModel {
  late final GenerativeModel _model;

  // 1. Define the strict schema expected from the AI
  static final _crosswordSchema = Schema(
    SchemaType.object,
    properties: {
      'width': Schema(SchemaType.integer),
      'height': Schema(SchemaType.integer),
      'clues': Schema(
        SchemaType.array,
        items: Schema(
          SchemaType.object,
          properties: {
            'number': Schema(SchemaType.integer),
            'text': Schema(SchemaType.string),
          },
        ),
      ),
    },
  );

  CrosswordAiModel() {
    // 2. Initialize the model with the schema and MIME type
    _model = FirebaseAI.instance.generativeModel(
      model: 'gemini-2.5-pro',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _crosswordSchema,
      ),
    );
  }

  Future<Map<String, dynamic>> analyzeCrossword(String prompt) async {
    // 3. Reinforce the schema in the prompt
    final fullPrompt = '''
      $prompt
      
      Return the data strictly adhering to the following JSON schema:
      ${jsonEncode(_crosswordSchema.toJson())}
    ''';

    final content = [Content.text(fullPrompt)];
    final response = await _model.generateContent(content);

    if (response.text == null) {
      throw Exception('AI returned an empty response.');
    }

    // 4. Safely decode the guaranteed JSON response
    final jsonResponse = jsonDecode(response.text!) as Map<String, dynamic>;
    return jsonResponse;
  }
}
```
