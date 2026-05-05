import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/route_record.dart';
import '../repositories/user_local_repository.dart';
import 'async_list_controller.dart';
import 'session_providers.dart';

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
