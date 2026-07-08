import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/local_user_profile.dart';
import '../repositories/user_local_repository.dart';
import '../services/guest_data_store.dart';
import '../services/local_media_storage_service.dart';
import '../services/session_store.dart';

final sessionStoreProvider = Provider<SessionStore>((ref) {
  return SessionStore();
});

final localMediaStorageServiceProvider = Provider<LocalMediaStorageService>((ref) {
  return LocalMediaStorageService();
});

final guestDataStoreProvider = Provider<GuestDataStore>((ref) {
  return GuestDataStore();
});

final userLocalRepositoryProvider = Provider<UserLocalRepository>((ref) {
  return UserLocalRepository(
    sessionStore: ref.watch(sessionStoreProvider),
    guestDataStore: ref.watch(guestDataStoreProvider),
  );
});

final localUserProfileProvider = FutureProvider<LocalUserProfile>((ref) async {
  final UserLocalRepository repository = ref.watch(userLocalRepositoryProvider);
  return repository.getUserProfile();
});
