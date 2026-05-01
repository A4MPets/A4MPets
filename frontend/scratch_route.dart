import 'dart:convert';
import 'lib/models/route_record.dart';

void main() {
  final RouteRecord record = RouteRecord(
    id: 1,
    remoteId: 'remote',
    name: 'test',
    points: [RoutePoint(latitude: 1.0, longitude: 1.0)],
    syncStatus: 'synced',
    lastModifiedAt: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    needsSync: false,
  );

  final Map<String, Object?> map = record.toMap();
  final String jsonStr = jsonEncode(map);
  final dynamic decoded = jsonDecode(jsonStr);

  try {
    final RouteRecord newRecord = RouteRecord.fromMap(decoded as Map<String, Object?>);
    print('Success! $newRecord');
  } catch (e, stack) {
    print('Error: $e');
    print(stack);
  }
}
