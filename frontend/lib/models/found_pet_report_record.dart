import 'dart:convert';

import 'report_comment_record.dart';

class FoundPetReportRecord {
  final int id;
  final String localUuid;
  final String? remoteId;
  final String syncStatus;
  final DateTime lastModifiedAt;
  final double latitude;
  final double longitude;
  final String details;
  final DateTime foundDate;
  final String? photoUrl;
  final String? phone;
  final List<ReportCommentRecord> comments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool needsSync;

  const FoundPetReportRecord({
    required this.id,
    required this.localUuid,
    required this.remoteId,
    required this.syncStatus,
    required this.lastModifiedAt,
    required this.latitude,
    required this.longitude,
    required this.details,
    required this.foundDate,
    required this.photoUrl,
    required this.phone,
    required this.comments,
    required this.createdAt,
    required this.updatedAt,
    required this.needsSync,
  });

  factory FoundPetReportRecord.fromMap(Map<String, Object?> map) {
    final String commentsJson = map['comments_json'] as String? ?? '[]';
    final List<dynamic> rawComments = jsonDecode(commentsJson) as List<dynamic>;
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int createdAtMs = (map['created_at'] as num?)?.toInt() ?? nowMs;
    final int updatedAtMs = (map['updated_at'] as num?)?.toInt() ?? createdAtMs;
    final int lastModifiedMs =
        (map['last_modified_at'] as num?)?.toInt() ?? updatedAtMs;
    final int foundDateMs = (map['found_date'] as num?)?.toInt() ?? createdAtMs;

    return FoundPetReportRecord(
      id: (map['id'] as num?)?.toInt() ?? 0,
      localUuid:
          map['local_uuid'] as String? ?? 'found-${map['id'] ?? createdAtMs}',
      remoteId: map['remote_id']?.toString(),
      syncStatus: map['sync_status'] as String? ?? 'created',
      lastModifiedAt: DateTime.fromMillisecondsSinceEpoch(lastModifiedMs),
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      details: map['details'] as String? ?? '',
      foundDate: DateTime.fromMillisecondsSinceEpoch(foundDateMs),
      photoUrl: map['photo_url'] as String?,
      phone: map['phone'] as String?,
      comments: rawComments
          .map(
            (dynamic item) =>
                ReportCommentRecord.fromMap(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMs),
      needsSync: (map['needs_sync'] as int? ?? 0) == 1,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'local_uuid': localUuid,
      'remote_id': remoteId,
      'sync_status': syncStatus,
      'last_modified_at': lastModifiedAt.millisecondsSinceEpoch,
      'latitude': latitude,
      'longitude': longitude,
      'details': details,
      'found_date': foundDate.millisecondsSinceEpoch,
      'photo_url': photoUrl,
      'phone': phone,
      'comments_json': jsonEncode(
        comments.map((ReportCommentRecord c) => c.toMap()).toList(),
      ),
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'needs_sync': needsSync ? 1 : 0,
    };
  }
}
