---
name: "flutter-accessibility"
description: "Configure your Flutter app to support assistive technologies like Screen Readers"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 18:07:39 GMT"

---
# Implementing-Flutter-Accessibility-And-Adaptive-Design

## When to Use
* The agent is building or refactoring a Flutter application targeting multiple platforms (mobile, web, desktop).
* The agent needs to ensure compliance with global accessibility standards (WCAG 2, EN 301 549, VPAT).
* The agent is implementing custom UI components that require explicit semantic roles, keyboard navigation, or mouse interactions.
* The agent is optimizing layouts to respond dynamically to varying screen sizes, window resizing, and device orientations.

## Instructions
1. **Analyze Context:** Evaluate the current project context for target platforms, specific accessibility compliance levels, and responsive breakpoints.
2. **Interaction Rule:** If target platforms or accessibility requirements are missing or ambiguous, ask the user for clarification before proceeding with implementation.
3. **Plan Layout:** Break down complex UI into smaller, `const` widgets. Determine where responsive (fitting space) and adaptive (usable in space) patterns apply.
4. **Implement UI:** Use `LayoutBuilder` and `MediaQuery.sizeOf` for sizing. Avoid hardware-specific or orientation-locked constraints.
5. **Apply Semantics:** Annotate custom widgets with `Semantics`, `MergeSemantics`, or `ExcludeSemantics`.
6. **Verify:** Write widget tests using the `AccessibilityGuideline` API to validate tap targets, contrast, and labeling.

## Decision Logic
Use the following logic to determine the correct architectural approach:

* **Layout Strategy:**
  * If adjusting the placement or size of elements to fit available space -> Use **Responsive Design** (`LayoutBuilder`, `MediaQuery.sizeOf`).
  * If selecting entirely different components or input methods based on available space (e.g., Bottom Nav vs. Side Drawer) -> Use **Adaptive Design**.
* **Semantics Strategy:**
  * If using standard Material/Cupertino widgets -> Rely on built-in semantics.
  * If building custom interactive widgets -> Wrap in `Semantics` and assign an explicit `SemanticsRole`.
  * If hiding purely decorative elements from screen readers -> Wrap in `ExcludeSemantics`.
  * If combining multiple related elements into a single screen reader focus node -> Wrap in `MergeSemantics`.
* **Input Handling:**
  * If adding hover effects or changing the mouse cursor -> Use `MouseRegion`.
  * If adding keyboard shortcuts or tab traversal -> Use `FocusableActionDetector` or `Shortcuts`.

## Best Practices

### Mandatory Accessibility Checklist
Enforce this checklist as a key criterion before shipping any Flutter app:
* **Active Interactions:** Ensure all active interactions provide feedback (e.g., `onPressed` must not be a silent no-op).
* **Screen Reader Testing:** Verify all controls are described intelligibly for TalkBack (Android) and VoiceOver (iOS).
* **Contrast Ratios:** Maintain a contrast ratio of at least 4.5:1 for small text and 3.0:1 for large text (18pt+ regular or 14pt+ bold).
* **Context Switching:** Do not change the user's context automatically without explicit confirmation.
* **Tap Targets:** Ensure all interactive elements have a minimum tap target size of 48x48 dp (Android) or 44x44 pts (iOS).
* **Error Handling:** Allow important actions to be undone and suggest corrections in error fields.
* **Visual Accessibility:** Ensure controls are legible in colorblind/grayscale modes and support large OS-level font scale factors.

### Adaptive & Responsive Guardrails
* **Do not lock app orientation.** Support both portrait and landscape modes to accommodate multi-window and foldable use cases.
* **Avoid device orientation-based layouts.** Do not use `MediaQuery.orientation` to drive layout logic. Use `MediaQuery.sizeOf(context)` or `LayoutBuilder` instead.
* **Avoid checking hardware types.** Do not write logic that checks if a device is a "phone" or "tablet". Base layout decisions on available window size.
* **Solve touch first.** Perfect the touch interface, then layer on mouse and keyboard accelerators.
* **Restore list state.** Use `PageStorageKey` to maintain scroll positions in lists when the device orientation or window size changes.

### Web Accessibility
* Enable web accessibility programmatically if required by the project using `SemanticsBinding.instance.ensureSemantics();`.
* Map custom Flutter widgets to HTML DOM equivalents by explicitly defining `SemanticsRole` (e.g., `SemanticsRole.button`, `SemanticsRole.list`).

## Examples

### Example 1: Custom Semantic Widget with Hover and Keyboard Support
Demonstrates how to build a custom, accessible button that supports touch, mouse hover, keyboard focus, and screen readers.

```dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class AccessibleCustomButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;

  const AccessibleCustomButton({
    super.key,
    required this.onPressed,
    required this.label,
  });

  @override
  State<AccessibleCustomButton> createState() => _AccessibleCustomButtonState();
}

class _AccessibleCustomButtonState extends State<AccessibleCustomButton> {
  bool _isHovered = false;
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      role: SemanticsRole.button,
      label: widget.label,
      button: true,
      enabled: true,
      child: FocusableActionDetector(
        onFocusChange: (value) => setState(() => _hasFocus = value),
        onShowHoverHighlight: (value) => setState(() => _isHovered = value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<Intent>(
            onInvoke: (intent) {
              widget.onPressed();
              return null;
            },
          ),
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              Focus.of(context).requestFocus();
              widget.onPressed();
            },
            child: Container(
              // Ensure minimum tap target size of 48x48
              constraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: _isHovered || _hasFocus ? Colors.blue[700] : Colors.blue,
                border: _hasFocus ? Border.all(color: Colors.white, width: 2.0) : null,
                borderRadius: BorderRadius.circular(8.0),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

### Example 2: Accessibility Testing
Demonstrates how to enforce accessibility guidelines in widget tests.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/widgets/accessible_custom_button.dart'; // Adjust path as needed

void main() {
  testWidgets('AccessibleCustomButton meets accessibility guidelines', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AccessibleCustomButton(
            label: 'Submit',
            onPressed: () {},
          ),
        ),
      ),
    );

    // Check Android tap target size (48x48)
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    
    // Check iOS tap target size (44x44)
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    
    // Check that tappable nodes are labeled
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    
    // Check text contrast (minimum 4.5:1 for standard text)
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    
    handle.dispose();
  });
}
```

### Example 3: Enabling Web Accessibility Programmatically
Demonstrates how to force the semantics tree to build for web targets.

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

void main() {
  runApp(const MyApp());
  
  // Force accessibility DOM tree generation on Web
  if (kIsWeb) {
    SemanticsBinding.instance.ensureSemantics();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Accessible Web App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Accessibility is enabled by default on web.'),
        ),
      ),
    );
  }
}
```
