---
name: "flutter-http-and-json"
description: "Make HTTP requests and encode / decode JSON in a Flutter app"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 18:09:20 GMT"

---
# Implementing-Networking-And-JSON-Parsing

## When to Use
* The agent needs to fetch, send, update, or delete data over the internet using HTTP REST APIs.
* The application requires parsing JSON responses into strongly typed Dart objects.
* The application needs to perform heavy JSON decoding without blocking the main UI thread (preventing jank).
* The agent is integrating AI models and needs to enforce and parse structured JSON output.

## Instructions

**Interaction Rule:** Evaluate the current project context for `http` package dependencies, target platforms (Android/macOS permissions), and API endpoint details. If the API schema, endpoint URL, or authentication requirement is missing, ask the user for clarification before proceeding with implementation.

**Workflow:**
1. **Plan:** Determine the required HTTP method (GET, POST, PUT, DELETE). Identify the JSON structure and select the appropriate serialization and parsing strategy.
2. **Configure:** Add the `http` package to `pubspec.yaml`. Apply necessary platform-specific network permissions.
3. **Model:** Create Dart model classes with `fromJson` and `toJson` methods.
4. **Implement:** Write the API call using `Uri.https` and `async`/`await`.
5. **Handle Errors:** Check HTTP status codes and throw explicit exceptions for failures.
6. **Parse:** Decode the JSON response, utilizing background isolates for large payloads.

## Decision Logic: JSON Parsing Strategy

Follow this decision tree to determine the correct JSON parsing implementation:

* **Is the JSON payload large (e.g., lists of hundreds of items) or complex?**
  * **Yes:** Use `compute()` from `package:flutter/foundation.dart` to parse the JSON in a background Isolate.
  * **No:** Proceed to the next check.
* **Is the project medium-to-large with many complex data models?**
  * **Yes:** Use code generation libraries (`json_serializable` and `build_runner`).
  * **No:** Use manual serialization with `dart:convert` (`jsonDecode` and `jsonEncode`) and pattern matching or factory constructors.

## Best Practices

* **Use Safe URI Construction:** Always use `Uri.https` or `Uri.http` to construct URLs safely. Never use string concatenation, as it fails to handle encoding and formatting reliably.
* **Enforce HTTPS:** Always use HTTPS. Insecure HTTP (cleartext) connections are disabled by default on iOS 9+ and Android API 28+.
* **Declare Platform Permissions:** 
  * For Android, add `<uses-permission android:name="android.permission.INTERNET" />` to `android/app/src/main/AndroidManifest.xml`.
  * For macOS, add `<key>com.apple.security.network.client</key><true/>` to `macos/Runner/DebugProfile.entitlements` and `Release.entitlements`.
* **Handle Status Codes Explicitly:** Always check `response.statusCode`. A status code of 200 (or 201 for creation) indicates success. Throw an exception for other codes. Do not return `null` on error, as it breaks `FutureBuilder` error handling.
* **Cache Futures in State:** Never call HTTP fetching methods directly inside a `build()` method. Call them in `initState()` and assign them to a state variable (e.g., `late Future<MyModel> _futureModel;`) to prevent redundant network requests on UI rebuilds.
* **Specify AI JSON Schemas:** When working with LLMs, explicitly pass the JSON schema in the system prompt and set the response MIME type to `application/json` to ensure reliable, parsable output.

## Examples

### Example 1: Data Model with Manual Serialization
Define a robust data model using factory constructors for JSON deserialization.

```dart
import 'dart:convert';

class ArticleSummary {
  final int id;
  final String title;
  final String extract;

  const ArticleSummary({
    required this.id,
    required this.title,
    required this.extract,
  });

  factory ArticleSummary.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': int id,
        'title': String title,
        'extract': String extract,
      } =>
        ArticleSummary(
          id: id,
          title: title,
          extract: extract,
        ),
      _ => throw const FormatException('Failed to parse ArticleSummary.'),
    };
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'extract': extract,
      };
}
```

### Example 2: Background JSON Parsing (GET Request)
Use `compute` to parse large JSON payloads in a background isolate to prevent UI jank.

```dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// Top-level function required for compute()
List<ArticleSummary> parseSummaries(String responseBody) {
  final parsed = (jsonDecode(responseBody) as List<Object?>)
      .cast<Map<String, dynamic>>();

  return parsed.map<ArticleSummary>(ArticleSummary.fromJson).toList();
}

Future<List<ArticleSummary>> fetchSummaries(http.Client client) async {
  final uri = Uri.https('api.example.com', '/v1/summaries');
  final response = await client.get(uri);

  if (response.statusCode == 200) {
    // Run the parsing logic in a background isolate
    return compute(parseSummaries, response.body);
  } else {
    throw Exception('Failed to load summaries: ${response.statusCode}');
  }
}
```

### Example 3: Sending Data (POST Request)
Encode Dart objects to JSON and send them via a POST request.

```dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<ArticleSummary> createSummary(String title, String extract) async {
  final uri = Uri.https('api.example.com', '/v1/summaries');
  
  final response = await http.post(
    uri,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'title': title,
      'extract': extract,
    }),
  );

  if (response.statusCode == 201) {
    return ArticleSummary.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  } else {
    throw Exception('Failed to create summary: ${response.statusCode}');
  }
}
```

### Example 4: Handling State with FutureBuilder
Consume the Future in the UI layer safely.

```dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  late Future<List<ArticleSummary>> _futureSummaries;

  @override
  void initState() {
    super.initState();
    // Initialize the future exactly once
    _futureSummaries = fetchSummaries(http.Client());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Summaries')),
      body: FutureBuilder<List<ArticleSummary>>(
        future: _futureSummaries,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final summaries = snapshot.data!;
            return ListView.builder(
              itemCount: summaries.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(summaries[index].title),
                  subtitle: Text(summaries[index].extract),
                );
              },
            );
          } else {
            return const Center(child: Text('No data available.'));
          }
        },
      ),
    );
  }
}
```
