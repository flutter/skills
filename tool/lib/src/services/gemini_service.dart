// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:google_cloud_ai_generativelanguage_v1beta/generativelanguage.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:retry/retry.dart';
import 'package:yaml_writer/yaml_writer.dart';

import 'markdown_converter.dart';
import 'skill_instructions.dart';

/// Service for interacting with the Gemini API to generate and validate skills.
class GeminiService {
  /// Creates a new [GeminiService].
  GeminiService({
    required String apiKey,
    http.Client? httpClient,
    String? model,
  }) : _model = model ?? defaultModel,
       _client = _ApiKeyClient(httpClient ?? http.Client(), apiKey);

  /// 0.2 is a good temperature for technical material.
  static const double defaultTemperature = 0.2;

  /// The default model to use for generation.
  static const String defaultModel = 'models/gemini-3.1-pro-preview';

  /// The default token budget for thinking.
  static const int defaultThinkingBudget = 4096;

  /// The default max output tokens for generation.
  static const int defaultMaxOutputTokens = 8192;

  /// The default safety settings to use for generation.
  static final List<SafetySetting> defaultSafetySettings = [
    SafetySetting(
      category: HarmCategory.harmCategoryDangerousContent,
      threshold: SafetySetting_HarmBlockThreshold.blockOnlyHigh,
    ),
    SafetySetting(
      category: HarmCategory.harmCategoryHateSpeech,
      threshold: SafetySetting_HarmBlockThreshold.blockOnlyHigh,
    ),
    SafetySetting(
      category: HarmCategory.harmCategoryHarassment,
      threshold: SafetySetting_HarmBlockThreshold.blockOnlyHigh,
    ),
    SafetySetting(
      category: HarmCategory.harmCategorySexuallyExplicit,
      threshold: SafetySetting_HarmBlockThreshold.blockOnlyHigh,
    ),
  ];

  final String _model;
  final http.Client _client;
  final Logger _logger = Logger('GeminiService');

  /// Generates the content for a skill based on raw markdown input.
  Future<String?> generateSkillContent(
    String rawMarkdown,
    String skillName,
    String description, {
    String? instructions,
    int thinkingBudget = defaultThinkingBudget,
  }) async {
    final service = GenerativeService(client: _client);
    final lastModified = io.HttpDate.format(DateTime.now());
    final prompt = _createSkillPrompt(rawMarkdown, instructions);

    final request = _createRequest(
      prompt,
      systemInstruction: skillInstructions,
      thinkingBudget: thinkingBudget,
    );

    _logger.fine(
      '  Model: $_model, Max Output Tokens: $defaultMaxOutputTokens, Thinking Budget: $thinkingBudget',
    );

    try {
      const r = RetryOptions(maxAttempts: 3);
      final response = await r.retry(() async {
        final res = await service.generateContent(request);
        final text = res.candidates.first.content?.parts
            .where((part) => !part.thought)
            .map((part) => part.text)
            .where((text) => text != null)
            .join('\n');

        if (text == null || text.isEmpty) {
          throw const FormatException('Empty response from Gemini');
        }

        return text;
      }, onRetry: (e) => _logger.warning('Retrying Gemini generation: $e'));

      final content = response;

      final frontMatterMap = {
        'name': skillName,
        'description': description,
        'metadata': {'model': _model, 'last_modified': lastModified},
      };

      final frontmatter = '---\n${YamlWriter().write(frontMatterMap)}\n---\n';

      return frontmatter + (cleanContent(content) ?? '');
    } on Object catch (e) {
      _logger.severe('Gemini generation failed: $e');
      return null;
    }
  }

