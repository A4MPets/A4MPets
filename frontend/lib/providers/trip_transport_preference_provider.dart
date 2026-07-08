import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TripTransportPreferenceController extends Notifier<String> {
  static const String _storageKey = 'trip_transport_method';

  SharedPreferences? _prefs;

  @override
  String build() {
    _loadPersistedValue();
    return 'walking';
  }

  Future<void> setTransportName(String transportName) async {
    state = _normalizeTransportName(transportName);
    final SharedPreferences prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setString(_storageKey, state);
  }

  Future<void> _loadPersistedValue() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    final String persistedValue = _normalizeTransportName(prefs.getString(_storageKey));
    if (state != persistedValue) state = persistedValue;
  }

  String _normalizeTransportName(String? value) {
    return value == 'vehicle' ? 'vehicle' : 'walking';
  }
}

final tripTransportPreferenceProvider = NotifierProvider<TripTransportPreferenceController, String>(
  TripTransportPreferenceController.new,
);
