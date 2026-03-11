---
name: "flutter-accessibility"
description: "Configure your Flutter app to support assistive technologies like Screen Readers"
metadata:
  model: "models/gemini-3.1-pro-preview"
  last_modified: "Wed, 11 Mar 2026 17:41:44 GMT"

---
# Implementing-Flutter-Accessibility-And-Adaptive-Design

## Goal
The agent implements universal access and adaptive layouts in Flutter applications, ensuring compliance with WCAG standards and seamless operation across mobile, web, and desktop form factors.

## When to Use
* The project requires support for screen readers, keyboard navigation, or assistive technologies.
* The application targets multiple platforms (iOS, Android, Web, Desktop) requiring responsive layouts.
* The user requests an accessibility audit or integration of semantic roles.
* Custom widgets require mouse hover, scroll wheel, or focus traversal support.

## Decision Logic
Follow this logic tree when determining how to handle layout and input adaptations:

* **Layout Strategy:**
  * If the widget layout depends on its parent's constraints -> Use `LayoutBuilder`.
  * If the widget layout depends on the overall window/screen size -> Use `MediaQuery.sizeOf(context)`.
  * If preserving scroll state during orientation changes -> Use `PageStorageKey`.
* **Input Handling:**
  * If a custom widget requires hover effects -> Wrap in `MouseRegion`.
  * If a custom widget requires keyboard shortcuts -> Use `Shortcuts` and `Actions`.
  * If a custom widget requires focus highlights and tab traversal -> Use `FocusableActionDetector`.
* **Accessibility:**
  * If using standard Material/Cupertino widgets -> Rely on built-in semantics.
  * If building a custom widget -> Wrap in `Semantics` and assign the appropriate `SemanticsRole`.
  * If targeting Flutter Web -> Programmatically enable semantics using `SemanticsBinding.instance.ensureSemantics()` or provide an ARIA opt-in button.

## Instructions
1. Evaluate the current project context for target platforms, existing accessibility configurations, and responsive layout requirements.
2. **Interaction Rule:** If target platforms or accessibility compliance standards (e.g., WCAG 2.1 AA) are not explicitly defined in the project context, ask the user for clarification before proceeding with implementation.
3. Plan the widget hierarchy. Break down complex widgets into smaller, `const` widgets to optimize rebuilds and simplify adaptive logic.
4. Execute layout adaptations using `LayoutBuilder` and `MediaQuery.sizeOf`. Do not lock device orientation.
5. Execute accessibility enhancements by applying `Semantics`, ensuring minimum tap targets, and verifying contrast ratios.
6. Implement input accelerators (keyboard shortcuts, mouse hover, scroll wheel) for desktop and web targets.
7. Write widget tests using the `AccessibilityGuideline` API to prevent regressions.

## Best Practices

### Accessibility Release Checklist
Enforce this checklist as a key criterion before shipping any app:
* **Active interactions:** Ensure all active interactions trigger an action or provide feedback (e.g., show a `SnackBar` for unimplemented buttons).
* **Screen reader testing:** Verify the screen reader describes all controls intelligibly.
* **Contrast ratios:** Maintain a contrast ratio of at least 4.5:1 for small text and 3.0:1 for large text (18pt+ regular or 14pt+ bold).
* **Context switching:** Do not change the user's context automatically without confirmation.
* **Tap target size:** Enforce a minimum tap target size of 48x48 logical pixels (44x44 on iOS).
* **Errors:** Provide undo capabilities for important actions and suggest corrections for form errors.
* **Color vision deficiency:** Verify controls are usable and legible in colorblind and grayscale modes.
* **Scale factors:** Ensure the UI remains legible and usable at maximum OS text scale factors.

### Adaptive Design Guardrails
* **Do not lock app orientation.** Support both portrait and landscape modes to accommodate multi-window and foldable devices.
* **Avoid hardware type checks.** Do not use `Platform.isAndroid` or similar checks to determine layout. Always use `MediaQuery` to measure available window space.
* **Solve touch first.** Build and polish the touch interface initially, then layer on mouse and keyboard accelerators.
* **Do not consume infinite horizontal space.** Constrain text fields and lists on large screens to prevent them from stretching across the entire monitor.

## Examples

### Example 1: Adaptive Custom Button with Accessibility and Hover
This example demonstrates a "Gold Standard" custom widget that handles touch, mouse hover, keyboard focus, and screen reader semantics.

```dart
// lib/widgets/adaptive_semantic_button.dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class AdaptiveSemanticButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final String? tooltip;

  const AdaptiveSemanticButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.tooltip,
  });

  @override
  State<AdaptiveSemanticButton> createState() => _AdaptiveSemanticButtonState();
}

class _AdaptiveSemanticButtonState extends State<AdaptiveSemanticButton> {
  bool _isHovered = false;
  bool _isFocused = false;

  void _handleFocusChange(bool hasFocus) {
    setState(() {
      _isFocused = hasFocus;
    });
  }

  void _handleHoverChange(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Minimum tap target size of 48x48 for accessibility
    const double minTargetSize = 48.0;

    return Semantics(
      button: true,
      label: widget.label,
      tooltip: widget.tooltip,
      onTap: widget.onPressed,
      child: FocusableActionDetector(
        onFocusChange: _handleFocusChange,
        onShowHoverHighlight: _handleHoverChange,
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<Intent>(
            onInvoke: (Intent intent) {
              widget.onPressed();
              return null;
            },
          ),
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onPressed,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: minTargetSize,
                minHeight: minTargetSize,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: _isHovered ? Colors.blue.shade700 : Colors.blue,
                  border: _isFocused
                      ? Border.all(color: Colors.white, width: 2.0)
                      : Border.all(color: Colors.transparent, width: 2.0),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                  ),
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
Implement automated tests to ensure UI components meet Flutter's accessibility guidelines.

```dart
// test/accessibility_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/widgets/adaptive_semantic_button.dart';

void main() {
  testWidgets('AdaptiveSemanticButton meets accessibility guidelines', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveSemanticButton(
            label: 'Submit',
            onPressed: () {},
          ),
        ),
      ),
    );

    // Check that tappable nodes have a minimum size of 48x48 pixels (Android standard)
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

    // Check that tappable nodes have a minimum size of 44x44 pixels (iOS standard)
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

    // Check that touch targets with a tap action are labeled
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    // Check whether semantic nodes meet the minimum text contrast levels (4.5:1)
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    handle.dispose();
  });
}
```
