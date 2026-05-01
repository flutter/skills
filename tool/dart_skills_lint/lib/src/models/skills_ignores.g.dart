// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skills_ignores.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SkillsIgnores _$SkillsIgnoresFromJson(Map<String, dynamic> json) => SkillsIgnores(
  skills: (json['skills'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(
      k,
      (e as List<dynamic>).map((e) => IgnoreEntry.fromJson(e as Map<String, dynamic>)).toList(),
    ),
  ),
);

Map<String, dynamic> _$SkillsIgnoresToJson(SkillsIgnores instance) => <String, dynamic>{
  'skills': instance.skills.map((k, e) => MapEntry(k, e.map((e) => e.toJson()).toList())),
};
