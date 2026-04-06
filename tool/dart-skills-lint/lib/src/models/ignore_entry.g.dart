// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ignore_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IgnoreEntry _$IgnoreEntryFromJson(Map<String, dynamic> json) => IgnoreEntry(
      ruleId: json['rule_id'] as String,
      fileName: json['file_name'] as String,
    );

Map<String, dynamic> _$IgnoreEntryToJson(IgnoreEntry instance) => <String, dynamic>{
      'rule_id': instance.ruleId,
      'file_name': instance.fileName,
    };
