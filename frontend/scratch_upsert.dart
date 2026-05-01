import 'dart:convert';
import 'lib/models/route_record.dart';

void main() {
  List<RouteRecord> current = [];
  List<RouteRecord> batch = [
    RouteRecord(
      id: 0,
      remoteId: "99",
      name: "Remote Route",
      points: [],
      syncStatus: "synced",
      lastModifiedAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      needsSync: false,
    )
  ];

  int nextId = 1;

  for (final RouteRecord incoming in batch) {
    RouteRecord? existing;
    for (final RouteRecord route in current) {
      if (incoming.remoteId != null && route.remoteId == incoming.remoteId) {
        existing = route;
        break;
      }
    }

    if (existing == null && incoming.id > 0) {
        for (final RouteRecord route in current) {
            if (route.id == incoming.id && route.createdAt.millisecondsSinceEpoch == incoming.createdAt.millisecondsSinceEpoch) {
                existing = route;
                break;
            }
        }
    }

    if (existing == null) {
      current.add(RouteRecord(
        id: nextId++,
        remoteId: incoming.remoteId,
        name: incoming.name,
        points: incoming.points,
        syncStatus: incoming.syncStatus,
        lastModifiedAt: incoming.lastModifiedAt,
        createdAt: incoming.createdAt,
        updatedAt: incoming.updatedAt,
        needsSync: false,
      ));
    }
  }

  final encoded = current.map((RouteRecord r) => r.toMap()).toList();
  print('Encoded: ${jsonEncode(encoded)}');
}
