import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/found_pet_report_record.dart';
import '../models/generic_report_record.dart';
import '../models/hazard_report_record.dart';
import '../models/local_user_profile.dart';
import '../models/lost_pet_report_record.dart';
import '../models/pet_record.dart';
import '../models/report_comment_record.dart';
import '../models/route_record.dart';
import '../repositories/user_local_repository.dart';
import '../services/local_media_storage_service.dart';
import '../services/session_store.dart';
import 'async_list_controller.dart';

final sessionStoreProvider = Provider<SessionStore>((ref) {
  return SessionStore();
});

final localMediaStorageServiceProvider = Provider<LocalMediaStorageService>((
  ref,
) {
  return LocalMediaStorageService();
});

final userLocalRepositoryProvider = Provider<UserLocalRepository>((ref) {
  return UserLocalRepository(sessionStore: ref.watch(sessionStoreProvider));
});

final localUserProfileProvider = FutureProvider<LocalUserProfile>((ref) async {
  final UserLocalRepository repository = ref.watch(userLocalRepositoryProvider);
  return repository.getUserProfile();
});

/// Exposes CRUD helpers for pets stored in the backend.
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
    await reload();
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
    await reload();
  }

  Future<void> deletePet({required int petId}) async {
    await _repository.deletePet(petId: petId);
    await reload();
  }

  Future<void> incrementPetWalks({required Iterable<int> petIds}) async {
    await _repository.incrementPetWalks(petIds: petIds);
    await reload();
  }

  Future<void> markPetFound({required int petId}) async {
    await _repository.markPetFound(petId: petId);
    await reload();
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
    await reload();
    await ref.read(petsControllerProvider.notifier).reload();
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
    await reload();
    await ref.read(petsControllerProvider.notifier).reload();
  }

  Future<void> deletePet({required int petId}) async {
    await _repository.deletePet(petId: petId);
    await reload();
    await ref.read(petsControllerProvider.notifier).reload();
  }

  Future<void> incrementPetWalks({required Iterable<int> petIds}) async {
    await _repository.incrementPetWalks(petIds: petIds);
    await reload();
    await ref.read(petsControllerProvider.notifier).reload();
  }

  Future<void> markPetFound({required int petId}) async {
    await _repository.markPetFound(petId: petId);
    await reload();
    await ref.read(petsControllerProvider.notifier).reload();
  }
}

/// Exposes CRUD helpers for travel routes stored in the backend.
final routesControllerProvider =
    AsyncNotifierProvider<RoutesController, List<RouteRecord>>(
      RoutesController.new,
    );

class RoutesController extends AsyncListController<RouteRecord> {
  UserLocalRepository get _repository => ref.read(userLocalRepositoryProvider);

  @override
  Future<List<RouteRecord>> loadItems() {
    return _repository.getRoutes();
  }

  Future<int> getNextDefaultRouteNumber() async {
    final int count = await _repository.getRoutesCount();
    return count + 1;
  }

  Future<int> addRoute({
    required String name,
    required List<RoutePoint> points,
  }) async {
    final int routeId = await _repository.addRoute(name: name, points: points);
    await reload();
    return routeId;
  }

  Future<void> deleteRoute({required int routeId}) async {
    await _repository.deleteRoute(routeId: routeId);
    await reload();
  }

  Future<void> updateRoute({
    required int routeId,
    required String name,
    required List<RoutePoint> points,
  }) async {
    await _repository.updateRoute(routeId: routeId, name: name, points: points);
    await reload();
  }
}

/// Manages hazard lists with periodic backend refresh.
final hazardReportsControllerProvider =
    AsyncNotifierProvider<HazardReportsController, List<HazardReportRecord>>(
      HazardReportsController.new,
    );

class HazardReportsController extends AsyncListController<HazardReportRecord> {
  UserLocalRepository get _repository => ref.read(userLocalRepositoryProvider);

  @override
  Duration get refreshInterval => const Duration(seconds: 3);

  @override
  Future<List<HazardReportRecord>> loadItems() {
    return _repository.getHazardReports();
  }

  Future<void> addHazardReport({
    required double incidentLatitude,
    required double incidentLongitude,
    required int impactRadiusMeters,
    required String categoryCode,
    required String narrativeDescription,
    required DateTime reportedAt,
    required String estimatedDurationCode,
    required String riskLevelCode,
    String? evidencePhotoUrl,
    required String reportedByUsername,
  }) async {
    await _repository.addHazardReport(
      incidentLatitude: incidentLatitude,
      incidentLongitude: incidentLongitude,
      impactRadiusMeters: impactRadiusMeters,
      categoryCode: categoryCode,
      narrativeDescription: narrativeDescription,
      reportedAt: reportedAt,
      estimatedDurationCode: estimatedDurationCode,
      riskLevelCode: riskLevelCode,
      evidencePhotoUrl: evidencePhotoUrl,
      reportedByUsername: reportedByUsername,
    );
    await reload();
  }

  Future<void> addCommentToHazard({
    required int hazardId,
    required HazardCommentRecord comment,
  }) async {
    await _repository.addCommentToHazard(hazardId: hazardId, comment: comment);
    await reload();
  }

