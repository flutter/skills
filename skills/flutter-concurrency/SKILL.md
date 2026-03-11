---
name: "flutter-concurrency"
description: "Execute long-running tasks in a background thread in Flutter"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 17:49:36 GMT"

---
# Implementing-Flutter-Concurrency-and-Data-Processing

## When to Use
* The agent needs to perform heavy computational tasks without blocking the main UI thread.
* The agent is parsing, decoding, or serializing large JSON payloads.
* The agent is implementing long-lived background workers for continuous data processing.
* The agent needs to manage asynchronous state updates and display `Future` or `Stream` results in a Flutter application.

## Instructions

**Interaction Rule:** Evaluate the current project context for target platforms (e.g., Web vs. Mobile), existing state management solutions, and expected API payload sizes. If this information is missing or ambiguous, ask the user for clarification before proceeding with implementation.

### Plan
1. **Analyze the Task:** Determine if the operation is I/O-bound (network, disk) or CPU-bound (parsing large JSON, complex math).
2. **Select the Concurrency Model:** Use the Decision Logic below to choose between standard asynchronous execution, short-lived isolates, or long-lived isolates.
3. **Design the Data Flow:** Define the data structures being passed. Ensure objects passed between isolates are immutable or easily serializable.

### Execute
1. Implement the chosen concurrency model using Dart's `async`/`await`, `Isolate.run()`, or `ReceivePort`/`SendPort`.
2. Integrate JSON serialization using `dart:convert` for simple tasks or `json_serializable` for complex models.
3. Bind the asynchronous results to the UI using `FutureBuilder` or `StreamBuilder`.

### Decision Logic for Concurrency
Use the following decision tree to determine the appropriate concurrency implementation:

* **Is the target platform Web?**
  * **Yes:** Use `compute()` or standard `async`/`await`. (Isolates are not supported on the web).
  * **No:** Proceed to next step.
* **Is the task strictly I/O-bound (e.g., fetching data over HTTP, reading a small file)?**
  * **Yes:** Use standard `async` and `await` on the main isolate. The event loop will handle it without freezing the UI.
  * **No:** Proceed to next step.
* **Is the task a one-time heavy computation (e.g., decoding a >10KB JSON blob)?**
  * **Yes:** Use `Isolate.run()` to spawn a short-lived background worker.
  * **No:** Proceed to next step.
* **Does the task require continuous, repeated execution or multiple message passes over time?**
  * **Yes:** Use the `Isolate` API with `ReceivePort` and `SendPort` to establish a long-lived background worker.

## Best Practices

* **Understand the Execution Model:** Remember that Dart has a single-threaded execution model driven by an event loop. All code runs in isolates, which have their own isolated memory and do not share state.
* **Never Block the Main Isolate:** Use `async` and `await` to allow other operations to execute before a task completes. Functions marked as `async` automatically return a `Future`.
* **Offload Heavy Tasks:** Use `Isolate.run()` (Dart 2.19+) for long-running operations that might block UI rendering. Pass a callback with exactly one required, unnamed argument.
* **Communicate via Ports for Long-Lived Tasks:** Exclusively use `ReceivePort` (acts as a listener) and `SendPort` (acts like a `StreamController`) for messaging between long-lived isolates.
* **Optimize Message Passing:** Pass immutable objects (like `String` or unmodifiable bytes) between isolates when possible to send references rather than copying data, improving performance.
* **Automate JSON Serialization:** For medium to large projects, use `json_serializable` and `build_runner` to generate deterministic, type-safe serialization code instead of manually parsing `Map<String, dynamic>`.
* **Handle Errors Gracefully:** Always wrap asynchronous network and parsing operations in `try/catch` blocks. Handle `AsyncSnapshot.hasError` states within your `FutureBuilder` or `StreamBuilder` widgets.

## Examples

### Gold Standard: Short-Lived Isolate for JSON Parsing
Use `Isolate.run()` to decode a large JSON payload without dropping UI frames.

```dart
// lib/services/data_service.dart
import 'dart:convert';
import 'dart:isolate';
import 'package:http/http.dart' as http;

class DataService {
  static const String _apiUrl = 'https://api.example.com/large-payload';

  /// Fetches and parses a large JSON array in a background isolate.
  Future<List<Map<String, dynamic>>> fetchAndParseData() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      
      if (response.statusCode == 200) {
        // Offload the heavy JSON decoding to a background worker
        final parsedData = await Isolate.run(() {
          final decoded = jsonDecode(response.body) as List<dynamic>;
          return decoded.cast<Map<String, dynamic>>();
        });
        
        return parsedData;
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network or parsing error: $e');
    }
  }
}
```

### Gold Standard: Long-Lived Isolate with Two-Way Communication
Use `ReceivePort` and `SendPort` for continuous background processing.

```dart
// lib/services/background_worker.dart
import 'dart:isolate';

class BackgroundWorker {
  SendPort? _backgroundSendPort;
  final ReceivePort _mainReceivePort = ReceivePort();

  Future<void> initialize() async {
    // Spawn the isolate and pass the main isolate's SendPort
    await Isolate.spawn(_workerEntrypoint, _mainReceivePort.sendPort);

    // Listen for messages from the background isolate
    _mainReceivePort.listen((message) {
      if (message is SendPort) {
        // First message is the background isolate's SendPort
        _backgroundSendPort = message;
      } else {
        // Handle subsequent data messages
        print('Received processed data from background: $message');
      }
    });
  }

  void sendDataForProcessing(String data) {
    if (_backgroundSendPort != null) {
      _backgroundSendPort!.send(data);
    } else {
      print('Worker not fully initialized yet.');
    }
  }

  void dispose() {
    _mainReceivePort.close();
  }

  /// The entrypoint for the background isolate. Must be a top-level or static function.
  static void _workerEntrypoint(SendPort mainSendPort) {
    final backgroundReceivePort = ReceivePort();
    
    // Send the background port back to the main isolate to establish two-way communication
    mainSendPort.send(backgroundReceivePort.sendPort);

    // Listen for incoming tasks
    backgroundReceivePort.listen((message) {
      if (message is String) {
        // Perform heavy computation
        final result = message.toUpperCase(); // Example computation
        
        // Send result back to main isolate
        mainSendPort.send(result);
      }
    });
  }
}
```

### Gold Standard: Binding Asynchronous Data to the UI
Use `FutureBuilder` to reactively display the state of a `Future`.

```dart
// lib/ui/screens/data_screen.dart
import 'package:flutter/material.dart';
import '../services/data_service.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  late Future<List<Map<String, dynamic>>> _dataFuture;
  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    _dataFuture = _dataService.fetchAndParseData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Async Data Load')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final data = snapshot.data!;
            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(data[index]['name'] ?? 'Unknown'),
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
