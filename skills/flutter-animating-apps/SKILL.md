---
name: flutter-animating-apps
description: Implements animated effects, transitions, and motion in a Flutter app. Use when adding visual feedback, shared element transitions, or physics-based animations.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Thu, 12 Mar 2026 22:16:34 GMT

---
# Implementing Flutter Animations

## Contents
- [Core Concepts](#core-concepts)
- [Animation Strategies](#animation-strategies)
- [Workflows](#workflows)
  - [Implementing Implicit Animations](#implementing-implicit-animations)
  - [Implementing Explicit Animations](#implementing-explicit-animations)
  - [Implementing Hero Transitions](#implementing-hero-transitions)
  - [Implementing Physics-Based Animations](#implementing-physics-based-animations)
- [Examples](#examples)

## Core Concepts

Manage Flutter animations using the core typed `Animation` system. Do not manually calculate frames; rely on the framework's ticker and interpolation classes.

*   **`Animation<T>`**: Treat this as an abstract representation of a value that changes over time. It holds state (completed, dismissed) and notifies listeners, but knows nothing about the UI.
*   **`AnimationController`**: Instantiate this to drive the animation. It generates values (typically 0.0 to 1.0) tied to the screen refresh rate. Always provide a `vsync` (usually via `SingleTickerProviderStateMixin`) to prevent offscreen resource consumption. Always `dispose()` controllers to prevent memory leaks.
*   **`Tween<T>`**: Define a stateless mapping from an input range (usually 0.0-1.0) to an output type (e.g., `Color`, `Offset`, `double`). Chain tweens with curves using `.animate()`.
*   **`Curve`**: Apply non-linear timing (e.g., `Curves.easeIn`, `Curves.bounceOut`) to an animation using a `CurvedAnimation` or `CurveTween`.
*   **`CurvedAnimation`**: When you create one explicitly (e.g., for `Interval` / staggered motion), keep a reference and call `dispose()` when done. Leak tracking flags undisposed instances (see [flutter/flutter#141198](https://github.com/flutter/flutter/issues/141198)).

## Animation Strategies

Apply conditional logic to select the correct animation approach:

*   **If animating simple property changes (size, color, opacity) without playback control:** Use **Implicit Animations** (e.g., `AnimatedContainer`, `AnimatedOpacity`, `TweenAnimationBuilder`).
*   **If requiring playback control (play, pause, reverse, loop) or coordinating multiple properties:** Use **Explicit Animations** (e.g., `AnimationController` with `AnimatedBuilder` or `AnimatedWidget`).
*   **If animating elements between two distinct routes:** Use **Hero Animations** (Shared Element Transitions).
*   **If modeling real-world motion (e.g., snapping back after a drag):** Use **Physics-Based Animations** (e.g., `SpringSimulation`).
*   **If animating a sequence of overlapping or delayed motions:** Use **Staggered Animations** (multiple `Tween`s driven by a single `AnimationController` using `Interval` curves).

## Workflows

### Implementing Implicit Animations

Use this workflow for "fire-and-forget" state-driven animations.

- [ ] **Task Progress:**
  - [ ] Identify the target properties to animate (e.g., width, color).
  - [ ] Replace the static widget (e.g., `Container`) with its animated counterpart (e.g., `AnimatedContainer`).
  - [ ] Define the `duration` property.
  - [ ] (Optional) Define the `curve` property for non-linear motion.
  - [ ] Trigger the animation by updating the properties inside a `setState()` call.
  - [ ] Run validator -> review UI for jank -> adjust duration/curve if necessary.

### Implementing Explicit Animations

Use this workflow when you need granular control over the animation lifecycle.

- [ ] **Task Progress:**
  - [ ] Add `SingleTickerProviderStateMixin` (or `TickerProviderStateMixin` for multiple controllers) to the `State` class.
  - [ ] Initialize an `AnimationController` in `initState()`, providing `vsync: this` and a `duration`.
  - [ ] Define a `Tween` and chain it to the controller using `.animate()`.
  - [ ] Wrap the target UI in an `AnimatedBuilder` (preferred for complex trees) or subclass `AnimatedWidget`.
  - [ ] Pass the `Animation` object to the `AnimatedBuilder`'s `animation` property.
  - [ ] Control playback using `controller.forward()`, `controller.reverse()`, or `controller.repeat()`.
  - [ ] Call `controller.dispose()` in the `dispose()` method (if you use `CurvedAnimation` or another animation with its own `dispose()`, call that **before** the controller).
  - [ ] Run validator -> check for memory leaks -> ensure `dispose()` is called.

### Implementing Hero Transitions

Use this workflow to fly a widget between two routes.

- [ ] **Task Progress:**
  - [ ] Wrap the source widget in a `Hero` widget.
  - [ ] Assign a unique, data-driven `tag` to the source `Hero`.
  - [ ] Wrap the destination widget in a `Hero` widget.
  - [ ] Assign the *exact same* `tag` to the destination `Hero`.
  - [ ] Ensure the widget trees inside both `Hero` widgets are visually similar to prevent jarring jumps.
  - [ ] Trigger the transition by pushing the destination route via `Navigator`.

### Implementing Physics-Based Animations

Use this workflow for gesture-driven, natural motion.

- [ ] **Task Progress:**
  - [ ] Set up an `AnimationController` (do not set a fixed duration).
  - [ ] Capture gesture velocity using a `GestureDetector` (e.g., `onPanEnd` providing `DragEndDetails`).
  - [ ] Convert the pixel velocity to the coordinate space of the animating property.
  - [ ] Instantiate a `SpringSimulation` with mass, stiffness, damping, and the calculated velocity.
  - [ ] Drive the controller using `controller.animateWith(simulation)`.

## Examples

<details>
<summary><b>Example: Explicit Animation (Staggered with AnimatedBuilder)</b></summary>

```dart
class StaggeredAnimationDemo extends StatefulWidget {
  @override
  State<StaggeredAnimationDemo> createState() => _StaggeredAnimationDemoState();
}

class _StaggeredAnimationDemoState extends State<StaggeredAnimationDemo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late CurvedAnimation _widthCurve;
  late CurvedAnimation _colorCurve;
  late Animation<double> _widthAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Staggered width animation (0.0 to 0.5 interval)
    _widthCurve = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );
    _widthAnimation = Tween<double>(begin: 50.0, end: 200.0).animate(_widthCurve);

    // Staggered color animation (0.5 to 1.0 interval)
    _colorCurve = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );
    _colorAnimation = ColorTween(begin: Colors.blue, end: Colors.red).animate(_colorCurve);

    _controller.forward();
  }

  @override
  void dispose() {
    // CRITICAL: Prevent memory leaks
    _widthCurve.dispose();
    _colorCurve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          height: 50.0,
          color: _colorAnimation.value,
        );
      },
    );
  }
}
```
</details>

<details>
<summary><b>Example: Custom Page Route Transition</b></summary>

```dart
Route createCustomRoute(Widget destination) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => destination,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0); // Start from bottom
      const end = Offset.zero;
      const curve = Curves.easeOut;

      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      final offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  );
}

// Usage: Navigator.of(context).push(createCustomRoute(const NextPage()));
```
</details>
