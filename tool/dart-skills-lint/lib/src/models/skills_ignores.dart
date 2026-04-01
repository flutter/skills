import 'package:json_annotation/json_annotation.dart';
import 'ignore_entry.dart';

part 'skills_ignores.g.dart';

/// Represents the top-level structure of the skills ignore JSON file.
@JsonSerializable(explicitToJson: true)
class SkillsIgnores {
  SkillsIgnores({required this.skills});

  /// Creates a SkillsIgnores from a JSON map.
  factory SkillsIgnores.fromJson(Map<String, dynamic> json) => _$SkillsIgnoresFromJson(json);

  /// Map of skill names to their list of ignore entries.
  final Map<String, List<IgnoreEntry>> skills;

  /// Converts a SkillsIgnores to a JSON map.
  Map<String, dynamic> toJson() => _$SkillsIgnoresToJson(this);
}
