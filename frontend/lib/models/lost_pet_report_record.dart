import 'model_parsing.dart';
import 'report_comment_record.dart';

class LostPetReportRecord {
  final int id;
  final String localUuid, syncStatus;
  final String? remoteId, photoUrl, petPhotoUrl, phone;
  final DateTime lastModifiedAt, disappearanceDate, createdAt, updatedAt;
  final int? petId;
  final String petLocalUuid;
  final double lastSeenLatitude, lastSeenLongitude;
  final String details;
  final List<ReportCommentRecord> comments;
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
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int createdAtMs = readInt(map['created_at'], nowMs);
    final int updatedAtMs = readInt(map['updated_at'], createdAtMs);

    return LostPetReportRecord(
      id: readInt(map['id']),
      localUuid: map['local_uuid'] as String? ?? 'lost-${map['id'] ?? createdAtMs}',
      remoteId: map['remote_id']?.toString(),
      syncStatus: map['sync_status'] as String? ?? 'created',
      lastModifiedAt: readDateTimeOr(map['last_modified_at'], updatedAtMs),
      petId: readOptionalInt(map['pet_id']),
      petLocalUuid: map['pet_local_uuid'] as String? ?? '',
      lastSeenLatitude: readDouble(map['last_seen_latitude']),
      lastSeenLongitude: readDouble(map['last_seen_longitude']),
      details: map['details'] as String? ?? '',
      disappearanceDate: readDateTimeOr(map['disappearance_date'], createdAtMs),
      photoUrl: map['photo_url'] as String?,
      petPhotoUrl: map['pet_photo_url'] as String?,
      phone: map['phone'] as String?,
      comments: readReportComments(map['comments_json']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtMs),
      needsSync: readBool(map['needs_sync']),
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
      'comments_json': writeReportComments(comments),
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'needs_sync': needsSync ? 1 : 0,
    };
  }
}
