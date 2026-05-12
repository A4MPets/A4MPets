part of 'map_page.dart';

extension _MapPageRoutesState on _MapPageState {
  void _openManageRoutesPanel(bool isDarkMode) {
    _syncAndReloadData();
    _pushPanel(_buildManageRoutesRoute(isDarkMode));
  }

  void _openAddRoutePanel(bool isDarkMode) {
    _updatePageState(() {
      _clearDraftRouteVisuals();
    });
    _pushPanel(_buildAddRouteRoute(isDarkMode));
  }

  void _openEditRoutePanel(
    bool isDarkMode,
    RouteRecord route, {
    PanelAnchor anchor = PanelAnchor.topLeft,
  }) {
    final List<LatLng> points = route.points
        .map((RoutePoint p) => p.toLatLng())
        .toList();
    _updatePageState(() {
      _draftRoutePoints = points;
      _draftRoutePolyline = List<LatLng>.from(points);
      _activeRouteTool = _RouteMapTool.addPoint;
      _selectedPointIndexForEdit = null;
      _selectedRouteId = route.id;
      _editingRouteId = route.id;
      _editingRouteName = route.name;
    });
    _refreshDraftRoutePolyline(points);
    _pushPanel(_buildAddRouteRoute(isDarkMode, anchor: anchor));
  }

  void _showRouteOnMap(RouteRecord route) {
    final List<LatLng> points = route.points
        .map((RoutePoint p) => p.toLatLng())
        .toList();
    _updatePageState(() {
      _draftRoutePoints = points;
      _draftRoutePolyline = List<LatLng>.from(points);
      _selectedRouteId = route.id;
      _editingRouteId = route.id;
      _editingRouteName = route.name;
    });
    _refreshDraftRoutePolyline(points);
  }

