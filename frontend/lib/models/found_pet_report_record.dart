import 'model_parsing.dart';
import 'report_comment_record.dart';

class FoundPetReportRecord {
  final int id;
  final String localUuid, syncStatus;
  final String? remoteId, petLocalUuid, photoUrl, petPhotoUrl, phone;
  final DateTime lastModifiedAt, foundDate, createdAt, updatedAt;
  final int? petId, matchedLostPetReportId;
  final double latitude, longitude;
  final String details;
  final List<ReportCommentRecord> comments;
  final bool needsSync;

  const FoundPetReportRecord({
    required this.id,
    required this.localUuid,
    required this.remoteId,
    required this.syncStatus,
    required this.lastModifiedAt,
    required this.petId,
    required this.petLocalUuid,
    required this.matchedLostPetReportId,
    required this.latitude,
    required this.longitude,
    required this.details,
    required this.foundDate,
    required this.photoUrl,
    required this.petPhotoUrl,
    required this.phone,
    required this.comments,
    required this.createdAt,
    required this.updatedAt,
    required this.needsSync,
  });

  factory FoundPetReportRecord.fromMap(Map<String, Object?> map) {
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int createdAtMs = readInt(map['created_at'], nowMs);
    final int updatedAtMs = readInt(map['updated_at'], createdAtMs);

    return FoundPetReportRecord(
      id: readInt(map['id']),
      localUuid: map['local_uuid'] as String? ?? 'found-${map['id'] ?? createdAtMs}',
      remoteId: map['remote_id']?.toString(),
      syncStatus: map['sync_status'] as String? ?? 'created',
      lastModifiedAt: readDateTimeOr(map['last_modified_at'], updatedAtMs),
      petId: readOptionalInt(map['pet_id']),
      petLocalUuid: map['pet_local_uuid'] as String?,
      matchedLostPetReportId: readOptionalInt(map['matched_lost_pet_report_id']),
      latitude: readDouble(map['latitude']),
      longitude: readDouble(map['longitude']),
      details: map['details'] as String? ?? '',
      foundDate: readDateTimeOr(map['found_date'], createdAtMs),
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
      'matched_lost_pet_report_id': matchedLostPetReportId,
      'latitude': latitude,
      'longitude': longitude,
      'details': details,
      'found_date': foundDate.millisecondsSinceEpoch,
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
