---
name: "flutter-animation"
description: "Add animated effects to your Flutter app"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 18:06:07 GMT"

---
# Implementing-Flutter-Animations

## When to Use
* The agent needs to add motion, transitions, or visual feedback to a Flutter application.
* The user requests shared element transitions (Hero animations) between screens.
* The user wants to animate properties of a widget (size, color, padding, opacity) implicitly based on state changes.
* The user requires complex, coordinated, or staggered animations driven by a single timeline.
* The user asks for physics-based interactions (e.g., spring, gravity, drag-and-release).
* The user requests custom page route transitions (e.g., sliding in from the bottom).

## Decision Logic
Evaluate the animation requirements to select the correct Flutter animation approach:

1. **Implicit Animations:** If animating simple property changes (color, size, alignment, padding) on state change.
   * *Action:* Use `AnimatedContainer`, `AnimatedOpacity`, `AnimatedAlign`, etc.
2. **Shared Element Transitions:** If flying a widget (like an image) between two different routing screens.
   * *Action:* Use the `Hero` widget with identical `tag` properties on both routes.
3. **Custom Route Transitions:** If animating the entrance/exit of an entire page.
   * *Action:* Use `PageRouteBuilder` and provide a `transitionsBuilder` (e.g., returning a `SlideTransition`).
4. **Staggered Animations:** If animating multiple properties sequentially or with overlapping timings.
   * *Action:* Use a single `AnimationController` and multiple `Tween` objects, applying an `Interval` curve to each.
5. **Physics-based Animations:** If modeling real-world motion (springs, gravity, flinging).
   * *Action:* Use `SpringSimulation` or `FrictionSimulation` and drive the controller using `AnimationController.animateWith()`.
6. **Reusable Explicit Animations:** If building a standalone widget that encapsulates its own explicit animation.
   * *Action:* Subclass `AnimatedWidget`.
7. **Complex Explicit Animations:** If adding animation to a complex widget tree where only a specific part should rebuild.
   * *Action:* Use `AnimatedBuilder` to isolate the rebuilds.

## Instructions

**Interaction Rule:** Evaluate the current project context for animation requirements (e.g., duration, curves, specific properties to animate, and whether the animation is state-driven or timeline-driven). If the required approach or specific animation parameters are missing or ambiguous, ask the user for clarification before proceeding with implementation.

1. **Plan the Animation:**
   * Identify the trigger (e.g., user tap, route push, state change).
   * Determine the category: Tween-based (start/end points with a timeline and curve) or Physics-based (simulated real-world motion).
   * Select the appropriate widget or controller strategy using the Decision Logic above.
2. **Implement State Management (Explicit Animations):**
   * Add `SingleTickerProviderStateMixin` (for one controller) or `TickerProviderStateMixin` (for multiple) to the `State` class.
   * Initialize the `AnimationController` in `initState()`, providing the `vsync: this` and `duration`.
3. **Define Tweens and Curves:**
   * Map the 0.0-1.0 controller output to typed values using `Tween<T>` (e.g., `Tween<double>`, `ColorTween`).
   * Apply non-linear timing using `CurvedAnimation` or by chaining a `CurveTween`.
4. **Bind to the UI:**
   * For implicit animations, simply pass the new values to the animated widget and call `setState()`.
   * For explicit animations, wrap the animating portion of the UI in an `AnimatedBuilder` or `AnimatedWidget` to avoid calling `addListener` and `setState` manually.
5. **Execute Cleanup:**
   * Always dispose of `AnimationController` instances in the `dispose()` method.

## Best Practices

* **Prevent Memory Leaks:** Always call `dispose()` on `AnimationController` instances within the `State.dispose()` method.
* **Optimize Rebuilds:** Never call `setState()` inside an `AnimationController` listener if the widget tree is complex. Instead, use `AnimatedBuilder` or `AnimatedWidget` to scope rebuilds strictly to the widgets that are moving.
* **Chain Tweens for Readability:** Use the `.chain()` method to combine a `Tween` with a `CurveTween` (e.g., `Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut))`).
* **Use Implicit Animations First:** Default to implicit animations (like `AnimatedContainer`) for simple state transitions. Only escalate to explicit `AnimationController` implementations when you need to coordinate multiple animations, loop animations, or use physics simulations.
* **Match Hero Tags:** Ensure that the `tag` property of a `Hero` widget is strictly identical (and unique within the tree) between the source and destination routes.
* **Handle Offscreen Animations:** Always pass `vsync: this` to `AnimationController` to prevent offscreen animations from consuming unnecessary CPU resources.

## Examples

### Example 1: Implicit Animation (`AnimatedContainer`)
Use this pattern for simple, state-driven property changes without managing an `AnimationController`.

```dart
import 'package:flutter/material.dart';

class ImplicitAnimationExample extends StatefulWidget {
  const ImplicitAnimationExample({super.key});

  @override
  State<ImplicitAnimationExample> createState() => _ImplicitAnimationExampleState();
}

class _ImplicitAnimationExampleState extends State<ImplicitAnimationExample> {
  bool _isExpanded = false;

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleExpansion,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        width: _isExpanded ? 200.0 : 100.0,
        height: _isExpanded ? 200.0 : 100.0,
        decoration: BoxDecoration(
          color: _isExpanded ? Colors.blue : Colors.red,
          borderRadius: BorderRadius.circular(_isExpanded ? 20.0 : 8.0),
        ),
        alignment: _isExpanded ? Alignment.center : Alignment.bottomRight,
        child: const FlutterLogo(size: 50),
      ),
    );
  }
}
```

### Example 2: Staggered Explicit Animation (`AnimatedBuilder`)
Use this pattern when multiple properties must animate sequentially or overlap, driven by a single timeline.

```dart
import 'package:flutter/material.dart';

class StaggeredAnimationExample extends StatefulWidget {
  const StaggeredAnimationExample({super.key});

  @override
  State<StaggeredAnimationExample> createState() => _StaggeredAnimationExampleState();
}

class _StaggeredAnimationExampleState extends State<StaggeredAnimationExample>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _width;
  late Animation<Color?> _color;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Opacity animates during the first 50% of the timeline
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.50, curve: Curves.easeIn),
      ),
    );

    // Width animates from 50% to 100% of the timeline
    _width = Tween<double>(begin: 50.0, end: 200.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.50, 1.0, curve: Curves.easeOut),
      ),
    );

    // Color animates across the entire timeline
    _color = ColorTween(begin: Colors.red, end: Colors.blue).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.linear),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _playAnimation() {
    if (_controller.isCompleted) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _playAnimation,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacity.value,
            child: Container(
              width: _width.value,
              height: 100.0,
              color: _color.value,
              alignment: Alignment.center,
              child: const Text(
                'Staggered',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

### Example 3: Custom Page Route Transition
Use this pattern to override the default Material/Cupertino route transitions.

```dart
import 'package:flutter/material.dart';

Route<void> createSlideUpRoute(Widget destinationPage) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => destinationPage,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0); // Start from bottom
      const end = Offset.zero;        // End at center
      const curve = Curves.easeInOut;

      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      final offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  );
}

// Usage:
// Navigator.of(context).push(createSlideUpRoute(const MyNextPage()));
```
