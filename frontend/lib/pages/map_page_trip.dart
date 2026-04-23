// ignore_for_file: invalid_use_of_protected_member

part of 'map_page.dart';

extension _MapPageTripState on _MapPageState {
  void _refreshTripRoutePreviewForPreferences() {
    final RouteRecord? selectedRoute = _selectedTripRoute;
    if (selectedRoute == null) {
      return;
    }

    final List<LatLng> routePoints = selectedRoute.points
        .map((RoutePoint p) => p.toLatLng())
        .toList(growable: false);
    if (routePoints.isEmpty) {
      return;
    }

    final LatLng? origin = _latestUserLocation;
    if (origin != null) {
      _refreshDraftRoutePolyline(<LatLng>[origin, ...routePoints]);
      return;
    }

    _refreshDraftRoutePolyline(routePoints);
  }

  void _openStartTripPanel(bool isDarkMode) {
    if (_hasOpenPanels) {
      return;
    }
    _pushPanel(_buildStartTripRoute(isDarkMode));
  }

  void _openTripPetSelectorPanel(bool isDarkMode) {
    _syncAndReloadData();
    _pushPanel(_buildTripPetSelectorRoute(isDarkMode));
  }

  void _openTripRouteSelectorPanel(bool isDarkMode) {
    _syncAndReloadData();
    _pushPanel(_buildTripRouteSelectorRoute(isDarkMode));
  }

  void _openAddRoutePanelFromTrip(bool isDarkMode) {
    setState(() {
      _clearDraftRouteVisuals();
    });
    _pushPanel(
      _buildAddRouteRoute(isDarkMode, anchor: PanelAnchor.bottomRight),
    );
  }

  void _selectTripRoute(bool isDarkMode, RouteRecord route) {
    final List<LatLng> selectedRoutePoints = route.points
        .map((RoutePoint p) => p.toLatLng())
        .toList(growable: false);

    setState(() {
      _selectedTripRoute = route;
      _selectedRouteId = route.id;
      _tripRemainingWaypoints = List<LatLng>.from(selectedRoutePoints);
      _tripStartErrorText = null;
      if (_hasOpenPanels && _panelStack.last.isTripRouteSelectionPanel) {
        _panelStack.removeLast();
        if (!_hasOpenPanels || !_panelStack.last.isTripStartPanel) {
          _panelStack.add(_buildStartTripRoute(isDarkMode));
        }
      }
    });
    _showRouteOnMap(route);

    final LatLng? origin = _latestUserLocation;
    if (origin != null && selectedRoutePoints.isNotEmpty) {
      _refreshDraftRoutePolyline(<LatLng>[origin, ...selectedRoutePoints]);
    }
  }

  void _openEditSelectedTripRoutePanel(bool isDarkMode) {
    final RouteRecord? selectedRoute = _selectedTripRoute;
    if (selectedRoute == null) {
      return;
    }

    _openEditRoutePanel(
      isDarkMode,
      selectedRoute,
      anchor: PanelAnchor.bottomRight,
    );
  }

  void _startTrip(bool isDarkMode) {
    if (_selectedTripRoute == null || _selectedTripRoute!.points.length < 2) {
      setState(() {
        _tripStartErrorText =
            'Selecciona una ruta válida para iniciar el viaje.';
      });
      return;
    }

    final List<LatLng> routePoints = _selectedTripRoute!.points
        .map((RoutePoint p) => p.toLatLng())
        .toList(growable: false);

    setState(() {
      _tripStartErrorText = null;
      _isTripActive = true;
      _tripArrivalHandled = false;
      _tripRemainingWaypoints = List<LatLng>.from(routePoints);
      if (_hasOpenPanels) {
        _panelStack.removeLast();
      }
      _panelStack.add(_buildTripActiveRoute(isDarkMode));
    });

    final LatLng? origin = _latestUserLocation;
    if (origin != null && routePoints.isNotEmpty) {
      _refreshDraftRoutePolyline(<LatLng>[origin, ...routePoints]);
    }
  }

