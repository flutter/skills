---
name: "flutter-handling-concurrency"
description: "Executes long-running tasks in background isolates to keep the UI responsive. Use when performing heavy computations or parsing large datasets."
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Thu, 12 Mar 2026 22:23:14 GMT"

---
# Managing Dart Concurrency and Isolates

## Contents
- [Core Concepts](#core-concepts)
- [Decision Matrix: Async vs. Isolates](#decision-matrix-async-vs-isolates)
- [Workflows](#workflows)
  - [Implementing Standard Asynchronous UI](#implementing-standard-asynchronous-ui)
  - [Offloading Short-Lived Heavy Computation](#offloading-short-lived-heavy-computation)
  - [Establishing Long-Lived Worker Isolates](#establishing-long-lived-worker-isolates)
- [Examples](#examples)

## Core Concepts

Dart utilizes a single-threaded execution model driven by an Event Loop (comparable to the iOS main loop). By default, all Flutter application code runs on the Main Isolate. 

*   **Asynchronous Operations (`async`/`await`):** Use for non-blocking I/O tasks (network requests, file access). The Event Loop continues processing other events while waiting for the `Future` to complete.
*   **Isolates:** Dart's implementation of lightweight threads. Isolates possess their own isolated memory and do not share state. They communicate exclusively via message passing.
*   **Main Isolate:** The default thread where UI rendering and event handling occur. Blocking this isolate causes UI freezing (jank).
*   **Worker Isolate:** A spawned isolate used to offload CPU-bound tasks (e.g., decoding large JSON blobs) to prevent Main Isolate blockage.

## Decision Matrix: Async vs. Isolates

Apply the following conditional logic to determine the correct concurrency approach:

*   **If** the task is I/O bound (e.g., HTTP request, database read) -> **Use `async`/`await`** on the Main Isolate.
*   **If** the task is CPU-bound but executes quickly (< 16ms) -> **Use `async`/`await`** on the Main Isolate.
*   **If** the task is CPU-bound, takes significant time, and runs once (e.g., parsing a massive JSON payload) -> **Use `Isolate.run()`**.
*   **If** the task requires continuous or repeated background processing with multiple messages passed over time -> **Use `Isolate.spawn()` with `ReceivePort` and `SendPort`**.

## Workflows

### Implementing Standard Asynchronous UI

Use this workflow to fetch and display non-blocking asynchronous data.

**Task Progress:**
- [ ] Mark the data-fetching function with the `async` keyword.
- [ ] Return a `Future<T>` from the function.
- [ ] Use the `await` keyword to yield execution until the operation completes.
- [ ] Wrap the UI component in a `FutureBuilder<T>` (or `StreamBuilder` for streams).
- [ ] Handle `ConnectionState.waiting`, `hasError`, and `hasData` states within the builder.
- [ ] Run validator -> review UI for loading indicators -> fix missing states.

### Offloading Short-Lived Heavy Computation

Use this workflow for one-off, CPU-intensive tasks using Dart 2.19+.

**Task Progress:**
- [ ] Identify the CPU-bound operation blocking the Main Isolate.
- [ ] Extract the computation into a standalone callback function.
- [ ] Ensure the callback function signature accepts exactly one required, unnamed argument (as per specific architectural constraints).
- [ ] Invoke `Isolate.run()` passing the callback.
- [ ] `await` the result of `Isolate.run()` in the Main Isolate.
- [ ] Assign the returned value to the application state.

### Establishing Long-Lived Worker Isolates

Use this workflow for persistent background processes requiring continuous bidirectional communication.

**Task Progress:**
- [ ] Instantiate a `ReceivePort` on the Main Isolate to listen for messages.
- [ ] Define the worker entry point function and mark it with `@pragma('vm:entry-point')` to prevent tree-shaking.
- [ ] Spawn the worker isolate using `Isolate.spawn()`, passing the `ReceivePort.sendPort` as the initial message.
- [ ] In the worker isolate, instantiate its own `ReceivePort`.
- [ ] Send the worker's `SendPort` back to the Main Isolate via the initial port.
- [ ] Store the worker's `SendPort` in the Main Isolate for future message dispatching.
- [ ] Implement listeners on both `ReceivePort` instances to handle incoming messages.
- [ ] Run validator -> review memory leaks -> ensure ports are closed when the isolate is no longer needed.

## Examples

### Example 1: Asynchronous UI with FutureBuilder

```dart
// 1. Define the async operation
Future<String> fetchUserData() async {
  await Future.delayed(const Duration(seconds: 2)); // Simulate network I/O
  return "User Data Loaded";
}

// 2. Consume in the UI
Widget build(BuildContext context) {
  return FutureBuilder<String>(
    future: fetchUserData(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const CircularProgressIndicator();
      } else if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}');
      } else {
        return Text('Result: ${snapshot.data}');
      }
    },
  );
}
```

### Example 2: Short-Lived Isolate (`Isolate.run`)

```dart
import 'dart:isolate';
import 'dart:convert';

// 1. Define the heavy computation callback
// Note: Adhering to the strict single-argument signature requirement.
List<dynamic> decodeHeavyJson(String jsonString) {
  return jsonDecode(jsonString) as List<dynamic>;
}

// 2. Offload to a worker isolate
Future<List<dynamic>> processDataInBackground(String rawJson) async {
  // Isolate.run spawns the isolate, runs the computation, returns the value, and exits.
  final result = await Isolate.run(() => decodeHeavyJson(rawJson));
  return result;
}
```

### Example 3: Long-Lived Isolate (`ReceivePort` / `SendPort`)

```dart
import 'dart:isolate';

class WorkerManager {
  late SendPort _workerSendPort;
  final ReceivePort _mainReceivePort = ReceivePort();
  Isolate? _isolate;

  Future<void> initialize() async {
    // 1. Spawn isolate and pass the Main Isolate's SendPort
    _isolate = await Isolate.spawn(_workerEntry, _mainReceivePort.sendPort);

    // 2. Listen for messages from the Worker Isolate
    _mainReceivePort.listen((message) {
      if (message is SendPort) {
        // First message is the Worker's SendPort
        _workerSendPort = message;
        _startCommunication();
      } else {
        // Subsequent messages are data payloads
        print('Main Isolate received: $message');
      }
    });
  }

  void _startCommunication() {
    // Send data to the worker
    _workerSendPort.send("Process this data");
  }

  // 3. Worker Isolate Entry Point
  // The @pragma annotation prevents tree-shaking of this function, as it is
  // invoked dynamically by the VM when the isolate starts, not through
  // regular static calls. Without this, the function may be removed in
  // release builds, causing the isolate spawn to fail at runtime.
  @pragma('vm:entry-point')
  static void _workerEntry(SendPort mainSendPort) {
    final workerReceivePort = ReceivePort();
    
    // Send the Worker's SendPort back to the Main Isolate
    mainSendPort.send(workerReceivePort.sendPort);

    // Listen for incoming tasks
    workerReceivePort.listen((message) {
      print('Worker Isolate received: $message');
      
      // Perform work and send result back
      final result = "Processed: $message";
      mainSendPort.send(result);
    });
  }

  void dispose() {
    _mainReceivePort.close();
    _isolate?.kill();
  }
}
```
