import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/local_user_profile.dart';
import '../models/pet_record.dart';
import '../repositories/user_local_repository.dart';
import '../services/local_database_manager.dart';
import '../services/local_media_storage_service.dart';
import '../services/user_data_sync_coordinator.dart';

final localDatabaseManagerProvider = Provider<LocalDatabaseManager>((ref) {
  return LocalDatabaseManager();
});

final localMediaStorageServiceProvider = Provider<LocalMediaStorageService>((ref) {
  return LocalMediaStorageService();
});

final userDataSyncCoordinatorProvider = Provider<UserDataSyncCoordinator>((ref) {
  return const UserDataSyncCoordinator();
});

final userLocalRepositoryProvider = Provider<UserLocalRepository>((ref) {
  return UserLocalRepository(
    databaseManager: ref.watch(localDatabaseManagerProvider),
    syncCoordinator: ref.watch(userDataSyncCoordinatorProvider),
  );
});

final localUserProfileProvider = FutureProvider<LocalUserProfile>((ref) async {
  final UserLocalRepository repository = ref.watch(userLocalRepositoryProvider);
  return repository.getUserProfile();
});

final petsControllerProvider =
    AsyncNotifierProvider<PetsController, List<PetRecord>>(PetsController.new);

class PetsController extends AsyncNotifier<List<PetRecord>> {
  UserLocalRepository get _repository => ref.read(userLocalRepositoryProvider);

  @override
  Future<List<PetRecord>> build() {
    return _repository.getPets();
  }

  Future<int> getNextDefaultPetNumber() async {
    final int count = await _repository.getPetsCount();
    return count + 1;
  }

  Future<void> reload() async {
    state = const AsyncLoading<List<PetRecord>>().copyWithPrevious(state);
    state = await AsyncValue.guard(_repository.getPets);
  }

  Future<void> addPet({
    required String name,
    String? photoPath,
  }) async {
    await _repository.addPet(name: name, photoPath: photoPath);
    await reload();
  }

  Future<void> updatePet({
    required int petId,
    required String name,
    String? photoPath,
  }) async {
    await _repository.updatePet(petId: petId, name: name, photoPath: photoPath);
    await reload();
  }

  Future<void> deletePet({required int petId}) async {
    await _repository.deletePet(petId: petId);
    await reload();
  }
}
