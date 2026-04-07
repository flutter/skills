// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'models/analysis_severity.dart';
import 'models/check_type.dart';

/// URL for frontmatter documentation.
const metadataUrl = 'https://agentskills.io/specification#frontmatter';

/// Template instance for checking disallowed fields in YAML metadata.
const disallowedFieldCheck = CheckType(
  name: 'disallowed-field',
  defaultSeverity: AnalysisSeverity.disabled,
);

/// URL for compatibility field documentation.
const compatibilityFieldUrl = 'https://agentskills.io/specification#compatibility-field';

/// Template instance for checking if YAML metadata is valid.
const validYamlMetadataCheck = CheckType(
  name: 'valid-yaml-metadata',
  defaultSeverity: AnalysisSeverity.error,
);

/// URL for description field documentation.
const descriptionFieldUrl = 'https://agentskills.io/specification#description-field';

/// Template instance for checking if description is too long.
const descriptionTooLongCheck = CheckType(
  name: 'description-too-long',
  defaultSeverity: AnalysisSeverity.error,
);

/// URL for name field documentation.
const nameFieldUrl = 'https://agentskills.io/specification#name-field';

/// Template instance for checking if skill name is invalid.
const invalidSkillNameCheck = CheckType(
  name: 'invalid-skill-name',
  defaultSeverity: AnalysisSeverity.error,
);

/// URL for directory structure documentation.
const dirStructureUrl = 'https://agentskills.io/specification#directory-structure';

/// Template instance for checking if file path does not exist.
const pathDoesNotExistCheck = CheckType(
  name: 'path-does-not-exist',
  defaultSeverity: AnalysisSeverity.error,
);

/// Template instance for checking relative file paths.
const relativePathsCheck = CheckType(
  name: 'check-relative-paths',
  defaultSeverity: AnalysisSeverity.disabled,
);

/// Template instance for checking absolute file paths.
const absolutePathsCheck = CheckType(
  name: 'check-absolute-paths',
  defaultSeverity: AnalysisSeverity.warning,
);
