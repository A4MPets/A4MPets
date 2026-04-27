import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/found_pet_report_record.dart';
import '../models/generic_report_record.dart';
import '../models/hazard_report_record.dart';
import '../models/local_user_profile.dart';
import '../models/lost_pet_report_record.dart';
import '../models/pet_record.dart';
import '../models/route_record.dart';
import '../repositories/user_local_repository.dart';
import '../services/local_database_manager.dart';
import '../services/local_media_storage_service.dart';
import '../services/user_data_sync_coordinator.dart';
import 'async_list_controller.dart';

final localDatabaseManagerProvider = Provider<LocalDatabaseManager>((ref) {
  return LocalDatabaseManager();
});

final localMediaStorageServiceProvider = Provider<LocalMediaStorageService>((
  ref,
) {
  return LocalMediaStorageService();
});

final userDataSyncCoordinatorProvider = Provider<UserDataSyncCoordinator>((
  ref,
) {
  final UserDataSyncCoordinator coordinator = UserDataSyncCoordinator(
    databaseManager: ref.watch(localDatabaseManagerProvider),
  );

  coordinator.startAutoSync();
  ref.onDispose(coordinator.stopAutoSync);

  return coordinator;
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

/// Exposes CRUD helpers for locally stored pets.
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

  Future<void> addPet({required String name, String? photoPath}) async {
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

/// Exposes CRUD helpers for locally stored travel routes.
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

  Future<void> addRoute({
    required String name,
    required List<RoutePoint> points,
  }) async {
    await _repository.addRoute(name: name, points: points);
    await reload();
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

/// Manages hazard lists with periodic refresh and background sync.
final hazardReportsControllerProvider =
    AsyncNotifierProvider<HazardReportsController, List<HazardReportRecord>>(
      HazardReportsController.new,
    );

class HazardReportsController extends AsyncListController<HazardReportRecord> {
  UserLocalRepository get _repository => ref.read(userLocalRepositoryProvider);

  @override
  Duration get refreshInterval => const Duration(seconds: 3);

  @override
  Future<void> runInitialSync() async {
    unawaited(_repository.syncHazardsNow());
  }

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

    try {
      await reload();
    } catch (_) {
      // The local save already succeeded; avoid blocking the UI on refresh.
    }
  }

  Future<void> addCommentToHazard({
    required int hazardId,
    required HazardCommentRecord comment,
  }) async {
    await _repository.addCommentToHazard(hazardId: hazardId, comment: comment);
    await reload();
  }

  Future<void> syncWithBackend() async {
    await _repository.syncHazardsNow();
    await reload();
  }
}

/// Manages lost-pet reports with periodic refresh and background sync.
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
  Future<void> runInitialSync() async {
    unawaited(_repository.syncLostPetReportsNow());
  }

  @override
  Future<List<LostPetReportRecord>> loadItems() {
    return _repository.getLostPetReports();
  }

  Future<void> addLostPetReport({
    required double lastSeenLatitude,
    required double lastSeenLongitude,
    required String name,
    required String details,
    required DateTime disappearanceDate,
    String? photoUrl,
    String? phone,
  }) async {
    await _repository.addLostPetReport(
      lastSeenLatitude: lastSeenLatitude,
      lastSeenLongitude: lastSeenLongitude,
      name: name,
      details: details,
      disappearanceDate: disappearanceDate,
      photoUrl: photoUrl,
      phone: phone,
    );

    try {
      await reload();
    } catch (_) {}
  }

  Future<void> syncWithBackend() async {
    await _repository.syncLostPetReportsNow();
    await reload();
  }
}

/// Manages found-pet reports with periodic refresh and background sync.
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
  Future<void> runInitialSync() async {
    unawaited(_repository.syncFoundPetReportsNow());
  }

  @override
  Future<List<FoundPetReportRecord>> loadItems() {
    return _repository.getFoundPetReports();
  }

  Future<void> addFoundPetReport({
    required double latitude,
    required double longitude,
    required String details,
    required DateTime foundDate,
    String? photoUrl,
    String? phone,
  }) async {
    await _repository.addFoundPetReport(
      latitude: latitude,
      longitude: longitude,
      details: details,
      foundDate: foundDate,
      photoUrl: photoUrl,
      phone: phone,
    );

    try {
      await reload();
    } catch (_) {}
  }

  Future<void> syncWithBackend() async {
    await _repository.syncFoundPetReportsNow();
    await reload();
  }
}

/// Manages generic reports with periodic refresh and background sync.
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
  Future<void> runInitialSync() async {
    unawaited(_repository.syncGenericReportsNow());
  }

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
    String? photoUrl,
  }) async {
    await _repository.addGenericReport(
      latitude: latitude,
      longitude: longitude,
      description: description,
      reportedDate: reportedDate,
      riskLevelCode: riskLevelCode,
      photoUrl: photoUrl,
    );

    try {
      await reload();
    } catch (_) {}
  }

  Future<void> syncWithBackend() async {
    await _repository.syncGenericReportsNow();
    await reload();
  }
}
