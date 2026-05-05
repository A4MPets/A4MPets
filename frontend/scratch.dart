import 'dart:convert';

import 'lib/models/generic_report_record.dart';

void main() {
  final GenericReportRecord record = GenericReportRecord(
    id: 1,
    localUuid: 'uuid',
    remoteId: 'remote',
    syncStatus: 'sync',
    lastModifiedAt: DateTime.now(),
    latitude: 1.0,
    longitude: 1.0,
    description: 'desc',
    reportedDate: DateTime.now(),
    riskLevelCode: 'low',
    impactRadiusMeters: 10,
    photoUrl: null,
    reportedByUsername: 'Anonimo',
    comments: [],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    needsSync: false,
  );

  final Map<String, Object?> map = record.toMap();
  final String jsonStr = jsonEncode(map);
  final dynamic decoded = jsonDecode(jsonStr);

  try {
    final GenericReportRecord newRecord = GenericReportRecord.fromMap(
      decoded as Map<String, Object?>,
    );
    print('Success! $newRecord');
  } catch (e, stack) {
    print('Error: $e');
    print(stack);
  }
}
