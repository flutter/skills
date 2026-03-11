---
name: "flutter-layout"
description: "How to build your app's layout using Flutter's layout widgets and constraint system"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 17:37:51 GMT"

---
# Architecting-Flutter-Layouts

## Goal
The goal of this skill is to architect and implement robust, responsive, and adaptive Flutter layouts using widget composition and constraint-based sizing.

## When to Use
*   The system needs to build new UI screens or components in a Flutter application.
*   The system must refactor existing UIs to be responsive across mobile, tablet, and desktop platforms.
*   The system encounters layout overflow errors or unbounded constraint exceptions (e.g., `BoxConstraints forces an infinite width`).

## Instructions
Follow this "Plan -> Execute" workflow to build Flutter layouts:

1.  **Plan the Layout:** Break down the UI into basic elements. Identify rows, columns, grids, overlapping elements, and areas requiring alignment, padding, or borders.
2.  **Select Layout Widgets:** Choose the appropriate structural widgets based on the layout diagram (see Decision Logic below).
3.  **Compose Visible Widgets:** Create the visible elements (Text, Image, Icon) and nest them inside the layout widgets.
4.  **Apply Constraints:** Manage sizing and positioning by applying constraints. Remember that in Flutter, almost everything is a widget, including layout models.

**Interaction Rule:** Evaluate the current project context for target screen sizes, orientation requirements, and design mockups. If missing, ask the user for clarification before proceeding with implementation.

## Decision Logic

Use the following logic tree to select the correct layout widget:

*   **Does the content need to scroll?**
    *   Yes, it's a linear list -> Use `ListView`.
    *   Yes, it's a 2D array -> Use `GridView`.
    *   Yes, it's a custom layout -> Wrap in `SingleChildScrollView`.
    *   No -> Proceed below.
*   **How are the items arranged?**
    *   Horizontally -> Use `Row`.
    *   Vertically -> Use `Column`.
    *   Overlapping (Z-axis) -> Use `Stack`.
*   **Does a single widget need styling or spacing?**
    *   Needs padding, margin, border, and background color -> Use `Container`.
    *   Needs *only* padding -> Use `Padding` (more performant).
    *   Needs *only* specific dimensions -> Use `SizedBox`.
*   **Does the layout need to adapt to screen size?**
    *   Yes -> Use `LayoutBuilder` to read constraints and branch logic.

## Best Practices

*   **Apply the Core Constraint Rule:** Memorize and strictly adhere to: *Constraints go down. Sizes go up. Parent sets position.* A widget cannot choose its own size or placement; it must negotiate with its parent.
*   **Prevent Unbounded Constraints:** Never nest a scrollable widget (like `ListView`) inside an unconstrained flex box (`Column` or `Row`) without wrapping it in an `Expanded` or `Flexible` widget.
*   **Handle Flex Overflows:** Use `Expanded` or `Flexible` inside `Row` and `Column` to prevent overflow and distribute available space proportionally.
*   **Implement Adaptive Breakpoints:** Use `LayoutBuilder` to create responsive designs that fit the UI into the available space and adaptive designs that make the UI usable (e.g., switching from a bottom navigation bar to a side navigation rail on wide screens).
*   **Flatten Widget Trees:** Extract heavily nested layout code into separate, smaller `StatelessWidget` classes. This improves readability and minimizes the render tree rebuild scope.

## Examples

### Gold Standard: Adaptive Layout with LayoutBuilder

This example demonstrates how to build a responsive layout that adapts between a mobile view (stacked) and a tablet/desktop view (side-by-side) using `LayoutBuilder`.

```dart
import 'package:flutter/material.dart';

const double _kTabletBreakpoint = 600.0;

class AdaptiveContactLayout extends StatefulWidget {
  const AdaptiveContactLayout({super.key});

  @override
  State<AdaptiveContactLayout> createState() => _AdaptiveContactLayoutState();
}

class _AdaptiveContactLayoutState extends State<AdaptiveContactLayout> {
  int _selectedContactId = 0;

  void _onContactSelected(int id) {
    setState(() {
      _selectedContactId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contacts')),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isLargeScreen = constraints.maxWidth > _kTabletBreakpoint;

          if (isLargeScreen) {
            return _buildLargeScreenLayout();
          } else {
            return _buildSmallScreenLayout();
          }
        },
      ),
    );
  }

  Widget _buildLargeScreenLayout() {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 320.0,
          child: ContactList(onSelected: _onContactSelected),
        ),
        const VerticalDivider(width: 1.0, thickness: 1.0),
        Expanded(
          child: ContactDetail(contactId: _selectedContactId),
        ),
      ],
    );
  }

  Widget _buildSmallScreenLayout() {
    return ContactList(onSelected: _onContactSelected);
  }
}

// Mock Widgets for demonstration
class ContactList extends StatelessWidget {
  final ValueChanged<int> onSelected;
  const ContactList({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('Contact $index'),
          onTap: () => onSelected(index),
        );
      },
    );
  }
}

class ContactDetail extends StatelessWidget {
  final int contactId;
  const ContactDetail({super.key, required this.contactId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Details for Contact $_kContactIdPrefix$contactId'),
    );
  }
}

const String _kContactIdPrefix = '#';
```

### Gold Standard: Safe Flex Constraints

This example demonstrates how to safely constrain a `ListView` inside a `Column` to prevent the "unbounded height" error.

```dart
import 'package:flutter/material.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Dashboard',
            style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
          ),
        ),
        // Wrap ListView in Expanded to provide bounded height constraints
        Expanded(
          child: ListView.builder(
            itemCount: 20,
            itemBuilder: (BuildContext context, int index) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ListTile(
                  leading: const Icon(Icons.data_usage),
                  title: Text('Data Item $index'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
```
