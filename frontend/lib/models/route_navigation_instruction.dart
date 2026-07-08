class RouteNavigationInstruction {
  const RouteNavigationInstruction({
    required this.sequence,
    required this.sign,
    required this.text,
    required this.streetName,
    this.exitNumber,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.pointStartIndex,
    required this.pointEndIndex,
  });

  final int sequence, sign;
  final String text, streetName;
  final int? exitNumber;
  final double distanceMeters, durationSeconds;
  final int pointStartIndex, pointEndIndex;

  String get id => 'instruction-$sequence-$pointStartIndex-$pointEndIndex-$sign';

  bool get isArrival => sign == 4;

  bool get isAudibleTurn {
    switch (sign) {
      case -3:
      case -2:
      case -1:
      case 1:
      case 2:
      case 3:
      case 6:
      case -98:
      case 98:
        return true;
      default:
        return false;
    }
  }

  factory RouteNavigationInstruction.fromMap(Map<String, dynamic> map) {
    return RouteNavigationInstruction(
      sequence: (map['sequence'] as num?)?.toInt() ?? 0,
      sign: (map['sign'] as num?)?.toInt() ?? 0,
      text: map['text']?.toString() ?? '',
      streetName: map['street_name']?.toString() ?? '',
      exitNumber: (map['exit_number'] as num?)?.toInt(),
      distanceMeters: (map['distance_meters'] as num?)?.toDouble() ?? 0,
      durationSeconds: (map['duration_seconds'] as num?)?.toDouble() ?? 0,
      pointStartIndex: (map['point_start_index'] as num?)?.toInt() ?? 0,
      pointEndIndex: (map['point_end_index'] as num?)?.toInt() ?? 0,
    );
  }
}
