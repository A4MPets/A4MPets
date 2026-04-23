class SyncDateTimeAndCodes {
  const SyncDateTimeAndCodes._();

  static DateTime parseBackendDateTime(Object? value) {
    if (value == null) {
      return DateTime.now().toUtc();
    }

    final String raw = value.toString().trim();
    if (raw.isEmpty) {
      return DateTime.now().toUtc();
    }

    return DateTime.tryParse(raw)?.toUtc() ?? DateTime.now().toUtc();
  }

  static String toBackendDateTime(DateTime dateTime) {
    final DateTime utc = dateTime.toUtc();
    final String y = utc.year.toString().padLeft(4, '0');
    final String m = utc.month.toString().padLeft(2, '0');
    final String d = utc.day.toString().padLeft(2, '0');
    final String hh = utc.hour.toString().padLeft(2, '0');
    final String mm = utc.minute.toString().padLeft(2, '0');
    final String ss = utc.second.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm:$ss';
  }

  static String normalizeRiskLevelCode(String? value) {
    final String normalized = (value ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'low':
      case 'medium':
      case 'high':
      case 'undefined':
        return normalized;
      case 'unknown':
      case 'unspecified':
      default:
        return 'undefined';
    }
  }

  static String normalizeCategoryCode(String? value) {
    final String normalized = (value ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'contagious_disease':
      case 'stagnant_water':
      case 'waste_accumulation':
      case 'aggressive_animals':
      case 'undefined':
        return normalized;
      case 'unknown':
      case 'unspecified':
      default:
        return 'undefined';
    }
  }

  static String normalizeDurationCode(String? value) {
    final String normalized = (value ?? '').trim().toLowerCase();
    switch (normalized) {
      case '1_day':
      case '3_days':
      case '1_week':
      case '2_weeks':
      case '1_month':
      case '3_months':
      case '6_months':
      case '1_year':
      case 'undefined':
        return normalized;
      case 'unknown':
      case 'unspecified':
      default:
        return 'undefined';
    }
  }
}
