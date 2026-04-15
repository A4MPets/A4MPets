import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/hazard_report_record.dart';
import '../models/local_user_profile.dart';
import '../models/pet_record.dart';
import '../models/route_record.dart';
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

final routesControllerProvider =
    AsyncNotifierProvider<RoutesController, List<RouteRecord>>(RoutesController.new);

class RoutesController extends AsyncNotifier<List<RouteRecord>> {
  UserLocalRepository get _repository => ref.read(userLocalRepositoryProvider);

  @override
  Future<List<RouteRecord>> build() {
    return _repository.getRoutes();
  }

  Future<int> getNextDefaultRouteNumber() async {
    final int count = await _repository.getRoutesCount();
    return count + 1;
  }

  Future<void> reload() async {
    state = const AsyncLoading<List<RouteRecord>>().copyWithPrevious(state);
    state = await AsyncValue.guard(_repository.getRoutes);
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

final hazardReportsControllerProvider =
    AsyncNotifierProvider<HazardReportsController, List<HazardReportRecord>>(
        HazardReportsController.new);

class HazardReportsController extends AsyncNotifier<List<HazardReportRecord>> {
  UserLocalRepository get _repository => ref.read(userLocalRepositoryProvider);
  Timer? _refreshTimer;
  bool _isDisposed = false;

  void _ensureAutoRefresh() {
    _refreshTimer ??= Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_isDisposed) {
        return;
      }

      try {
        final List<HazardReportRecord> latest = await _repository.getHazardReports();
        state = AsyncData<List<HazardReportRecord>>(latest);
      } catch (_) {
        // Evitar ruido en UI: el siguiente tick volverá a intentar.
      }
    });

    ref.onDispose(() {
      _isDisposed = true;
      _refreshTimer?.cancel();
      _refreshTimer = null;
    });
  }

  @override
  Future<List<HazardReportRecord>> build() async {
    _ensureAutoRefresh();

    // Disparar sincronización en segundo plano sin bloquear la carga local.
    unawaited(_repository.syncHazardsNow());
    return _repository.getHazardReports();
  }

  Future<void> reload() async {
    state = const AsyncLoading<List<HazardReportRecord>>().copyWithPrevious(state);
    state = await AsyncValue.guard(_repository.getHazardReports);
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
      // El guardado local ya ocurrió; no bloquear UX por refresco/sync.
    }
  }

  Future<void> addCommentToHazard({
    required int hazardId,
    required HazardCommentRecord comment,
  }) async {
    await _repository.addCommentToHazard(
      hazardId: hazardId,
      comment: comment,
    );
    await reload();
  }

  Future<void> syncWithBackend() async {
    await _repository.syncHazardsNow();
    await reload();
  }
}
