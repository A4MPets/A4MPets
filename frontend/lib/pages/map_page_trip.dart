part of 'map_page.dart';

extension _MapPageTripState on _MapPageState {
  Future<void> _syncBackgroundAudioContext() async {
    final audioService = ref.read(audioFeedbackServiceProvider);
    if (!_isAudioFeedbackEnabled) {
      await audioService.disableBackgroundAudio();
      return;
    }

    final bool shouldEnableBackgroundAudio =
        _isTripActive || _hasProximityAudioTargets;
    if (shouldEnableBackgroundAudio) {
      await audioService.enableBackgroundAudio(
        notificationText: _isTripActive
            ? 'Indicaciones y alertas activas'
            : 'Alertas de proximidad activas',
      );
      return;
    }

    await audioService.disableBackgroundAudio();
  }

  void _stopNavigationSpeech() {
    unawaited(ref.read(audioFeedbackServiceProvider).stopSpeech());
  }

  void _resetTripAudioNavigationState({bool stopSpeech = true}) {
    _activeNavigationInstructions = const <RouteNavigationInstruction>[];
    _spokenFarApproachInstructionIds.clear();
    _spokenApproachInstructionIds.clear();
    _spokenImmediateInstructionIds.clear();
    if (stopSpeech) {
      _stopNavigationSpeech();
    }
  }

  Future<void> _maybeAnnounceNavigationInstruction(LatLng location) async {
    if (!_isTripActive ||
        !_isAudioFeedbackEnabled ||
        _draftRoutePolyline.length < 2 ||
        _activeNavigationInstructions.isEmpty) {
      return;
    }

    final NavigationAudioCue? cue = NavigationAudioProgress.nextCue(
      currentLocation: location,
      polyline: _draftRoutePolyline,
      instructions: _activeNavigationInstructions,
      spokenFarApproachKeys: _spokenFarApproachInstructionIds,
      spokenApproachKeys: _spokenApproachInstructionIds,
      spokenImmediateKeys: _spokenImmediateInstructionIds,
      distanceCalculator: _distanceCalculator,
    );
    if (cue == null) {
      return;
    }

    final String message = switch (cue.type) {
      NavigationAudioCueType.farApproach =>
        NavigationAudioMessageBuilder.buildFarApproachMessage(cue.instruction),
      NavigationAudioCueType.approach =>
        NavigationAudioMessageBuilder.buildApproachMessage(cue.instruction),
      NavigationAudioCueType.immediate =>
        NavigationAudioMessageBuilder.buildImmediateMessage(cue.instruction),
    };
    if (message.trim().isEmpty) {
      return;
    }

    if (cue.type == NavigationAudioCueType.farApproach) {
      _spokenFarApproachInstructionIds.add(cue.maneuverKey);
    } else if (cue.type == NavigationAudioCueType.approach) {
      _spokenFarApproachInstructionIds.add(cue.maneuverKey);
      _spokenApproachInstructionIds.add(cue.maneuverKey);
    } else {
      _spokenFarApproachInstructionIds.add(cue.maneuverKey);
      _spokenApproachInstructionIds.add(cue.maneuverKey);
      _spokenImmediateInstructionIds.add(cue.maneuverKey);
    }

    await ref.read(audioFeedbackServiceProvider).speakNavigation(message);
  }

  Future<void> _playArrivalAudioCue() async {
    if (!_isAudioFeedbackEnabled) {
      return;
    }

    await ref
        .read(audioFeedbackServiceProvider)
        .playArrivalCue(NavigationAudioMessageBuilder.buildArrivalMessage());
  }

