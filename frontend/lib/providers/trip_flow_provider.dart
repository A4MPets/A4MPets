import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../models/route_navigation_instruction.dart';
import '../models/route_record.dart';
import '../services/hazard_risk_filtering.dart';

enum TripTransportMethod { walking, vehicle }

class TripFlowState {
  final Set<int> selectedPetIds;
  final TripTransportMethod selectedTransport;
  final Set<String> selectedHazardRiskFilters;
  final RouteRecord? selectedRoute;
  final bool isTripActive;
  final bool arrivalHandled;
  final String? startErrorText;
  final LatLng? latestUserLocation;
  final bool isUserLocationLoading;
  final String? userLocationErrorText;
  final List<LatLng> remainingWaypoints;
  final List<RouteNavigationInstruction> activeNavigationInstructions;

  const TripFlowState({
    this.selectedPetIds = const <int>{},
    this.selectedTransport = TripTransportMethod.walking,
    this.selectedHazardRiskFilters = const <String>{
      ...HazardRiskFiltering.allRoutingFilters,
    },
    this.selectedRoute,
    this.isTripActive = false,
    this.arrivalHandled = false,
    this.startErrorText,
    this.latestUserLocation,
    this.isUserLocationLoading = true,
    this.userLocationErrorText,
    this.remainingWaypoints = const <LatLng>[],
    this.activeNavigationInstructions = const <RouteNavigationInstruction>[],
  });

  TripFlowState copyWith({
    Set<int>? selectedPetIds,
    TripTransportMethod? selectedTransport,
    Set<String>? selectedHazardRiskFilters,
    Object? selectedRoute = _sentinel,
    bool? isTripActive,
    bool? arrivalHandled,
    Object? startErrorText = _sentinel,
    Object? latestUserLocation = _sentinel,
    bool? isUserLocationLoading,
    Object? userLocationErrorText = _sentinel,
    List<LatLng>? remainingWaypoints,
    List<RouteNavigationInstruction>? activeNavigationInstructions,
  }) {
    return TripFlowState(
      selectedPetIds: selectedPetIds ?? this.selectedPetIds,
      selectedTransport: selectedTransport ?? this.selectedTransport,
      selectedHazardRiskFilters:
          selectedHazardRiskFilters ?? this.selectedHazardRiskFilters,
      selectedRoute: selectedRoute == _sentinel
          ? this.selectedRoute
          : selectedRoute as RouteRecord?,
      isTripActive: isTripActive ?? this.isTripActive,
      arrivalHandled: arrivalHandled ?? this.arrivalHandled,
      startErrorText: startErrorText == _sentinel
          ? this.startErrorText
          : startErrorText as String?,
      latestUserLocation: latestUserLocation == _sentinel
          ? this.latestUserLocation
          : latestUserLocation as LatLng?,
      isUserLocationLoading:
          isUserLocationLoading ?? this.isUserLocationLoading,
      userLocationErrorText: userLocationErrorText == _sentinel
          ? this.userLocationErrorText
          : userLocationErrorText as String?,
      remainingWaypoints: remainingWaypoints ?? this.remainingWaypoints,
      activeNavigationInstructions:
          activeNavigationInstructions ?? this.activeNavigationInstructions,
    );
  }
}

final tripFlowProvider = NotifierProvider<TripFlowController, TripFlowState>(
  TripFlowController.new,
);

class TripFlowController extends Notifier<TripFlowState> {
  @override
  TripFlowState build() {
    return const TripFlowState();
  }

  void setSelectedPets(Set<int> petIds) {
    state = state.copyWith(selectedPetIds: Set<int>.from(petIds));
  }

  void togglePet(int petId) {
    final Set<int> nextIds = Set<int>.from(state.selectedPetIds);
    if (!nextIds.add(petId)) {
      nextIds.remove(petId);
    }
    state = state.copyWith(selectedPetIds: nextIds);
  }

  void setTransport(TripTransportMethod transport) {
    state = state.copyWith(selectedTransport: transport);
  }

  void toggleHazardRiskFilter(String riskLevelCode, bool enabled) {
    final Set<String> nextFilters = Set<String>.from(
      state.selectedHazardRiskFilters,
    );
    if (enabled) {
      nextFilters.add(riskLevelCode);
    } else {
      nextFilters.remove(riskLevelCode);
    }
    state = state.copyWith(selectedHazardRiskFilters: nextFilters);
  }

  void selectRoute(RouteRecord? route) {
    state = state.copyWith(
      selectedRoute: route,
      remainingWaypoints:
          route?.points.map((RoutePoint point) => point.toLatLng()).toList() ??
          const <LatLng>[],
      startErrorText: null,
    );
  }

  void startTrip() {
    if (state.selectedRoute == null || state.remainingWaypoints.isEmpty) {
      state = state.copyWith(
        startErrorText: 'Selecciona una ruta valida para iniciar el viaje.',
      );
      return;
    }
    state = state.copyWith(
      isTripActive: true,
      arrivalHandled: false,
      startErrorText: null,
    );
  }

  void finishTrip() {
    state = state.copyWith(
      isTripActive: false,
      arrivalHandled: false,
      selectedRoute: null,
      remainingWaypoints: const <LatLng>[],
      activeNavigationInstructions: const <RouteNavigationInstruction>[],
    );
  }

  void updateUserLocation({
    LatLng? location,
    bool? isLoading,
    String? errorText,
  }) {
    state = state.copyWith(
      latestUserLocation: location,
      isUserLocationLoading: isLoading,
      userLocationErrorText: errorText,
    );
  }

  void replace(TripFlowState nextState) {
    state = nextState;
  }
}

const Object _sentinel = Object();
