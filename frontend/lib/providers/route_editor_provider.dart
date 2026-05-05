import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

enum RouteMapTool { addPoint, editPoint }

class RouteEditorState {
  final List<LatLng> draftRoutePoints;
  final List<LatLng> draftRoutePolyline;
  final List<LatLng> routePolylineWaypoints;
  final RouteMapTool activeTool;
  final int? selectedPointIndexForEdit;
  final int? selectedRouteId;
  final int? editingRouteId;
  final String? editingRouteName;

  const RouteEditorState({
    this.draftRoutePoints = const <LatLng>[],
    this.draftRoutePolyline = const <LatLng>[],
    this.routePolylineWaypoints = const <LatLng>[],
    this.activeTool = RouteMapTool.addPoint,
    this.selectedPointIndexForEdit,
    this.selectedRouteId,
    this.editingRouteId,
    this.editingRouteName,
  });

  RouteEditorState copyWith({
    List<LatLng>? draftRoutePoints,
    List<LatLng>? draftRoutePolyline,
    List<LatLng>? routePolylineWaypoints,
    RouteMapTool? activeTool,
    Object? selectedPointIndexForEdit = _sentinel,
    Object? selectedRouteId = _sentinel,
    Object? editingRouteId = _sentinel,
    Object? editingRouteName = _sentinel,
  }) {
    return RouteEditorState(
      draftRoutePoints: draftRoutePoints ?? this.draftRoutePoints,
      draftRoutePolyline: draftRoutePolyline ?? this.draftRoutePolyline,
      routePolylineWaypoints:
          routePolylineWaypoints ?? this.routePolylineWaypoints,
      activeTool: activeTool ?? this.activeTool,
      selectedPointIndexForEdit: selectedPointIndexForEdit == _sentinel
          ? this.selectedPointIndexForEdit
          : selectedPointIndexForEdit as int?,
      selectedRouteId: selectedRouteId == _sentinel
          ? this.selectedRouteId
          : selectedRouteId as int?,
      editingRouteId: editingRouteId == _sentinel
          ? this.editingRouteId
          : editingRouteId as int?,
      editingRouteName: editingRouteName == _sentinel
          ? this.editingRouteName
          : editingRouteName as String?,
    );
  }
}

final routeEditorProvider =
    NotifierProvider<RouteEditorController, RouteEditorState>(
      RouteEditorController.new,
    );

class RouteEditorController extends Notifier<RouteEditorState> {
  @override
  RouteEditorState build() {
    return const RouteEditorState();
  }

  void setTool(RouteMapTool tool) {
    state = state.copyWith(
      activeTool: tool,
      selectedPointIndexForEdit: tool == RouteMapTool.addPoint
          ? null
          : state.selectedPointIndexForEdit,
    );
  }

  void setDraftPoints(List<LatLng> points) {
    state = state.copyWith(draftRoutePoints: List<LatLng>.from(points));
  }

  void addDraftPoint(LatLng point) {
    state = state.copyWith(
      draftRoutePoints: <LatLng>[...state.draftRoutePoints, point],
    );
  }

  void updateDraftPoint(int index, LatLng point) {
    if (index < 0 || index >= state.draftRoutePoints.length) {
      return;
    }
    final List<LatLng> nextPoints = List<LatLng>.from(state.draftRoutePoints);
    nextPoints[index] = point;
    state = state.copyWith(draftRoutePoints: nextPoints);
  }

  void setPolyline({required List<LatLng> polyline, List<LatLng>? waypoints}) {
    state = state.copyWith(
      draftRoutePolyline: List<LatLng>.from(polyline),
      routePolylineWaypoints: waypoints == null
          ? state.routePolylineWaypoints
          : List<LatLng>.from(waypoints),
    );
  }

  void selectPointForEdit(int? index) {
    state = state.copyWith(selectedPointIndexForEdit: index);
  }

  void selectRoute(int? routeId) {
    state = state.copyWith(selectedRouteId: routeId);
  }

  void startEditingRoute({required int routeId, required String name}) {
    state = state.copyWith(editingRouteId: routeId, editingRouteName: name);
  }

  void clearDraft() {
    state = state.copyWith(
      draftRoutePoints: const <LatLng>[],
      draftRoutePolyline: const <LatLng>[],
      routePolylineWaypoints: const <LatLng>[],
      selectedPointIndexForEdit: null,
      editingRouteId: null,
      editingRouteName: null,
    );
  }

  void replace(RouteEditorState nextState) {
    state = nextState;
  }
}

const Object _sentinel = Object();
