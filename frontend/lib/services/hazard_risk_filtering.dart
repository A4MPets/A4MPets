class HazardRiskFiltering {
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  static const String other = 'other';

  static const List<String> allRoutingFilters = <String>[low, medium, high, other];

  static Set<String> normalizeSelectedFilters(Iterable<String>? filters) {
    if (filters == null) return allRoutingFilters.toSet();

    return filters
        .map((String value) => value.trim().toLowerCase())
        .where((String value) => allRoutingFilters.contains(value))
        .toSet();
  }

  static String routingBucketForRiskCode(String? riskLevelCode) {
    switch (riskLevelCode?.trim().toLowerCase()) {
      case low:
        return low;
      case medium:
        return medium;
      case high:
        return high;
      case 'undefined':
      default:
        return high;
    }
  }

  static bool shouldConsiderRisk({required String? riskLevelCode, required Iterable<String> selectedFilters}) {
    final Set<String> normalizedFilters = normalizeSelectedFilters(selectedFilters);
    if (normalizedFilters.isEmpty) return false;

    return normalizedFilters.contains(routingBucketForRiskCode(riskLevelCode));
  }

  static bool shouldConsiderOtherReports({required Iterable<String> selectedFilters}) {
    return normalizeSelectedFilters(selectedFilters).contains(other);
  }
}
