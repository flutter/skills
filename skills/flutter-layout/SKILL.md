---
name: "flutter-layout"
description: "How to build your app's layout using Flutter's layout widgets and constraint system"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 18:03:58 GMT"

---
# Building-Flutter-Layouts

## When to Use
* The agent needs to construct user interfaces in Flutter.
* The agent is tasked with arranging, aligning, or constraining visible widgets.
* The agent must implement responsive or adaptive designs for multiple screen sizes (e.g., mobile, tablet, desktop).
* The agent encounters layout overflow errors (yellow and black striped patterns) or unbounded constraint exceptions.

## Instructions

**Interaction Rule:** Evaluate the current project context for UI mockups, target platforms, and specific layout requirements. If missing, ask the user for clarification before proceeding with implementation.

1. **Plan the Layout:** Diagram the UI visually before coding. Break the design down into basic elements: identify rows, columns, grids, overlapping elements, and areas requiring padding or alignment.
2. **Select the Layout Widget:** Choose the appropriate structural widget (e.g., `Scaffold`, `Row`, `Column`, `Stack`) based on the diagram.
3. **Create Visible Widgets:** Instantiate the visible elements such as `Text`, `Icon`, or `Image`.
4. **Compose the Tree:** Add the visible widgets as children to the layout widgets. Nest rows and columns as needed to achieve the desired structure.
5. **Apply Constraints:** Use `Expanded`, `Flexible`, or `SizedBox` to control how children occupy available space and to prevent overflow errors.
6. **Implement Responsiveness:** Wrap top-level layout components in a `LayoutBuilder` to adapt the UI based on available screen width.

## Decision Logic

Use the following decision tree to select the correct layout widget:

* **Do you need to arrange widgets linearly?**
  * Yes, horizontally -> Use `Row`.
  * Yes, vertically -> Use `Column`.
  * *Sub-decision:* Will the content exceed the screen size?
    * Yes -> Use `ListView` (or wrap the `Column`/`Row` in a `SingleChildScrollView`).
    * No -> Stick with `Row` or `Column`.
* **Do you need to overlap widgets (e.g., text over an image)?**
  * Yes -> Use `Stack`.
* **Do you need to arrange widgets in a 2D array?**
  * Yes -> Use `GridView`.
* **Do you need to add padding, margins, borders, or background color to a single widget?**
  * Yes -> Use `Container` (or `Padding` if only padding is needed).
* **Do you need the layout to change based on screen size (e.g., mobile vs. tablet)?**
  * Yes -> Use `LayoutBuilder` to read constraints and branch the UI logic.
* **Do you need a child to fill the remaining space in a `Row` or `Column`?**
  * Yes -> Wrap the child in an `Expanded` widget.

## Best Practices

* **Apply the Core Layout Rule:** Always remember: *Constraints go down. Sizes go up. Parent sets position.* A widget gets constraints from its parent, asks its children what size they want to be, positions them, and then tells its parent its own size.
* **Treat Everything as a Widget:** Remember that in Flutter, almost everything is a widget, including invisible layout models (like `Center`, `Align`, `Padding`).
* **Prevent Unbounded Constraints:** Never place a scrollable widget (like `ListView`) directly inside an unconstrained flex box (like `Column` or `Row`). Always wrap the scrollable widget in an `Expanded` or `Flexible` widget to provide bounded constraints.
* **Handle Overflows:** If a `Row` or `Column` overflows its bounds (showing yellow/black stripes), wrap the offending children in `Expanded` or `Flexible` widgets to constrain them to the available space.
* **Modularize the UI:** Extract heavily nested layout code into separate, smaller `StatelessWidget` classes or builder methods to improve readability and performance.
* **Use SafeArea:** Always wrap top-level screen content in a `SafeArea` widget to prevent the UI from overlapping with system interfaces like notches, status bars, and home indicators.
* **Pack Widgets Tightly:** Set `mainAxisSize: MainAxisSize.min` on `Row` or `Column` when you want the layout to shrink-wrap its children rather than expanding to fill the main axis.

## Examples

### Adaptive Layout with Constraints and Flex Widgets

This example demonstrates an adaptive layout that switches between a single-column view for mobile and a side-by-side view for larger screens, applying proper constraints and flex rules.

```dart
import 'package:flutter/material.dart';

const double kLargeScreenMinWidth = 600.0;

class AdaptiveDashboard extends StatefulWidget {
  const AdaptiveDashboard({super.key});

  @override
  State<AdaptiveDashboard> createState() => _AdaptiveDashboardState();
}

class _AdaptiveDashboardState extends State<AdaptiveDashboard> {
  int _selectedIndex = 0;

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adaptive Dashboard'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isLargeScreen = constraints.maxWidth > kLargeScreenMinWidth;

            if (isLargeScreen) {
              return _buildLargeScreenLayout();
            } else {
              return _buildSmallScreenLayout();
            }
          },
        ),
      ),
    );
  }

  Widget _buildLargeScreenLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Fixed-width sidebar
        SizedBox(
          width: 250.0,
          child: _SidebarList(
            selectedIndex: _selectedIndex,
            onItemSelected: _onItemSelected,
          ),
        ),
        // Vertical divider
        Container(
          width: 1.0,
          color: Colors.grey[300],
        ),
        // Expanded detail view takes remaining space
        Expanded(
          child: _DetailView(selectedIndex: _selectedIndex),
        ),
      ],
    );
  }

  Widget _buildSmallScreenLayout() {
    // Uses a Column with Expanded to prevent unbounded height issues
    return Column(
      children: <Widget>[
        Expanded(
          child: _SidebarList(
            selectedIndex: _selectedIndex,
            onItemSelected: _onItemSelected,
          ),
        ),
      ],
    );
  }
}

class _SidebarList extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const _SidebarList({
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          selected: index == selectedIndex,
          leading: const Icon(Icons.dashboard),
          title: Text('Item $index'),
          onTap: () => onItemSelected(index),
        );
      },
    );
  }
}

class _DetailView extends StatelessWidget {
  final int selectedIndex;

  const _DetailView({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min, // Packs children tightly
        children: <Widget>[
          Icon(
            Icons.info_outline,
            size: 64.0,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16.0),
          Text(
            'Details for Item $selectedIndex',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ],
      ),
    );
  }
}
```
