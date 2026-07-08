import 'package:shared_preferences/shared_preferences.dart';

import '../models/local_user_profile.dart';

class SessionStore {
  static const String _profileKey = 'a4m_session_profile';

  Future<LocalUserProfile> getLocalUserProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_profileKey);
    if (raw == null || raw.isEmpty) return LocalUserProfile.guest();

    try {
      return LocalUserProfile.fromJson(raw);
    } catch (_) {
      return LocalUserProfile.guest();
    }
  }

  Future<void> saveLocalUserProfile(LocalUserProfile profile) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool saved = await prefs.setString(_profileKey, profile.toJson());
    if (!saved) throw Exception('No se pudo guardar la sesion local.');
  }

  Future<void> clearUserSessionData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool removed = await prefs.remove(_profileKey);
    if (!removed && prefs.containsKey(_profileKey)) throw Exception('No se pudo borrar la sesion local.');
  }
}
