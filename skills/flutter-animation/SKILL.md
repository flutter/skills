---
name: "flutter-animation"
description: "Add animated effects to your Flutter app"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 17:40:11 GMT"

---
# Implementing-Flutter-Animations

## When to Use
* The agent needs to add motion, visual feedback, or transitions to a Flutter application.
* The user requests shared element transitions (Hero animations), staggered animations, or physics-based interactions.
* The UI requires smooth interpolation of properties (color, size, position, opacity) over a specified duration.
* The project requires custom page routing transitions.

## Decision Logic
Evaluate the animation requirements using the following decision tree to select the correct approach:

1. **Is the animation a simple property change (e.g., size, color, alignment) without needing manual control (play, pause, reverse)?**
   * **Yes:** Use **Implicit Animations** (e.g., `AnimatedContainer`, `AnimatedOpacity`, `AnimatedAlign`).
   * **No:** Proceed to step 2.
2. **Does the animation involve an element flying between two different routes/pages?**
   * **Yes:** Use **Shared Element Transitions** (`Hero` widget).
   * **No:** Proceed to step 3.
3. **Does the animation need to model real-world motion (e.g., dropping, springing)?**
   * **Yes:** Use **Physics-based Animation** (`SpringSimulation` with `AnimationController.animateWith()`).
   * **No:** Proceed to step 4 (Tween-based explicit animation).
4. **Is the animation a transition between two page routes?**
   * **Yes:** Use `PageRouteBuilder` with a transition widget (e.g., `SlideTransition`).
   * **No:** Proceed to step 5.
5. **Do you need to build a custom explicit animation from scratch?**
   * **Yes:** Create an `AnimationController`. 
     * If the animated widget is standalone and reusable, subclass `AnimatedWidget`.
     * If the animation is part of a larger build function, use `AnimatedBuilder` to separate the transition rendering from the widget rendering.

## Instructions

**Plan**
1. Identify the trigger for the animation (e.g., user tap, route push, state change).
2. Determine the animation category (Implicit, Explicit Tween-based, or Physics-based) using the Decision Logic.
3. Identify the specific properties to animate (e.g., `double` for size, `Color` for background, `Offset` for position).

**Execute**
1. **Implicit:** Replace standard widgets with their `Animated` counterparts (e.g., `Container` -> `AnimatedContainer`) and define a `Duration` and `Curve`.
2. **Explicit:** 
   * Add `SingleTickerProviderStateMixin` (or `TickerProviderStateMixin` for multiple controllers) to the `State` class.
   * Initialize an `AnimationController` in `initState()` with a `Duration` and `vsync: this`.
   * Define a `Tween` to map the 0.0-1.0 controller range to the desired output type and range.
   * Apply a `Curve` using `CurvedAnimation` or `CurveTween`.
   * Wrap the target widget in an `AnimatedBuilder` or `AnimatedWidget`.
3. **Clean Up:** Always call `dispose()` on the `AnimationController` in the `dispose()` lifecycle method.

**Interaction Rule:** Evaluate the current project context for [Target Widget, Trigger Mechanism, Performance Constraints]. If any of these requirements are missing or ambiguous, ask the user for clarification before proceeding with implementation.

## Best Practices

* **Manage State Lifecycle:** Always dispose of `AnimationController` instances in the `dispose()` method of your `StatefulWidget` to prevent memory leaks.
* **Optimize Rebuilds:** Use `AnimatedBuilder` or `AnimatedWidget` instead of manually calling `setState()` inside an `addListener()`. This isolates the rebuilds to only the widgets that are actually animating.
* **Use Tweens Correctly:** Treat `Tween<T>` and `Curve` classes as stateless and immutable. Use them strictly to map the `AnimationController`'s default 0.0-1.0 range to your desired output values.
* **Leverage Implicit Animations:** Default to implicit animations (like `AnimatedContainer`) for simple state changes. They automatically manage the intermediate behavior without boilerplate.
* **Implement Hero Animations for Context:** Use `Hero` widgets with identical `tag` properties on both the source and destination routes to create seamless shared element transitions.
* **Stagger Complex Motions:** Break complex animations into smaller, overlapping motions using multiple `Tween`s driven by a single `AnimationController`. Assign an `Interval` (between 0.0 and 1.0) to each `CurvedAnimation` to stagger their execution.
* **Use Physics for Natural Interactions:** Implement physics-based animations (using `SpringSimulation` and `animateWith`) when elements are driven by user gestures (like dragging and releasing) to maintain realistic momentum.

## Examples

### Gold Standard: Implicit Animation (`AnimatedContainer`)
Use this for simple, fire-and-forget property transitions.

```dart
// lib/widgets/animated_box.dart
import 'package:flutter/material.dart';

class AnimatedBox extends StatefulWidget {
  const AnimatedBox({super.key});

  @override
  State<AnimatedBox> createState() => _AnimatedBoxState();
}

class _AnimatedBoxState extends State<AnimatedBox> {
  bool _isExpanded = false;

  void _toggleBox() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleBox,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        width: _isExpanded ? 200.0 : 100.0,
        height: _isExpanded ? 200.0 : 100.0,
        decoration: BoxDecoration(
          color: _isExpanded ? Colors.green : Colors.blue,
          borderRadius: BorderRadius.circular(_isExpanded ? 20.0 : 8.0),
        ),
        alignment: _isExpanded ? Alignment.center : Alignment.topCenter,
        child: const Text(
          'Tap Me',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
```

### Gold Standard: Explicit Animation with `AnimatedBuilder`
Use this when you need precise control over the animation lifecycle (play, reverse, repeat).

```dart
// lib/widgets/spinning_logo.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class SpinningLogo extends StatefulWidget {
  const SpinningLogo({super.key});

  @override
  State<SpinningLogo> createState() => _SpinningLogoState();
}

class _SpinningLogoState extends State<SpinningLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value,
          child: child,
        );
      },
      child: const FlutterLogo(size: 100), // Child is passed in to prevent rebuilding
    );
  }
}
```

### Gold Standard: Custom Page Route Transition
Use this to create custom transitions between screens (e.g., sliding up from the bottom).

```dart
// lib/routes/slide_up_route.dart
import 'package:flutter/material.dart';

class SlideUpRoute extends PageRouteBuilder {
  final Widget page;

  SlideUpRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

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
// Navigator.of(context).push(SlideUpRoute(page: const DetailsScreen()));
```

### Gold Standard: Hero Animation (Shared Element)
Use this to fly an element seamlessly between two routes.

```dart
// lib/screens/hero_screens.dart
import 'package:flutter/material.dart';

class SourceScreen extends StatelessWidget {
  const SourceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Source')),
      body: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DestinationScreen()),
          );
        },
        child: Hero(
          tag: 'avatar-tag',
          child: CircleAvatar(
            radius: 40,
            backgroundImage: const NetworkImage('https://example.com/avatar.png'),
          ),
        ),
      ),
    );
  }
}

class DestinationScreen extends StatelessWidget {
  const DestinationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Destination')),
      body: Center(
        child: Hero(
          tag: 'avatar-tag', // Must match the source tag exactly
          child: Image.network(
            'https://example.com/avatar.png',
            width: 300,
            height: 300,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
```
