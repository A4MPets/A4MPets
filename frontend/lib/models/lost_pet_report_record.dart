import 'dart:convert';

import 'report_comment_record.dart';

class LostPetReportRecord {
  final int id;
  final String localUuid;
  final String? remoteId;
  final String syncStatus;
  final DateTime lastModifiedAt;
  final int? petId;
  final String petLocalUuid;
  final double lastSeenLatitude;
  final double lastSeenLongitude;
  final String details;
  final DateTime disappearanceDate;
  final String? photoUrl;
  final String? petPhotoUrl;
  final String? phone;
  final List<ReportCommentRecord> comments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool needsSync;

  const LostPetReportRecord({
    required this.id,
    required this.localUuid,
    required this.remoteId,
    required this.syncStatus,
    required this.lastModifiedAt,
    required this.petId,
    required this.petLocalUuid,
    required this.lastSeenLatitude,
    required this.lastSeenLongitude,
    required this.details,
    required this.disappearanceDate,
    required this.photoUrl,
    required this.petPhotoUrl,
    required this.phone,
    required this.comments,
    required this.createdAt,
    required this.updatedAt,
    required this.needsSync,
  });

  factory LostPetReportRecord.fromMap(Map<String, Object?> map) {
    final String commentsJson = map['comments_json'] as String? ?? '[]';
    final List<dynamic> rawComments = jsonDecode(commentsJson) as List<dynamic>;
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int createdAtMs = (map['created_at'] as num?)?.toInt() ?? nowMs;
    final int updatedAtMs = (map['updated_at'] as num?)?.toInt() ?? createdAtMs;
    final int lastModifiedMs =
        (map['last_modified_at'] as num?)?.toInt() ?? updatedAtMs;
    final int disappearanceDateMs =
        (map['disappearance_date'] as num?)?.toInt() ?? createdAtMs;

    return LostPetReportRecord(
      id: (map['id'] as num?)?.toInt() ?? 0,
      localUuid:
          map['local_uuid'] as String? ?? 'lost-${map['id'] ?? createdAtMs}',
      remoteId: map['remote_id']?.toString(),
      syncStatus: map['sync_status'] as String? ?? 'created',
      lastModifiedAt: DateTime.fromMillisecondsSinceEpoch(lastModifiedMs),
      petId: (map['pet_id'] as num?)?.toInt(),
      petLocalUuid: map['pet_local_uuid'] as String? ?? '',
      lastSeenLatitude: (map['last_seen_latitude'] as num).toDouble(),
      lastSeenLongitude: (map['last_seen_longitude'] as num).toDouble(),
      details: map['details'] as String? ?? '',
      disappearanceDate: DateTime.fromMillisecondsSinceEpoch(
        disappearanceDateMs,
      ),
      photoUrl: map['photo_url'] as String?,
      petPhotoUrl: map['pet_photo_url'] as String?,
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
      'pet_id': petId,
      'pet_local_uuid': petLocalUuid,
      'last_seen_latitude': lastSeenLatitude,
      'last_seen_longitude': lastSeenLongitude,
      'details': details,
      'disappearance_date': disappearanceDate.millisecondsSinceEpoch,
      'photo_url': photoUrl,
      'pet_photo_url': petPhotoUrl,
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
