// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: avoid_classes_with_only_static_members

/// Manages prompts used by the GeminiService.
class Prompts {
  /// Creates the prompt for generating a new skill.
  static String createSkillPrompt(String markdown, String? instructions) {
    return '''
Rewrite the following technical documentation into a high-quality "SKILL.md" file.

DO NOT include any YAML frontmatter. Start immediately with the markdown content (e.g. headers).

**Guidelines:**
1. **Ignore Noise**: Exclude navigation bars, footers, "Edit this page" links, and other non-technical content.
2. **Decision Trees**: If the content describes a process with multiple choices or steps, YOU MUST create a "Decision Logic" or "Flowchart" section to guide the agent.
3. **Clarity**: Use clear headings, bullet points, and code blocks.
4. **Format**: Do NOT wrap the entire output in a markdown code block (like ```markdown ... ```). Return raw markdown text.
${instructions != null && instructions.isNotEmpty ? '5. **Special Instructions**: $instructions' : ''}

Raw Content:
$markdown
''';
  }

  /// Creates the prompt for validating an existing skill.
  static String validateExistingSkillContentPrompt(
    String markdown,
    String instructions,
    String generationDate,
    String modelName,
    String currentSkillContent,
  ) {
    return '''
Validate the following skill document against the provided source material and verify if it is valid.
Focus on:
1. Accuracy: Does the skill capture the technical details correctly based on the Source Material?
2. Structure: Is the skill well-structured according to skill best practices?
3. Completeness: Is any critical information missing in the skill that is present in the Source Material?

Context:
- The skill was originally generated on: $generationDate
- The current evaluation is using model: $modelName
- The instructions used to generate the skill were:
$instructions

Source Material:
$markdown

Current Skill Content:
  "$currentSkillContent"
---

Grade the current output based on the instructions and the comparison to current website content and instructions today.
Establish a conclusion on whether the new skill is valid or not.
Reasons for a good or bad quality grade should be provided including concepts such as missing content, different model used, more than a few months old, etc.
On the very last line, output "Grade: [0-100]" representing overall quality of the skill compared to the assumed value if it were generated again today.
''';
  }
}
