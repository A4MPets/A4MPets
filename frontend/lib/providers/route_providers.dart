import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/route_record.dart';
import '../repositories/user_local_repository.dart';
import 'async_list_controller.dart';
import 'session_providers.dart';

Future<void> _reloadBestEffort(Future<void> Function() reload) async {
  try {
    await reload();
  } catch (_) {
    // A successful route mutation should not be surfaced as failed only
    // because the follow-up refresh could not complete.
  }
}

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
    await _reloadBestEffort(reload);
    return routeId;
  }

  Future<void> deleteRoute({required int routeId}) async {
    await _repository.deleteRoute(routeId: routeId);
    await _reloadBestEffort(reload);
  }

  Future<void> updateRoute({
    required int routeId,
    required String name,
    required List<RoutePoint> points,
  }) async {
    await _repository.updateRoute(routeId: routeId, name: name, points: points);
    await _reloadBestEffort(reload);
  }
}
