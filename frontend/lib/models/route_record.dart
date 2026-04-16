import 'dart:convert';

import 'package:latlong2/latlong.dart';

class RoutePoint {
  final double latitude;
  final double longitude;

  const RoutePoint({
    required this.latitude,
    required this.longitude,
  });

  factory RoutePoint.fromMap(Map<String, dynamic> map) {
    return RoutePoint(
      latitude: (map['lat'] as num).toDouble(),
      longitude: (map['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'lat': latitude, 'lng': longitude};
  }

  LatLng toLatLng() => LatLng(latitude, longitude);
}

class RouteRecord {
  final int id;
  final String? remoteId;
  final String name;
  final List<RoutePoint> points;
  final String syncStatus;
  final DateTime lastModifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool needsSync;

  const RouteRecord({
    required this.id,
    this.remoteId,
    required this.name,
    required this.points,
    required this.syncStatus,
    required this.lastModifiedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.needsSync,
  });

  factory RouteRecord.fromMap(Map<String, Object?> map) {
    final String pointsJson = map['points_json'] as String? ?? '[]';
    final List<dynamic> rawPoints = jsonDecode(pointsJson) as List<dynamic>;
    final int nowMs = DateTime.now().millisecondsSinceEpoch;

    return RouteRecord(
      id: map['id'] as int,
      remoteId: map['remote_id']?.toString(),
      name: map['name'] as String,
      points: rawPoints
          .map((dynamic e) => RoutePoint.fromMap(e as Map<String, dynamic>))
          .toList(),
      syncStatus: map['sync_status'] as String? ?? 'created',
      lastModifiedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['last_modified_at'] as int?) ?? nowMs,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['created_at'] as int?) ?? nowMs,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['updated_at'] as int?) ?? nowMs,
      ),
      needsSync: (map['needs_sync'] as int? ?? 0) == 1,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'remote_id': remoteId,
      'name': name,
      'points_json': jsonEncode(
        points.map((RoutePoint p) => p.toMap()).toList(),
      ),
      'sync_status': syncStatus,
      'last_modified_at': lastModifiedAt.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'needs_sync': needsSync ? 1 : 0,
    };
  }
}