  Future<void> deleteHazardReport({
    required int hazardId,
    String? remoteId,
  }) async {
    await _repository.deleteHazardReport(
      hazardId: hazardId,
      remoteId: remoteId,
    );
    await reload();
  }

  Future<void> syncWithBackend() => reload();
}

/// Manages lost-pet reports with periodic backend refresh.
final lostPetReportsControllerProvider =
    AsyncNotifierProvider<LostPetReportsController, List<LostPetReportRecord>>(
      LostPetReportsController.new,
    );

class LostPetReportsController
    extends AsyncListController<LostPetReportRecord> {
  UserLocalRepository get _repository => ref.read(userLocalRepositoryProvider);

  @override
  Duration get refreshInterval => const Duration(seconds: 3);

  @override
  Future<List<LostPetReportRecord>> loadItems() {
    return _repository.getLostPetReports();
  }

  Future<void> addLostPetReport({
    required int petId,
    required String petLocalUuid,
    required double lastSeenLatitude,
    required double lastSeenLongitude,
    required String details,
    required DateTime disappearanceDate,
    String? photoUrl,
    required String phone,
  }) async {
    await _repository.addLostPetReport(
      petId: petId,
      petLocalUuid: petLocalUuid,
      lastSeenLatitude: lastSeenLatitude,
      lastSeenLongitude: lastSeenLongitude,
      details: details,
      disappearanceDate: disappearanceDate,
      photoUrl: photoUrl,
      phone: phone,
    );
    await reload();
  }

  Future<void> syncWithBackend() => reload();

  Future<void> addCommentToLostPetReport({
    required int reportId,
    required ReportCommentRecord comment,
  }) async {
    await _repository.addCommentToLostPetReport(
      reportId: reportId,
      comment: comment,
    );
    await reload();
  }

  Future<void> deleteLostPetReport({
    required int reportId,
    String? remoteId,
  }) async {
    await _repository.deleteLostPetReport(
      reportId: reportId,
      remoteId: remoteId,
    );
    await reload();
  }
}

/// Manages found-pet reports with periodic backend refresh.
final foundPetReportsControllerProvider =
    AsyncNotifierProvider<
      FoundPetReportsController,
      List<FoundPetReportRecord>
    >(FoundPetReportsController.new);

class FoundPetReportsController
    extends AsyncListController<FoundPetReportRecord> {
  UserLocalRepository get _repository => ref.read(userLocalRepositoryProvider);

  @override
  Duration get refreshInterval => const Duration(seconds: 3);

  @override
  Future<List<FoundPetReportRecord>> loadItems() {
    return _repository.getFoundPetReports();
  }

  Future<void> addFoundPetReport({
    int? petId,
    String? petLocalUuid,
    int? matchedLostPetReportId,
    required double latitude,
    required double longitude,
    required String details,
    required DateTime foundDate,
    String? photoUrl,
    String? phone,
  }) async {
    await _repository.addFoundPetReport(
      petId: petId,
      petLocalUuid: petLocalUuid,
      matchedLostPetReportId: matchedLostPetReportId,
      latitude: latitude,
      longitude: longitude,
      details: details,
      foundDate: foundDate,
      photoUrl: photoUrl,
      phone: phone,
    );
    await reload();
  }

  Future<void> syncWithBackend() => reload();

  Future<void> addCommentToFoundPetReport({
    required int reportId,
    required ReportCommentRecord comment,
  }) async {
    await _repository.addCommentToFoundPetReport(
      reportId: reportId,
      comment: comment,
    );
    await reload();
  }

  Future<void> deleteFoundPetReport({
    required int reportId,
    String? remoteId,
  }) async {
    await _repository.deleteFoundPetReport(
      reportId: reportId,
      remoteId: remoteId,
    );
    await reload();
  }
}

/// Manages generic reports with periodic backend refresh.
final genericReportsControllerProvider =
    AsyncNotifierProvider<GenericReportsController, List<GenericReportRecord>>(
      GenericReportsController.new,
    );

class GenericReportsController
    extends AsyncListController<GenericReportRecord> {
  UserLocalRepository get _repository => ref.read(userLocalRepositoryProvider);

  @override
  Duration get refreshInterval => const Duration(seconds: 3);

  @override
  Future<List<GenericReportRecord>> loadItems() {
    return _repository.getGenericReports();
  }

  Future<void> addGenericReport({
    required double latitude,
    required double longitude,
    required String description,
    required DateTime reportedDate,
    required String riskLevelCode,
    required int impactRadiusMeters,
    String? photoUrl,
  }) async {
    await _repository.addGenericReport(
      latitude: latitude,
      longitude: longitude,
      description: description,
      reportedDate: reportedDate,
      riskLevelCode: riskLevelCode,
      impactRadiusMeters: impactRadiusMeters,
      photoUrl: photoUrl,
    );
    await reload();
  }

  Future<void> syncWithBackend() => reload();

  Future<void> addCommentToGenericReport({
    required int reportId,
    required ReportCommentRecord comment,
  }) async {
    await _repository.addCommentToGenericReport(
      reportId: reportId,
      comment: comment,
    );
    await reload();
  }

  Future<void> deleteGenericReport({
    required int reportId,
    String? remoteId,
  }) async {
    await _repository.deleteGenericReport(
      reportId: reportId,
      remoteId: remoteId,
    );
    await reload();
  }
}
