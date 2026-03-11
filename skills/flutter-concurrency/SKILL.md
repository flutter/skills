---
name: "flutter-concurrency"
description: "Execute long-running tasks in a background thread in Flutter"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 18:15:34 GMT"

---
# Managing-Flutter-Concurrency-and-Data

## When to Use
* When an application requires parsing large data payloads (e.g., JSON) without causing UI jank or dropping frames.
* When offloading heavy computational tasks to background workers using Dart Isolates.
* When integrating asynchronous operations (`Future`, `Stream`) with Flutter UI components (`FutureBuilder`, `StreamBuilder`).
* When establishing a scalable JSON serialization strategy and state management architecture.

## Instructions

**Plan**
1. Evaluate the data payload size and the computational complexity of the required operations.
2. Determine the appropriate concurrency model (Main UI thread with `async`/`await`, short-lived `Isolate.run()`, or long-lived `ReceivePort`/`SendPort` isolates).
3. Select the JSON serialization strategy (manual `dart:convert` vs. automated `json_serializable`).
4. Choose the state management approach based on the scope of the state (ephemeral vs. app-wide).

**Execute**
1. Implement data models with the chosen serialization logic.
2. Offload heavy parsing or computation to isolates to preserve the 60/120fps rendering pipeline.
3. Bind asynchronous results to the UI using reactive builders.
4. Handle loading and error states explicitly within the UI builders.

**Interaction Rule:** 
Scan the project's `pubspec.yaml` for existing state management (e.g., `provider`, `riverpod`, `bloc`) and serialization dependencies (e.g., `json_serializable`, `built_value`). If missing or ambiguous, ask the user for their preferred stack before generating architectural boilerplate.

## Decision Logic

Use the following decision trees to determine the correct architectural approach:

**1. Concurrency Strategy**
* **Is the task I/O bound (e.g., network request, disk read)?**
  * Yes -> Use `async` and `await` on the main isolate.
* **Is the task CPU bound (e.g., parsing a massive JSON blob, image processing)?**
  * Is it a one-off task? -> Use `Isolate.run()`.
  * Does it require continuous, two-way communication over time? -> Use `Isolate.spawn()` with `ReceivePort` and `SendPort`.

**2. JSON Serialization Strategy**
* **Is the project a small prototype with few models?**
  * Yes -> Use manual serialization with `dart:convert` (`jsonDecode`).
* **Is the project medium-to-large with complex/nested data?**
  * Yes -> Use code generation (`json_serializable` and `build_runner`).

**3. State Management Strategy**
* **Is the state ephemeral and contained within a single widget (e.g., a toggle button)?**
  * Yes -> Use `StatefulWidget` and `setState()`.
* **Is the state shared across a small localized widget tree?**
  * Yes -> Use `ValueNotifier` or `InheritedWidget`.
* **Is the state complex, global, or requiring dependency injection?**
  * Yes -> Use a community package (e.g., `provider`, `riverpod`).

## Best Practices

* **Never block the main UI thread:** Dart uses a single-threaded execution model driven by an event loop. Use `async`/`await` for non-blocking I/O operations.
* **Offload heavy computation:** Use `Isolate.run()` to spawn an isolate, execute a computation, return the result, and automatically shut down the isolate.
* **Manage long-lived isolates carefully:** For processes that run repeatedly, use `Isolate.spawn()`. Communicate exclusively through `ReceivePort` (listener) and `SendPort` (message sender).
* **Optimize isolate message passing:** Pass only immutable objects or simple data types across isolate ports to minimize the overhead of copying memory.
* **Use reactive UI builders:** Utilize `FutureBuilder` and `StreamBuilder` to automatically handle the lifecycle of asynchronous data in the widget tree. Always check `snapshot.connectionState` and `snapshot.hasError`.
* **Generate serialization code:** When using `json_serializable`, run `dart run build_runner build --delete-conflicting-outputs` to generate the `*.g.dart` files. Use `@JsonSerializable(explicitToJson: true)` for nested objects.

## Examples

### Example 1: Short-Lived Isolate for Heavy JSON Parsing
Use `Isolate.run()` to decode a large JSON payload without freezing the UI.

```dart
// lib/services/data_service.dart
import 'dart:convert';
import 'dart:isolate';
import 'package:http/http.dart' as http;

class DataService {
  static const String _dataUrl = 'https://api.example.com/large-payload';

  /// Fetches and parses a large JSON array in a background isolate.
  Future<List<Map<String, dynamic>>> fetchAndParseData() async {
    final response = await http.get(Uri.parse(_dataUrl));

    if (response.statusCode == 200) {
      // Offload the heavy JSON decoding to a background worker
      return await Isolate.run(() {
        final decoded = jsonDecode(response.body) as List<dynamic>;
        return decoded.cast<Map<String, dynamic>>();
      });
    } else {
      throw Exception('Failed to load data');
    }
  }
}
```

### Example 2: Long-Lived Isolate with Ports
Use `ReceivePort` and `SendPort` for continuous background processing.

```dart
// lib/services/worker_service.dart
import 'dart:isolate';

class WorkerService {
  late SendPort _sendPort;
  final ReceivePort _receivePort = ReceivePort();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    // Spawn the isolate and pass the ReceivePort's SendPort
    await Isolate.spawn(_workerEntrypoint, _receivePort.sendPort);
    
    // The first message received is the SendPort from the worker
    _sendPort = await _receivePort.first as SendPort;
    _isInitialized = true;
  }

  /// Sends a message to the worker and waits for the specific response
  Future<int> processData(int input) async {
    final responsePort = ReceivePort();
    _sendPort.send([input, responsePort.sendPort]);
    return await responsePort.first as int;
  }

  /// The entrypoint running on the background isolate
  static void _workerEntrypoint(SendPort initialReplyTo) {
    final port = ReceivePort();
    initialReplyTo.send(port.sendPort);

    // Listen for incoming messages
    port.listen((message) {
      final int data = message[0] as int;
      final SendPort replyTo = message[1] as SendPort;
      
      // Perform heavy computation
      final result = data * 42; 
      
      replyTo.send(result);
    });
  }
}
```

### Example 3: Reactive UI with FutureBuilder
Bind the asynchronous isolate computation to the UI safely.

```dart
// lib/ui/data_screen.dart
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
      appBar: AppBar(title: const Text('Isolate Data Parsing')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data available.'));
          }

          final data = snapshot.data!;
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(data[index]['name'] ?? 'Unknown'),
                subtitle: Text(data[index]['email'] ?? 'No email'),
              );
            },
          );
        },
      ),
    );
  }
}
```
