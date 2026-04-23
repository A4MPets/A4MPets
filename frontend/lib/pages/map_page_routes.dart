// ignore_for_file: invalid_use_of_protected_member

part of 'map_page.dart';

extension _MapPageRoutesState on _MapPageState {
  void _openManageRoutesPanel(bool isDarkMode) {
    _pushPanel(_buildManageRoutesRoute(isDarkMode));
  }

  void _openAddRoutePanel(bool isDarkMode) {
    setState(() {
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
    setState(() {
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
    setState(() {
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
      setState(() {
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
            setState(() {
              _activeRouteTool = _RouteMapTool.addPoint;
              _selectedPointIndexForEdit = null;
            });
          },
          onSelectEditTool: () {
            setState(() {
              _activeRouteTool = _RouteMapTool.editPoint;
            });
          },
          selectedPointIndex: _selectedPointIndexForEdit,
          onSelectPointForMapEdit: (int index) {
            setState(() {
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
          onSavedComplete: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) {
                return;
              }
              _closeAddRoutePanelAfterSave();
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
    _hazardColoredRouteSegments = <dynamic>[];
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
    setState(() {
      _selectedPointIndexForEdit = index;
    });
  }

  void _onRoutePointDragUpdate(int index, LatLng point) {
    if (_activeRouteTool != _RouteMapTool.editPoint ||
        index < 0 ||
        index >= _draftRoutePoints.length) {
      return;
    }

    setState(() {
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
    setState(() {
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
    setState(() {
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
    setState(() {
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
    if (_hasOpenPanels &&
        _panelStack.last.isReportHazardPanel &&
        _isSelectingHazardLocationOnMap) {
      setState(() {
        _developerHazardLocation = point;
        _isSelectingHazardLocationOnMap = false;
      });
      return;
    }

    if (!_hasOpenPanels || !_panelStack.last.isAddRoutePanel) {
      return;
    }

    if (_activeRouteTool == _RouteMapTool.addPoint) {
      late final List<LatLng> updated;
      setState(() {
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
    setState(() {
      updated = List<LatLng>.from(_draftRoutePoints);
      updated[index] = point;
      _draftRoutePoints = updated;
    });
    _refreshDraftRoutePolyline(updated);
  }

  Future<void> _refreshDraftRoutePolyline(
    List<LatLng> waypoints, {
    bool keepCurrentPolylineWhileLoading = false,
  }) async {
    final int requestVersion = ++_routePolylineRequestVersion;

    if (!keepCurrentPolylineWhileLoading && mounted) {
      setState(() {
        _draftRoutePolyline = List<LatLng>.from(waypoints);
        _analyzeRouteForHazards();
      });
    }

    if (waypoints.length < 2) {
      return;
    }

    try {
      final List<LatLng> polyline = await _routingService.buildRoadRoute(
        waypoints: waypoints,
        avoidHazards: _shouldAvoidHazardsInRouting,
        travelMode: _selectedTripTransport == _TripTransportMethod.vehicle
            ? 'vehicle'
            : 'walking',
        tripConfig: <String, Object?>{
          'selected_pet_ids': _selectedTripPetIds.toList(growable: false),
          'selected_route_id': _selectedTripRoute?.id,
          'transport_method': _selectedTripTransport.name,
        },
      );
      if (!mounted || requestVersion != _routePolylineRequestVersion) {
        return;
      }
      setState(() {
        _draftRoutePolyline = polyline;
        _analyzeRouteForHazards();
      });
    } catch (_) {
      if (!mounted || requestVersion != _routePolylineRequestVersion) {
        return;
      }
      setState(_analyzeRouteForHazards);
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
      setState(() {
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