  /// Validate Existing Skill
  Future<String?> validateExistingSkillContent(
    String markdown,
    String skillName,
    String instructions,
    String generationDate,
    String modelName,
    String currentSkillContent, {
    int thinkingBudget = defaultThinkingBudget,
  }) async {
    final service = GenerativeService(client: _client);
    final validationPrompt =
        '''
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

    final request = _createRequest(
      validationPrompt,
      systemInstruction: skillInstructions,
      thinkingBudget: thinkingBudget,
    );

    _logger.fine(
      '  Model: $_model, Max Output Tokens: $defaultMaxOutputTokens, Thinking Budget: $thinkingBudget',
    );

    try {
      const r = RetryOptions(maxAttempts: 3);
      final response = await r.retry(() async {
        final res = await service.generateContent(request);
        final text = res.candidates.first.content?.parts
            .where((part) => !part.thought)
            .map((part) => part.text)
            .where((text) => text != null)
            .join('\n');

        if (text == null || text.isEmpty) {
          throw const FormatException('Empty response from Gemini');
        }

        return text;
      }, onRetry: (e) => _logger.warning('Retrying Gemini validation: $e'));

      return response;
    } on Object catch (e) {
      _logger.severe('Gemini validation failed: $e');
      return null;
    }
  }

  /// Cleans the generated content by removing markdown code blocks and frontmatter.
  @visibleForTesting
  String? cleanContent(String? content) {
    if (content == null) return null;
    var cleaned = content;
    final startMatch = RegExp(
      r'^\s*```[a-zA-Z]*\s*\n',
      caseSensitive: false,
    ).firstMatch(cleaned);
    if (startMatch != null) {
      cleaned = cleaned.substring(startMatch.end);
      // Remove the last triple backticks if they exist
      cleaned = cleaned.replaceAll(RegExp(r'\n```\s*$'), '');
    }

    final yamlStartIndex = cleaned.indexOf('---');
    if (yamlStartIndex == 0) {
      // Possible frontmatter, skip it
      final end = cleaned.indexOf('---', 3);
      if (end != -1) {
        cleaned = cleaned.substring(end + 3).trim();
      }
    } else if (yamlStartIndex > 0) {
      // Maybe noise before frontmatter, try to strip it if it looks like frontmatter
      final end = cleaned.indexOf('---', yamlStartIndex + 3);
      if (end != -1) {
        cleaned = cleaned.substring(end + 3).trim();
      }
    }

    // Ensure one trailing newline
    return '${cleaned.trim()}\n';
  }

  String _createSkillPrompt(String markdown, String? instructions) {
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

  GenerateContentRequest _createRequest(
    String prompt, {
    String? systemInstruction,
    int thinkingBudget = defaultThinkingBudget,
  }) {
    return GenerateContentRequest(
      model: _model,
      systemInstruction: systemInstruction != null
          ? Content(parts: [Part(text: systemInstruction)])
          : null,
      contents: [
        Content(parts: [Part(text: prompt)]),
      ],
      // See [GenerationConfig] in package:google_cloud_ai_generativelanguage_v1beta
      generationConfig: GenerationConfig(
        temperature: defaultTemperature,
        maxOutputTokens: defaultMaxOutputTokens,
        thinkingConfig: thinkingBudget > 0
            ? ThinkingConfig(
                includeThoughts: true,
                thinkingBudget: thinkingBudget,
              )
            : null,
      ),
      safetySettings: defaultSafetySettings,
    );
  }
}

class _ApiKeyClient extends http.BaseClient {
  _ApiKeyClient(this._inner, this._apiKey);

  final http.Client _inner;
  final String _apiKey;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['x-goog-api-key'] = _apiKey;
    return _inner.send(request);
  }
}

/// Fetches and converts content from a list of resources.
///
/// Throws an [Exception] if fetching any resource fails. This strict behavior
/// prevents wasting Gemini tokens on generating low-quality skills when
/// source material is missing.
Future<String> fetchAndConvertContent(
  List<String> resources,
  http.Client httpClient,
  Logger logger, {
  io.Directory? configDir,
}) async {
  final converter = MarkdownConverter();
  final sb = StringBuffer();
  for (final resource in resources) {
    logger.fine('  Fetching $resource...');

    if (resource.startsWith('http://')) {
      throw Exception(
        'Insecure HTTP URL found: $resource. '
        'Only HTTPS URLs or relative file paths are allowed.',
      );
    }

    if (resource.startsWith('https://')) {
      final response = await httpClient.get(Uri.parse(resource));
      if (response.statusCode == 200) {
        sb
          ..writeln('--- Raw content from $resource ---')
          ..writeln(converter.convert(response.body));
      } else {
        throw Exception(
          'Failed to fetch $resource: HTTP ${response.statusCode}. '
          'Failing fast to save Gemini tokens.',
        );
      }
    } else {
      if (configDir == null) {
        throw Exception(
          'Relative resource "$resource" found, but no configuration '
          'directory was provided to resolve it.',
        );
      }
      final file = io.File(p.join(configDir.path, resource));
      if (!file.existsSync()) {
        throw Exception('Local resource file not found: ${file.path}');
      }

      final String content;
      try {
        content = file.readAsStringSync();
      } on io.FileSystemException {
        throw Exception('Local resource file is not readable: ${file.path}');
      }

      sb
        ..writeln('--- Raw content from $resource ---')
        ..writeln(content);
    }
  }
  return sb.toString();
}
