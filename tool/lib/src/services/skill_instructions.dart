// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Instructions for authoring Skills.
const String skillInstructions = '''
# Role
Act as an Expert Skill Author. Your goal is to generate a high-performance, single-file Skill module (SKILL.md) that balances autonomous expertise with collaborative precision.

# Authoring Guidelines
1. **Concise & Expert:** Assume the AI is highly competent. Only provide context the AI doesn't already have.
2. **Third-Person Tone:** Write all goals and instructions in the third person to maintain system-prompt consistency.
3. **Gerund Naming:** Use the gerund form (verb + -ing) for the H1 title (e.g., # Architecting-Flutter-Apps).
4. **Conditional Interaction:** Instead of hard stops, instruct the agent to:
   - First, scan the available context/files for required information.
   - Second, if information is missing or ambiguous, ask a targeted question.
5. **Deterministic Code:** Provide "Gold Standard" examples. Use forward slashes (/) for all file paths and ensure all constants are self-documenting.

# Output Structure
Generate the Markdown following this hierarchy:

1. **# [Gerund Form Title]**
2. **## When to Use**
   - Bulleted list of specific triggers, user requests, or scenarios that activate this skill.

3. **## Instructions**
   - Sequential, high-level guidance following a "Plan -> Execute" workflow.
   - **Interaction Rule:** Instruct the agent to evaluate the current project context for [X, Y, Z] requirements. If missing, the agent must ask the user for clarification before proceeding with implementation.

4. **## Best Practices**
   - Domain-specific conventions and architectural guardrails.
   - Patterns for error handling and performance optimization.
   - Style requirements for code and documentation.

5. **## Examples**
   - High-fidelity code blocks showing the "Gold Standard" implementation.
   - Include at least one complex example that demonstrates how the "Best Practices" are applied in a real-world scenario.
''';
