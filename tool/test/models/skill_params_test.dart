// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:skills/src/models/skill_params.dart';
import 'package:test/test.dart';

void main() {
  group('SkillParams', () {
    test('fromJson parses correctly without instructions', () {
      final json = {
        'name': 'test-skill',
        'description': 'Test Description',
        'resources': ['http://example.com'],
      };
      final skill = SkillParams.fromJson(json);
      expect(skill.name, 'test-skill');
      expect(skill.description, 'Test Description');
      expect(skill.resources, ['http://example.com']);
      expect(skill.instructions, isNull);
    });

    test('fromJson parses correctly with instructions', () {
      final json = {
        'name': 'test-skill',
        'description': 'Test Description',
        'instructions': 'Do not hallucinate.',
        'resources': ['http://example.com'],
      };
      final skill = SkillParams.fromJson(json);
      expect(skill.name, 'test-skill');
      expect(skill.description, 'Test Description');
      expect(skill.resources, ['http://example.com']);
      expect(skill.instructions, 'Do not hallucinate.');
    });
  });
}
