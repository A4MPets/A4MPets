import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pet_record.dart';
import '../repositories/user_local_repository.dart';
import 'async_list_controller.dart';
import 'session_providers.dart';

final petsControllerProvider = AsyncNotifierProvider<PetsController, List<PetRecord>>(PetsController.new);

class PetsController extends PetControllerBase {
  @override
  Future<List<PetRecord>> loadItems() => repository.getPets();

  @override
  Future<int> petCount() => repository.getPetsCount();
}

final myPetsControllerProvider = AsyncNotifierProvider<MyPetsController, List<PetRecord>>(MyPetsController.new);

class MyPetsController extends PetControllerBase {
  @override
  Future<List<PetRecord>> loadItems() => repository.getMyPets();

  @override
  Future<int> petCount() => repository.getMyPetsCount();

  @override
  Future<void> afterMutation() => ref.read(petsControllerProvider.notifier).silentlyRefresh();
}

abstract class PetControllerBase extends AsyncListController<PetRecord> {
  UserLocalRepository get repository => ref.read(userLocalRepositoryProvider);

  Future<int> petCount();

  Future<void> afterMutation() async {}

  Future<int> getNextDefaultPetNumber() async => await petCount() + 1;

  Future<int> addPet({
    String? name,
    String? photoPath,
    DateTime? adoptionDate,
    DateTime? birthDate,
    bool isOwnerless = false,
  }) async {
    final int petId = await mutateAndReload(
      () => repository.addPet(
        name: name,
        photoPath: photoPath,
        adoptionDate: adoptionDate,
        birthDate: birthDate,
        isOwnerless: isOwnerless,
      ),
      bestEffort: true,
    );
    await afterMutation();
    return petId;
  }

  Future<void> updatePet({
    required int petId,
    required String? name,
    String? photoPath,
    DateTime? adoptionDate,
    DateTime? birthDate,
  }) async {
    await mutateAndReload(
      () => repository.updatePet(
        petId: petId,
        name: name,
        photoPath: photoPath,
        adoptionDate: adoptionDate,
        birthDate: birthDate,
      ),
      bestEffort: true,
    );
    await afterMutation();
  }

  Future<void> deletePet({required int petId}) async {
    await mutateAndReload(() => repository.deletePet(petId: petId), bestEffort: true);
    await afterMutation();
  }

  Future<void> incrementPetWalks({required Iterable<int> petIds}) async {
    await mutateAndReload(() => repository.incrementPetWalks(petIds: petIds), bestEffort: true);
    await afterMutation();
  }

  Future<void> markPetFound({required int petId}) async {
    await mutateAndReload(() => repository.markPetFound(petId: petId), bestEffort: true);
    await afterMutation();
  }
}