  Future<void> _playWaypointAudioCue() async {
    if (!_isAudioFeedbackEnabled) {
      return;
    }

    await ref.read(audioFeedbackServiceProvider).playWaypointCue();
  }

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
    ref.read(myPetsControllerProvider.notifier).reload();
    ref.read(routesControllerProvider.notifier).reload();
    _updatePageState(() {
      _isTripStartPanelMinimized = false;
    });
    _pushPanel(_buildStartTripRoute(isDarkMode));
  }

  void _openTripPetSelectorPanel(bool isDarkMode) {
    ref.read(myPetsControllerProvider.notifier).reload();
    _syncAndReloadData();
    _pushPanel(_buildTripPetSelectorRoute(isDarkMode));
  }

  void _openTripRouteSelectorPanel(bool isDarkMode) {
    ref.read(routesControllerProvider.notifier).reload();
    _syncAndReloadData();
    _pushPanel(_buildTripRouteSelectorRoute(isDarkMode));
  }

  void _openAddRoutePanelFromTrip(bool isDarkMode) {
    _updatePageState(() {
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

    _updatePageState(() {
      _selectedTripRoute = route;
      _selectedRouteId = route.id;
      _tripRemainingWaypoints = List<LatLng>.from(selectedRoutePoints);
      _tripStartErrorText = null;
      _isTripStartPanelMinimized = false;
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
    final RouteRecord? selectedRoute = _selectedTripRoute;
    if (selectedRoute == null || selectedRoute.points.length < 2) {
      _updatePageState(() {
        _tripStartErrorText =
            'Selecciona una ruta válida para iniciar el viaje.';
      });
      return;
    }

    final List<LatLng> routePoints = selectedRoute.points
        .map((RoutePoint p) => p.toLatLng())
        .toList(growable: false);

    _stopNavigationSpeech();
    _updatePageState(() {
      _tripRerouteController.reset();
      _resetTripAudioNavigationState(stopSpeech: false);
      _tripStartErrorText = null;
      _isTripActive = true;
      _tripArrivalHandled = false;
      _tripRemainingWaypoints = List<LatLng>.from(routePoints);
      _isTripStartPanelMinimized = false;
      if (_hasOpenPanels) {
        _panelStack.removeLast();
      }
      _panelStack.add(_buildTripActiveRoute(isDarkMode));
      if (_latestUserLocation != null) {
        _tripUserFocusRevision += 1;
      }
    });
    unawaited(_syncBackgroundAudioContext());

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

    _stopNavigationSpeech();
    _updatePageState(() {
      _tripRerouteController.reset();
      _resetTripAudioNavigationState(stopSpeech: false);
      _isTripActive = false;
      _tripArrivalHandled = false;
      _selectedTripRoute = null;
      _tripRemainingWaypoints = <LatLng>[];
      _isTripStartPanelMinimized = false;
      _selectedTripPetIds.clear();
      _selectedTripHazardRiskFilters = <String>{
        ...HazardRiskFiltering.allRoutingFilters,
      };
      _clearDraftRouteVisuals();
      _panelStack.removeWhere(
        (_PanelRoute route) =>
            route.isTripPanel ||
            route.isTripStartPanel ||
            route.isTripPetSelectionPanel ||
            route.isTripRouteSelectionPanel,
      );
    });
    unawaited(_syncBackgroundAudioContext());
  }

  void _finishTripOnArrival() {
    if (_tripArrivalHandled) {
      return;
    }

    final bool isDarkMode = ref.read(themeModeProvider);
    final Set<int> completedPetIds = Set<int>.from(_selectedTripPetIds);
    unawaited(_playArrivalAudioCue());
    if (completedPetIds.isNotEmpty) {
      unawaited(
        ref
            .read(myPetsControllerProvider.notifier)
            .incrementPetWalks(petIds: completedPetIds),
      );
    }
    _updatePageState(() {
      _tripRerouteController.reset();
      _resetTripAudioNavigationState(stopSpeech: false);
      _tripArrivalHandled = true;
      _isTripActive = false;
      _selectedTripRoute = null;
      _tripRemainingWaypoints = <LatLng>[];
      _isTripStartPanelMinimized = false;
      _selectedTripPetIds.clear();
      _selectedTripHazardRiskFilters = <String>{
        ...HazardRiskFiltering.allRoutingFilters,
      };
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
    _stopNavigationSpeech();
    _updatePageState(() {
      _tripRerouteController.reset();
      _resetTripAudioNavigationState(stopSpeech: false);
      _tripArrivalHandled = false;
      _selectedTripRoute = null;
      _tripRemainingWaypoints = <LatLng>[];
      _isTripStartPanelMinimized = false;
      _selectedTripPetIds.clear();
      _selectedTripHazardRiskFilters = <String>{
        ...HazardRiskFiltering.allRoutingFilters,
      };
      _clearDraftRouteVisuals();
      _panelStack.clear();
    });
    unawaited(_syncBackgroundAudioContext());
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
    _tripArrivalHandled = false;
    _tripStartErrorText = null;
    _isTripActive = false;
    _selectedRouteId = null;
    _selectedTripRoute = null;
    _tripRemainingWaypoints = <LatLng>[];
    _isTripStartPanelMinimized = false;
    _tripRerouteController.reset();
    _resetTripAudioNavigationState(stopSpeech: false);
    _stopNavigationSpeech();
    _selectedTripPetIds.clear();
    _selectedTripHazardRiskFilters = <String>{
      ...HazardRiskFiltering.allRoutingFilters,
    };
    _clearDraftRouteVisuals();
    unawaited(_syncBackgroundAudioContext());
  }

  Future<void> _restoreTripRouteSelectionAfterEditorClose({
    int? routeId,
  }) async {
    final int? selectedTripRouteId = routeId ?? _selectedTripRoute?.id;
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

    _updatePageState(() {
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
    _updatePageState(() {
      _isTripStartPanelMinimized = false;
      _panelStack.removeWhere(
        (_PanelRoute route) =>
            route.isTripPetSelectionPanel || route.isTripRouteSelectionPanel,
      );
      if (_panelStack.isEmpty || !_panelStack.last.isTripStartPanel) {
        _panelStack.add(_buildStartTripRoute(isDarkMode));
      }
    });
  }

  Future<void> _closeAddRoutePanelAfterSave(int savedRouteId) async {
    if (!_hasOpenPanels) {
      return;
    }

    final _PanelRoute currentPanel = _panelStack.last;
    if (!currentPanel.isAddRoutePanel) {
      _closeCurrentPanel();
      return;
    }

    final bool returningToTripStartOrSelection =
        _panelStack.length > 1 &&
        (_panelStack[_panelStack.length - 2].isTripRouteSelectionPanel ||
            _panelStack[_panelStack.length - 2].isTripStartPanel);

    _updatePageState(() {
      _clearDraftRouteVisuals();
      _panelStack.removeLast();
    });

    if (returningToTripStartOrSelection) {
      await ref.read(routesControllerProvider.notifier).reload();
      if (!mounted) {
        return;
      }

      final List<RouteRecord> routes =
          ref.read(routesControllerProvider).asData?.value ??
          const <RouteRecord>[];
      for (final RouteRecord route in routes) {
        if (route.id != savedRouteId) {
          continue;
        }
        final bool isDarkMode = ref.read(themeModeProvider);
        _selectTripRoute(isDarkMode, route);
        return;
      }

      await _restoreTripRouteSelectionAfterEditorClose(routeId: savedRouteId);
    }
  }

  void _toggleTripStartPanelMinimized() {
    _updatePageState(() {
      _isTripStartPanelMinimized = !_isTripStartPanelMinimized;
    });
  }

  void _handleUserLocationChanged(LatLng location) {
    if (_isTripActive) {
      _updatePageState(() {
        _latestUserLocation = location;
        _tripUserFocusRevision += 1;
      });
    } else if (_latestUserLocation == null) {
      _updatePageState(() {
        _latestUserLocation = location;
      });
    } else {
      _latestUserLocation = location;
    }

    if (_isUserLocationLoading || _userLocationErrorText != null) {
      _handleUserLocationStatusChanged(false, null);
    }

    _evaluateProximityAlerts(location);
    unawaited(_syncBackgroundAudioContext());
    unawaited(_maybeAnnounceNavigationInstruction(location));

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
    final bool reachedIntermediateWaypoint =
        changed && nextRemaining.isNotEmpty;

    if (changed) {
      _updatePageState(() {
        _tripRemainingWaypoints = nextRemaining;
      });
    }

    if (reachedIntermediateWaypoint) {
      unawaited(_playWaypointAudioCue());
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

    _updatePageState(() {
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
      canMinimize: true,
      isMinimized: _isTripStartPanelMinimized,
      minimizedHeight: 72,
      onToggleMinimize: _toggleTripStartPanelMinimized,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return _TripStartPanelContent(
          isDarkMode: isDarkMode,
          selectedTransport: _selectedTripTransport,
          selectedHazardRiskFilters: _selectedTripHazardRiskFilters,
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
            _updatePageState(() {
              _selectedTripTransport = method;
            });
            ref
                .read(tripTransportPreferenceProvider.notifier)
                .setTransportName(method.name);
            _refreshTripRoutePreviewForPreferences();
          },
          onToggleHazardRiskFilter: (String riskLevelCode, bool value) {
            final Set<String> nextFilters = Set<String>.from(
              _selectedTripHazardRiskFilters,
            );
            if (value) {
              nextFilters.add(riskLevelCode);
            } else {
              nextFilters.remove(riskLevelCode);
            }

            _updatePageState(() {
              _selectedTripHazardRiskFilters = nextFilters;
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
              myPetsControllerProvider,
            );
            return _TripPetSelectionPanelContent(
              isDarkMode: isDarkMode,
              petsValue: petsValue,
              selectedPetIds: _selectedTripPetIds,
              onAddPetPressed: () => _openAddPetPanelFromTrip(isDarkMode),
              onTogglePet: (int petId) {
                _updatePageState(() {
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
      height: 220,
      maxHeight: 220,
      adaptHeightToContent: false,
      expandHorizontal: false,
      expandVertical: false,
      scrollContent: false,
      isTripPanel: true,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return _TripActivePanelContent(
          isDarkMode: isDarkMode,
          selectedTransport: _selectedTripTransport,
          onTransportChanged: (_TripTransportMethod method) {
            _updatePageState(() {
              _selectedTripTransport = method;
            });
            ref
                .read(tripTransportPreferenceProvider.notifier)
                .setTransportName(method.name);
            _refreshTripRoutePreviewForPreferences();
          },
          onFinishTrip: () {
            _finishTripManually();
          },
        );
      },
    );
  }
}
