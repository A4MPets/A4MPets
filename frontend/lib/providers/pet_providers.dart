import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pet_record.dart';
import '../repositories/user_local_repository.dart';
import 'async_list_controller.dart';
import 'session_providers.dart';

Future<void> _reloadBestEffort(Future<void> Function() reload) async {
  try {
    await reload();
  } catch (_) {
    // The mutation already succeeded; a transient refresh failure should not
    // turn the completed user action into an error state.
  }
}

final petsControllerProvider =
    AsyncNotifierProvider<PetsController, List<PetRecord>>(PetsController.new);

class PetsController extends AsyncListController<PetRecord> {
  UserLocalRepository get _repository => ref.read(userLocalRepositoryProvider);

  @override
  Future<List<PetRecord>> loadItems() {
    return _repository.getPets();
  }

  Future<int> getNextDefaultPetNumber() async {
    final int count = await _repository.getPetsCount();
    return count + 1;
  }

  Future<int> addPet({
    String? name,
    String? photoPath,
    DateTime? adoptionDate,
    DateTime? birthDate,
    bool isOwnerless = false,
  }) async {
    final int petId = await _repository.addPet(
      name: name,
      photoPath: photoPath,
      adoptionDate: adoptionDate,
      birthDate: birthDate,
      isOwnerless: isOwnerless,
    );
    await _reloadBestEffort(reload);
    return petId;
  }

  Future<void> updatePet({
    required int petId,
    required String? name,
    String? photoPath,
    DateTime? adoptionDate,
    DateTime? birthDate,
  }) async {
    await _repository.updatePet(
      petId: petId,
      name: name,
      photoPath: photoPath,
      adoptionDate: adoptionDate,
      birthDate: birthDate,
    );
    await _reloadBestEffort(reload);
  }

  Future<void> deletePet({required int petId}) async {
    await _repository.deletePet(petId: petId);
    await _reloadBestEffort(reload);
  }

  Future<void> incrementPetWalks({required Iterable<int> petIds}) async {
    await _repository.incrementPetWalks(petIds: petIds);
    await _reloadBestEffort(reload);
  }

  Future<void> markPetFound({required int petId}) async {
    await _repository.markPetFound(petId: petId);
    await _reloadBestEffort(reload);
  }
}

final myPetsControllerProvider =
    AsyncNotifierProvider<MyPetsController, List<PetRecord>>(
      MyPetsController.new,
    );

class MyPetsController extends AsyncListController<PetRecord> {
  UserLocalRepository get _repository => ref.read(userLocalRepositoryProvider);

  @override
  Future<List<PetRecord>> loadItems() {
    return _repository.getMyPets();
  }

  Future<int> getNextDefaultPetNumber() async {
    final int count = await _repository.getMyPetsCount();
    return count + 1;
  }

  Future<int> addPet({
    String? name,
    String? photoPath,
    DateTime? adoptionDate,
    DateTime? birthDate,
    bool isOwnerless = false,
  }) async {
    final int petId = await _repository.addPet(
      name: name,
      photoPath: photoPath,
      adoptionDate: adoptionDate,
      birthDate: birthDate,
      isOwnerless: isOwnerless,
    );
    await _reloadBestEffort(reload);
    await _reloadBestEffort(ref.read(petsControllerProvider.notifier).reload);
    return petId;
  }

  Future<void> updatePet({
    required int petId,
    required String? name,
    String? photoPath,
    DateTime? adoptionDate,
    DateTime? birthDate,
  }) async {
    await _repository.updatePet(
      petId: petId,
      name: name,
      photoPath: photoPath,
      adoptionDate: adoptionDate,
      birthDate: birthDate,
    );
    await _reloadBestEffort(reload);
    await _reloadBestEffort(ref.read(petsControllerProvider.notifier).reload);
  }

  Future<void> deletePet({required int petId}) async {
    await _repository.deletePet(petId: petId);
    await _reloadBestEffort(reload);
    await _reloadBestEffort(ref.read(petsControllerProvider.notifier).reload);
  }

  Future<void> incrementPetWalks({required Iterable<int> petIds}) async {
    await _repository.incrementPetWalks(petIds: petIds);
    await _reloadBestEffort(reload);
    await _reloadBestEffort(ref.read(petsControllerProvider.notifier).reload);
  }

  Future<void> markPetFound({required int petId}) async {
    await _repository.markPetFound(petId: petId);
    await _reloadBestEffort(reload);
    await _reloadBestEffort(ref.read(petsControllerProvider.notifier).reload);
  }
}
