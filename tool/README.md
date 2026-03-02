# Skills CLI

The Skills CLI simplifies the process of creating "Agent Skills" from external documentation. It allows you to crawl documentation websites to discover relevant pages and then uses Generative AI (Gemini) to convert those pages into structured `SKILL.md` files that agents can use.

## Context

*   [Agent Skills Best Practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

## Prerequisite

This tool requires the `GEMINI_API_KEY` environment variable to be set.

## Commands

### `generate-skill`

Generates `SKILL.md` files from a YAML configuration file. Use the `--skill` option to generate a specific skill.

**Usage:**
```bash
dart run skills generate-skill [options] [config_file]
```

**Arguments:**
*   `[config_file]`: Path to the YAML configuration file. Defaults to `resources/flutter_skills.yaml`.

**Options:**
*   `--skill`: Filter to generate only the specified skill by name.
*   `--directory` (`-d`): The directory to output the generated skill folder. Defaults to `../skills/`.

### `validate-skill`

Validates skills by re-generating and comparing with existing skills.

**Usage:**
```bash
dart run skills validate-skill [options] [config_file]
```

**Arguments:**
*   `[config_file]`: Path to the YAML configuration file. Defaults to `resources/flutter_skills.yaml`.

**Options:**
*   `--skill`: Validate only the specified skill by name.
*   `--directory` (`-d`): The directory containing the generated skills. Defaults to the output directory or `../skills/`.
*   `--thinking-budget`: The token budget for the model to "think" before generating content. Defaults to 2048.

**Example:**
Generate all skills defined in resources/flutter_skills.yaml to the skills/ directory:

```bash
dart run skills generate-skill
```

Generate only the 'flutter-layout' skill to a custom directory:

```
dart run skills generate-skill --skill flutter-layout --directory ../skills
```

### `validate-skill`

Validates generated skills by re-generating them using the same source and comparing the output. This is useful for testing prompts or verifying consistency.

**Usage:**
```bash
dart run skills validate-skill [options]
```

**Options:**
*   `--directory` (`-d`): The directory containing the generated skills to validate. Defaults to `skills/`.

**Example:**
Validate skills in the default 'skills' directory:

```bash
dart run skills validate-skill
```

Validate skills in a custom directory:
```
dart run skills validate-skill --directory ../validation_results
```

## Configuration

The default configuration file is located at `tool/resources/flutter_skills.yaml`. It contains a list of skill definitions:

```yaml
- name: flutter-layout
  description: "..."
  resources:
    - https://docs.flutter.dev/ui/widgets/layout
    - https://docs.flutter.dev/ui/layout
    - ../packages/flutter/lib/src/widgets/layout.md
```
