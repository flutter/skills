// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Parameters for generating a skill from resources.
class SkillParams {
  /// Creates a new [SkillParams] instance.
  SkillParams({
    required this.name,
    required this.description,
    required this.resources,
    this.instructions,
    this.examplePrompt,
  });

  /// Creates a [SkillParams] instance from a JSON map.
  factory SkillParams.fromJson(Map<String, dynamic> json) {
    return SkillParams(
      name: json['name'] as String,
      description: json['description'] as String,
      resources: (json['resources'] as List).cast<String>(),
      instructions: json['instructions'] as String?,
      examplePrompt: json['examplePrompt'] as String?,
    );
  }

  /// The name of the skill.
  final String name;

  /// The description of the skill.
  final String description;

  /// The example prompt for the skill.
  final String? examplePrompt;

  /// Optional instructions for generating the skill.
  final String? instructions;

  /// The resources to fetch content from.
  final List<String> resources;
}