  Future<void> _confirmAndDeleteRoute(
    BuildContext context,
    RouteRecord route,
  ) async {
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
            'Eliminar ruta',
            style: TextStyle(
              color: AppPalette.dialogTitle(isDarkMode),
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            '¿Estás seguro de borrar la ruta "${route.name}"?',
            style: TextStyle(color: AppPalette.dialogBody(isDarkMode)),
          ),
          actions: [
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
                'Borrar',
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

    await ref
        .read(routesControllerProvider.notifier)
        .deleteRoute(routeId: route.id);

    if (!mounted) {
      return;
    }

    if (_selectedRouteId == route.id) {
      _updatePageState(() {
        _clearDraftRouteVisuals();
      });
    }
  }

  _PanelRoute _buildManageRoutesRoute(bool isDarkMode) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Gestionar Rutas',
      anchor: PanelAnchor.topLeft,
      width: 380,
      height: 620,
      maxHeight: 620,
      adaptHeightToContent: false,
      expandHorizontal: false,
      expandVertical: true,
      scrollContent: false,
      isManageRoutesPanel: true,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return ManageRoutesPanelContent(
          isDarkMode: isDarkMode,
          onAddRoutePressed: () => _openAddRoutePanel(isDarkMode),
          selectedRouteId: _selectedRouteId,
          onRoutePressed: _showRouteOnMap,
          onEditRoutePressed: (RouteRecord route) =>
              _openEditRoutePanel(isDarkMode, route),
          onDeleteRoutePressed: (RouteRecord route) =>
              _confirmAndDeleteRoute(context, route),
        );
      },
    );
  }

  _PanelRoute _buildAddRouteRoute(
    bool isDarkMode, {
    PanelAnchor anchor = PanelAnchor.topLeft,
  }) {
    final bool isEditing = _editingRouteId != null;

    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: isEditing ? 'Editar Ruta' : 'Agregar Ruta',
      anchor: anchor,
      width: 340,
      height: 420,
      maxHeight: 420,
      adaptHeightToContent: false,
      expandHorizontal: false,
      expandVertical: false,
      scrollContent: false,
      isAddRoutePanel: true,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return AddRoutePanelContent(
          isDarkMode: isDarkMode,
          points: _draftRoutePoints,
          isAddToolSelected: _activeRouteTool == _RouteMapTool.addPoint,
          isEditToolSelected: _activeRouteTool == _RouteMapTool.editPoint,
          onSelectAddTool: () {
            _updatePageState(() {
              _activeRouteTool = _RouteMapTool.addPoint;
              _selectedPointIndexForEdit = null;
            });
          },
          onSelectEditTool: () {
            _updatePageState(() {
              _activeRouteTool = _RouteMapTool.editPoint;
            });
          },
          selectedPointIndex: _selectedPointIndexForEdit,
          onSelectPointForMapEdit: (int index) {
            _updatePageState(() {
              _selectedPointIndexForEdit = index;
              _activeRouteTool = _RouteMapTool.editPoint;
            });
          },
          onRequestCurrentLocation: _addCurrentLocationPoint,
          onReorderPoints: _reorderDraftPoints,
          onRemovePoint: _removeDraftPoint,
          isEditingExistingRoute: isEditing,
          routeId: _editingRouteId,
          initialRouteName: _editingRouteName,
          onSaveRoute: _persistDraftRoute,
          onSavedComplete: (int savedRouteId) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) {
                return;
              }
              _closeAddRoutePanelAfterSave(savedRouteId);
            });
          },
        );
      },
    );
  }

  void _clearDraftRouteVisuals() {
    _routePolylineRequestVersion++;
    _draftRoutePoints = <LatLng>[];
    _draftRoutePolyline = <LatLng>[];
    _routePolylineWaypoints = <LatLng>[];
    _hazardColoredRouteSegments = <ColoredRouteSegment>[];
    _activeNavigationInstructions = const <RouteNavigationInstruction>[];
    _spokenFarApproachInstructionIds.clear();
    _spokenApproachInstructionIds.clear();
    _spokenImmediateInstructionIds.clear();
    _activeRouteTool = _RouteMapTool.addPoint;
    _selectedPointIndexForEdit = null;
    _selectedRouteId = null;
    _editingRouteId = null;
    _editingRouteName = null;
  }

  void _onRoutePointDragStart(int index) {
    if (_activeRouteTool != _RouteMapTool.editPoint) {
      return;
    }
    _updatePageState(() {
      _selectedPointIndexForEdit = index;
    });
  }

  void _onRoutePointDragUpdate(int index, LatLng point) {
    if (_activeRouteTool != _RouteMapTool.editPoint ||
        index < 0 ||
        index >= _draftRoutePoints.length) {
      return;
    }

    _updatePageState(() {
      final List<LatLng> updated = List<LatLng>.from(_draftRoutePoints);
      updated[index] = point;
      _draftRoutePoints = updated;
      _draftRoutePolyline = List<LatLng>.from(updated);
      _analyzeRouteForHazards();
      _selectedPointIndexForEdit = index;
    });
  }

  void _onRoutePointDragEnd(int index, LatLng point) {
    if (_activeRouteTool != _RouteMapTool.editPoint ||
        index < 0 ||
        index >= _draftRoutePoints.length) {
      return;
    }

    List<LatLng> updated = <LatLng>[];
    _updatePageState(() {
      updated = List<LatLng>.from(_draftRoutePoints);
      updated[index] = point;
      _draftRoutePoints = updated;
      _selectedPointIndexForEdit = index;
    });
    _refreshDraftRoutePolyline(updated);
  }

  Future<bool> _confirmDiscardDraftRoute() async {
    final bool isDarkMode = ref.read(themeModeProvider);

    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppPalette.dialogBackground(isDarkMode),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppPalette.border(isDarkMode)),
          ),
          title: Text(
            'Descartar ruta',
            style: TextStyle(
              color: AppPalette.dialogTitle(isDarkMode),
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Tienes puntos sin guardar. Si cierras este panel, se perderán.',
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
                'Descartar',
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

    return result ?? false;
  }

  void _reorderDraftPoints(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    List<LatLng> updated = <LatLng>[];
    _updatePageState(() {
      updated = List<LatLng>.from(_draftRoutePoints);
      final LatLng moved = updated.removeAt(oldIndex);
      updated.insert(newIndex, moved);
      _draftRoutePoints = updated;
      if (_selectedPointIndexForEdit == oldIndex) {
        _selectedPointIndexForEdit = newIndex;
      }
    });
    _refreshDraftRoutePolyline(updated);
  }

  void _removeDraftPoint(int index) {
    List<LatLng> updated = <LatLng>[];
    _updatePageState(() {
      updated = List<LatLng>.from(_draftRoutePoints);
      updated.removeAt(index);
      _draftRoutePoints = updated;
      if (_selectedPointIndexForEdit != null) {
        if (_selectedPointIndexForEdit == index) {
          _selectedPointIndexForEdit = null;
        } else if (_selectedPointIndexForEdit! > index) {
          _selectedPointIndexForEdit = _selectedPointIndexForEdit! - 1;
        }
      }
    });
    _refreshDraftRoutePolyline(updated);
  }

  void _onMapTap(LatLng point) {
    if (_activeReportSelectionContext == _ReportMapSelectionContext.lostPet) {
      _updatePageState(() {
        _manualLostPetLocation = point;
        _activeReportSelectionContext = null;
      });
      return;
    }

    if (_activeReportSelectionContext == _ReportMapSelectionContext.foundPet) {
      _updatePageState(() {
        _manualFoundPetLocation = point;
        _activeReportSelectionContext = null;
      });
      return;
    }

    if (_activeReportSelectionContext == _ReportMapSelectionContext.generic) {
      _updatePageState(() {
        _manualGenericReportLocation = point;
        _activeReportSelectionContext = null;
      });
      return;
    }

    if (_hasOpenPanels &&
        _panelStack.last.isReportHazardPanel &&
        _isSelectingHazardLocationOnMap) {
      _updatePageState(() {
        _manualHazardLocation = point;
        _isSelectingHazardLocationOnMap = false;
        _activeReportSelectionContext = null;
        _isReportHazardPanelMinimized = false;
      });
      return;
    }

    if (!_hasOpenPanels || !_panelStack.last.isAddRoutePanel) {
      return;
    }

    if (_activeRouteTool == _RouteMapTool.addPoint) {
      late final List<LatLng> updated;
      _updatePageState(() {
        updated = <LatLng>[..._draftRoutePoints, point];
        _draftRoutePoints = updated;
      });
      _refreshDraftRoutePolyline(updated);
      return;
    }

    if (_selectedPointIndexForEdit == null ||
        _selectedPointIndexForEdit! < 0 ||
        _selectedPointIndexForEdit! >= _draftRoutePoints.length) {
      return;
    }

    late final List<LatLng> updated;
    final int index = _selectedPointIndexForEdit!;
    _updatePageState(() {
      updated = List<LatLng>.from(_draftRoutePoints);
      updated[index] = point;
      _draftRoutePoints = updated;
    });
    _refreshDraftRoutePolyline(updated);
  }

  Future<int> _persistDraftRoute(String name) async {
    final String resolvedName = name.trim().isEmpty ? 'Ruta' : name.trim();
    final List<RoutePoint> points = _draftRoutePoints
        .map(
          (LatLng ll) =>
              RoutePoint(latitude: ll.latitude, longitude: ll.longitude),
        )
        .toList(growable: false);

    if (points.isEmpty) {
      throw StateError('No hay puntos para guardar la ruta.');
    }

    if (_editingRouteId != null) {
      await ref
          .read(routesControllerProvider.notifier)
          .updateRoute(
            routeId: _editingRouteId!,
            name: resolvedName,
            points: points,
          );
      if (!mounted) {
        return _editingRouteId!;
      }
      _updatePageState(() {
        _editingRouteName = resolvedName;
        _selectedRouteId = _editingRouteId;
      });
      return _editingRouteId!;
    }

    return ref
        .read(routesControllerProvider.notifier)
        .addRoute(name: resolvedName, points: points);
  }

  Future<void> _refreshDraftRoutePolyline(
    List<LatLng> waypoints, {
    bool keepCurrentPolylineWhileLoading = false,
  }) async {
    final int requestVersion = ++_routePolylineRequestVersion;

    if (!keepCurrentPolylineWhileLoading && mounted) {
      _updatePageState(() {
        _routePolylineWaypoints = List<LatLng>.from(waypoints);
        _draftRoutePolyline = List<LatLng>.from(waypoints);
        _analyzeRouteForHazards();
      });
    } else {
      _routePolylineWaypoints = List<LatLng>.from(waypoints);
    }

    if (waypoints.length < 2) {
      if (_isTripNavigationContext) {
        _updatePageState(() {
          _activeNavigationInstructions = const <RouteNavigationInstruction>[];
          _spokenFarApproachInstructionIds.clear();
          _spokenApproachInstructionIds.clear();
          _spokenImmediateInstructionIds.clear();
        });
      }
      return;
    }

    try {
      final LocalUserProfile profile = await ref
          .read(sessionStoreProvider)
          .getLocalUserProfile();
      final PlannedRouteResult routeResult = await _routingService
          .buildRoadRoute(
            waypoints: waypoints,
            hazardRiskFilters: _selectedTripHazardRiskFilters.toList(
              growable: false,
            ),
            travelMode: _selectedTripTransport == _TripTransportMethod.vehicle
                ? 'vehicle'
                : 'walking',
            tripConfig: <String, Object?>{
              'selected_pet_ids': _selectedTripPetIds.toList(growable: false),
              'selected_route_id': _selectedTripRoute?.id,
              'transport_method': _selectedTripTransport.name,
              'hazard_risk_filters': _selectedTripHazardRiskFilters.toList(
                growable: false,
              ),
            },
            bearerToken: profile.isAuthenticated == true
                ? profile.accessToken
                : null,
          );
      if (!mounted || requestVersion != _routePolylineRequestVersion) {
        return;
      }
      _updatePageState(() {
        _draftRoutePolyline = routeResult.polyline;
        if (_isTripNavigationContext) {
          _activeNavigationInstructions = routeResult.navigationInstructions;
        }
        _analyzeRouteForHazards();
      });
      if (_isTripNavigationContext) {
        //I don't get why we stop the speech here, but it was in the original code. Maybe to prevent overlapping instructions during route refreshes?
        //ref.read(audioFeedbackServiceProvider).stopSpeech();
      }
    } catch (_) {
      if (!mounted || requestVersion != _routePolylineRequestVersion) {
        return;
      }
      _updatePageState(() {
        if (_isTripNavigationContext) {
          _activeNavigationInstructions = const <RouteNavigationInstruction>[];
          _spokenFarApproachInstructionIds.clear();
          _spokenApproachInstructionIds.clear();
          _spokenImmediateInstructionIds.clear();
        }
        _analyzeRouteForHazards();
      });
    }
  }

  Future<void> _addCurrentLocationPoint() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final Position pos = await Geolocator.getCurrentPosition();
      if (!mounted) {
        return;
      }
      late final List<LatLng> updated;
      _updatePageState(() {
        updated = <LatLng>[
          ..._draftRoutePoints,
          LatLng(pos.latitude, pos.longitude),
        ];
        _draftRoutePoints = updated;
      });
      _refreshDraftRoutePolyline(updated);
    } catch (_) {
      return;
    }
  }
}