  Future<void> _finishTripManually() async {
    final bool isDarkMode = ref.read(themeModeProvider);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppPalette.dialogBackground(isDarkMode),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppPalette.border(isDarkMode)),
          ),
          title: Text(
            'Terminar viaje',
            style: TextStyle(
              color: AppPalette.dialogTitle(isDarkMode),
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            '¿Estás seguro de terminar el viaje?',
            style: TextStyle(color: AppPalette.dialogBody(isDarkMode)),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: AppPalette.dialogCancel(isDarkMode),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Terminar',
                style: TextStyle(
                  color: AppPalette.dangerRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isTripActive = false;
      _tripArrivalHandled = false;
      _selectedTripRoute = null;
      _tripRemainingWaypoints = <LatLng>[];
      _selectedTripPetIds.clear();
      _selectedTripTransport = _TripTransportMethod.walking;
      _shouldAvoidHazardsInRouting = true;
      _clearDraftRouteVisuals();
      _panelStack.removeWhere(
        (_PanelRoute route) =>
            route.isTripPanel ||
            route.isTripStartPanel ||
            route.isTripPetSelectionPanel ||
            route.isTripRouteSelectionPanel,
      );
    });
  }

  void _finishTripOnArrival() {
    if (_tripArrivalHandled) {
      return;
    }

    final bool isDarkMode = ref.read(themeModeProvider);
    setState(() {
      _tripArrivalHandled = true;
      _isTripActive = false;
      _selectedTripRoute = null;
      _tripRemainingWaypoints = <LatLng>[];
      _selectedTripPetIds.clear();
      _selectedTripTransport = _TripTransportMethod.walking;
      _shouldAvoidHazardsInRouting = true;
      _clearDraftRouteVisuals();
      _panelStack.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _showTripArrivalDialog(isDarkMode);
    });
  }

  void _acknowledgeTripArrival() {
    setState(() {
      _tripArrivalHandled = false;
      _selectedTripRoute = null;
      _tripRemainingWaypoints = <LatLng>[];
      _selectedTripPetIds.clear();
      _selectedTripTransport = _TripTransportMethod.walking;
      _shouldAvoidHazardsInRouting = true;
      _clearDraftRouteVisuals();
      _panelStack.clear();
    });
  }

  Future<void> _showTripArrivalDialog(bool isDarkMode) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: AppPalette.dialogBackground(isDarkMode),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _TripArrivalPanelContent(
              isDarkMode: isDarkMode,
              onAcknowledge: () {
                Navigator.of(dialogContext).pop();
                _acknowledgeTripArrival();
              },
            ),
          ),
        );
      },
    );
  }

  void _clearTripSetupState() {
    _selectedTripRoute = null;
    _tripRemainingWaypoints = <LatLng>[];
    _tripRerouteController.reset();
    _selectedTripPetIds.clear();
    _selectedTripTransport = _TripTransportMethod.walking;
    _shouldAvoidHazardsInRouting = true;
    _clearDraftRouteVisuals();
  }

  Future<void> _restoreTripRouteSelectionAfterEditorClose() async {
    final int? selectedTripRouteId = _selectedTripRoute?.id;
    if (selectedTripRouteId == null) {
      return;
    }

    RouteRecord? resolvedRoute = _selectedTripRoute;
    final List<RouteRecord>? routes = ref
        .read(routesControllerProvider)
        .asData
        ?.value;
    if (routes != null) {
      for (final RouteRecord route in routes) {
        if (route.id == selectedTripRouteId) {
          resolvedRoute = route;
          break;
        }
      }
    }

    if (resolvedRoute == null) {
      return;
    }

    final List<LatLng> points = resolvedRoute.points
        .map((RoutePoint p) => p.toLatLng())
        .toList();

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedTripRoute = resolvedRoute;
      _selectedRouteId = resolvedRoute!.id;
      _tripRemainingWaypoints = List<LatLng>.from(points);
      _draftRoutePoints = points;
      _draftRoutePolyline = List<LatLng>.from(points);
    });

    if (_latestUserLocation != null && points.isNotEmpty) {
      await _refreshDraftRoutePolyline(<LatLng>[
        _latestUserLocation!,
        ...points,
      ]);
      return;
    }

    await _refreshDraftRoutePolyline(points);
  }

  void _returnToTripStartPanel(bool isDarkMode) {
    setState(() {
      _panelStack.removeWhere(
        (_PanelRoute route) =>
            route.isTripPetSelectionPanel || route.isTripRouteSelectionPanel,
      );
      if (_panelStack.isEmpty || !_panelStack.last.isTripStartPanel) {
        _panelStack.add(_buildStartTripRoute(isDarkMode));
      }
    });
  }

  Future<void> _closeAddRoutePanelAfterSave() async {
    if (!_hasOpenPanels) {
      return;
    }

    final _PanelRoute currentPanel = _panelStack.last;
    if (!currentPanel.isAddRoutePanel) {
      _closeCurrentPanel();
      return;
    }

    final bool returningToTripRouteSelection =
        _panelStack.length > 1 &&
        _panelStack[_panelStack.length - 2].isTripRouteSelectionPanel;

    setState(() {
      _clearDraftRouteVisuals();
      _panelStack.removeLast();
    });

    if (returningToTripRouteSelection) {
      await _restoreTripRouteSelectionAfterEditorClose();
    }
  }

  void _handleUserLocationChanged(LatLng location) {
    _latestUserLocation = location;

    if (_tripArrivalHandled || _selectedTripRoute == null) {
      return;
    }

    if (!_isTripActive) {
      final List<LatLng> waypoints = _tripRemainingWaypoints.isNotEmpty
          ? _tripRemainingWaypoints
          : _selectedTripRoute!.points
                .map((RoutePoint p) => p.toLatLng())
                .toList(growable: false);

      if (waypoints.isEmpty) {
        return;
      }

      _refreshDraftRoutePolyline(<LatLng>[location, ...waypoints]);
      return;
    }

    if (_tripRemainingWaypoints.isEmpty) {
      _finishTripOnArrival();
      return;
    }

    final WaypointProgressResult waypointProgress =
        TripWaypointProgressor.consumeReachedWaypoints(
          currentLocation: location,
          currentWaypoints: _tripRemainingWaypoints,
          waypointArrivalMeters: _MapPageState._tripWaypointArrivalMeters,
          distanceCalculator: _distanceCalculator,
        );
    final List<LatLng> nextRemaining = waypointProgress.remainingWaypoints;
    final bool changed = waypointProgress.hasChanges;

    if (changed) {
      setState(() {
        _tripRemainingWaypoints = nextRemaining;
      });
    }

    if (nextRemaining.isEmpty) {
      _finishTripOnArrival();
      return;
    }

    _softUpdateTripPolylineHead(location);
    _maybeRecalculateTripPolyline(
      location: location,
      nextWaypoints: nextRemaining,
      force: changed || _draftRoutePolyline.isEmpty,
    );
  }

  void _softUpdateTripPolylineHead(LatLng location) {
    if (_draftRoutePolyline.isEmpty) {
      return;
    }

    final double delta = _distanceCalculator.distance(
      location,
      _draftRoutePolyline.first,
    );
    if (delta < 2) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      final List<LatLng> updated = List<LatLng>.from(_draftRoutePolyline);
      updated[0] = location;
      _draftRoutePolyline = updated;
      _analyzeRouteForHazards();
    });
  }

  Future<void> _maybeRecalculateTripPolyline({
    required LatLng location,
    required List<LatLng> nextWaypoints,
    bool force = false,
  }) async {
    if (nextWaypoints.isEmpty) {
      return;
    }

    if (!_tripRerouteController.shouldTrigger(
      location: location,
      force: force,
    )) {
      return;
    }

    if (_tripRerouteController.isInFlight) {
      _tripRerouteController.queue(
        location: location,
        waypoints: nextWaypoints,
      );
      return;
    }

    _tripRerouteController.markStarted(location);

    try {
      await _refreshDraftRoutePolyline(<LatLng>[
        location,
        ...nextWaypoints,
      ], keepCurrentPolylineWhileLoading: true);
    } finally {
      final QueuedTripReroute? queued = _tripRerouteController
          .completeAndTakeQueued();

      if (queued != null && mounted) {
        _maybeRecalculateTripPolyline(
          location: queued.location,
          nextWaypoints: queued.waypoints,
          force: true,
        );
      }
    }
  }

  _PanelRoute _buildStartTripRoute(bool isDarkMode) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Iniciar Viaje',
      anchor: PanelAnchor.bottomRight,
      width: 360,
      maxHeightFactor: 0.62,
      adaptHeightToContent: false,
      expandHorizontal: false,
      expandVertical: false,
      scrollContent: false,
      isTripStartPanel: true,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return _TripStartPanelContent(
          isDarkMode: isDarkMode,
          selectedTransport: _selectedTripTransport,
          avoidHazards: _shouldAvoidHazardsInRouting,
          selectedPetsCount: _selectedTripPetIds.length,
          selectedRouteName: _selectedTripRoute?.name,
          errorText: _tripStartErrorText,
          contentTopPadding: 26,
          onSelectPets: () => _openTripPetSelectorPanel(isDarkMode),
          onSelectRoute: () => _openTripRouteSelectorPanel(isDarkMode),
          onEditSelectedRoute: _selectedTripRoute == null
              ? null
              : () => _openEditSelectedTripRoutePanel(isDarkMode),
          onTransportChanged: (_TripTransportMethod method) {
            setState(() {
              _selectedTripTransport = method;
            });
            _refreshTripRoutePreviewForPreferences();
          },
          onAvoidHazardsChanged: (bool value) {
            setState(() {
              _shouldAvoidHazardsInRouting = value;
            });
            _refreshTripRoutePreviewForPreferences();
          },
          onStartTrip: () => _startTrip(isDarkMode),
        );
      },
      contentTopPadding: 42,
    );
  }

  _PanelRoute _buildTripPetSelectorRoute(bool isDarkMode) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Seleccionar Mascotas',
      anchor: PanelAnchor.topRight,
      width: 380,
      maxHeightFactor: 0.82,
      adaptHeightToContent: false,
      expandHorizontal: false,
      expandVertical: true,
      scrollContent: false,
      isTripPetSelectionPanel: true,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? child) {
            final AsyncValue<List<PetRecord>> petsValue = ref.watch(
              petsControllerProvider,
            );
            return _TripPetSelectionPanelContent(
              isDarkMode: isDarkMode,
              petsValue: petsValue,
              selectedPetIds: _selectedTripPetIds,
              onAddPetPressed: () => _openAddPetPanelFromTrip(isDarkMode),
              onTogglePet: (int petId) {
                setState(() {
                  if (_selectedTripPetIds.contains(petId)) {
                    _selectedTripPetIds.remove(petId);
                  } else {
                    _selectedTripPetIds.add(petId);
                  }
                });
              },
              onDone: () => _returnToTripStartPanel(isDarkMode),
            );
          },
        );
      },
    );
  }

  _PanelRoute _buildTripRouteSelectorRoute(bool isDarkMode) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Ruta',
      anchor: PanelAnchor.topRight,
      width: 380,
      height: 620,
      maxHeight: 620,
      adaptHeightToContent: false,
      expandHorizontal: false,
      expandVertical: true,
      scrollContent: false,
      isTripRouteSelectionPanel: true,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return ManageRoutesPanelContent(
          isDarkMode: isDarkMode,
          onAddRoutePressed: () => _openAddRoutePanelFromTrip(isDarkMode),
          selectedRouteId: _selectedTripRoute?.id,
          onRoutePressed: (RouteRecord route) =>
              _selectTripRoute(isDarkMode, route),
          onEditRoutePressed: (RouteRecord route) => _openEditRoutePanel(
            isDarkMode,
            route,
            anchor: PanelAnchor.bottomRight,
          ),
          onDeleteRoutePressed: (RouteRecord route) =>
              _confirmAndDeleteRoute(context, route),
        );
      },
    );
  }

  _PanelRoute _buildTripActiveRoute(bool isDarkMode) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Viaje',
      anchor: PanelAnchor.bottomRight,
      width: 360,
      height: 130,
      maxHeight: 130,
      adaptHeightToContent: false,
      expandHorizontal: false,
      expandVertical: false,
      scrollContent: false,
      isTripPanel: true,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return _TripActivePanelContent(
          isDarkMode: isDarkMode,
          onFinishTrip: () {
            _finishTripManually();
          },
        );
      },
    );
  }
}
