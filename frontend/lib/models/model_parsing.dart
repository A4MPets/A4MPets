import 'dart:convert';

import 'report_comment_record.dart';

int readInt(Object? value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int? readOptionalInt(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double readDouble(Object? value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

bool readBool(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final String normalized = value.trim().toLowerCase();
    if (<String>{'1', 'true', 'yes', 'si', 'sí'}.contains(normalized)) {
      return true;
    }
    if (<String>{'0', 'false', 'no'}.contains(normalized)) {
      return false;
    }
  }
  return fallback;
}

DateTime? readDateTime(Object? value) {
  final int? millis = readOptionalInt(value);
  if (millis != null) return DateTime.fromMillisecondsSinceEpoch(millis);
  if (value is String && value.trim().isNotEmpty) return DateTime.tryParse(value);
  return null;
}

DateTime readDateTimeOr(Object? value, int fallbackMs) {
  return readDateTime(value) ?? DateTime.fromMillisecondsSinceEpoch(fallbackMs);
}

List<ReportCommentRecord> readReportComments(Object? value) {
  final List<dynamic> raw = jsonDecode(value as String? ?? '[]') as List<dynamic>;
  return raw.map((dynamic item) => ReportCommentRecord.fromMap(item as Map<String, dynamic>)).toList(growable: false);
}

String writeReportComments(List<ReportCommentRecord> comments) {
  return jsonEncode(comments.map((ReportCommentRecord c) => c.toMap()).toList());
}
