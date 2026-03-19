import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/pet_record.dart';
import '../models/hazard_report_record.dart';
import '../models/route_record.dart';
import '../providers/local_data_providers.dart';
import '../providers/theme_provider.dart';
import '../services/osm_routing_service.dart';
import '../theme/app_palette.dart';
import '../widgets/auth_panels.dart';
import '../widgets/map_widget.dart';
import '../widgets/panel_modal.dart';
import '../widgets/pet_management_panels.dart';
import '../widgets/profile_menu_panel.dart';
import '../widgets/hazard_reporting_panel.dart';
import '../widgets/hazard_details_panel.dart';
import '../widgets/hazard_comments_panel.dart';
import '../widgets/hazard_layers_panel.dart';
import '../widgets/route_management_panels.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

enum _RouteMapTool { addPoint, editPoint }

class _MapPageState extends ConsumerState<MapPage> {
  final List<_PanelRoute> _panelStack = <_PanelRoute>[];
  int _panelTransitionSeed = 0;
  final OsmRoutingService _routingService = OsmRoutingService();

  List<LatLng> _draftRoutePoints = <LatLng>[];
  List<LatLng> _draftRoutePolyline = <LatLng>[];
  _RouteMapTool _activeRouteTool = _RouteMapTool.addPoint;
  int? _selectedPointIndexForEdit;
  int? _selectedRouteId;
  int? _editingRouteId;
  String? _editingRouteName;
  bool _isSelectingHazardLocationOnMap = false;
  LatLng? _developerHazardLocation;
  HazardReportRecord? _selectedHazard;
  int _hazardFocusRevision = 0;
  bool _showLowRiskHazardCircles = true;
  bool _showMediumRiskHazardCircles = true;
  bool _showHighRiskHazardCircles = true;

  bool get _hasOpenPanels => _panelStack.isNotEmpty;

  void _pushPanel(_PanelRoute route) {
    setState(() {
      _panelStack.add(route);
    });
  }

  void _replaceTopPanel(_PanelRoute route) {
    setState(() {
      if (_panelStack.isNotEmpty) {
        _panelStack.removeLast();
      }
      _panelStack.add(route);
    });
  }

  void _openProfilePanel(bool isDarkMode) {
    if (_hasOpenPanels) {
      return;
    }

    _pushPanel(_buildProfileRoute(isDarkMode));
  }

  void _openLoginPanel(bool isDarkMode) {
    _pushPanel(_buildLoginRoute(isDarkMode));
  }

  void _openRegisterPanel(bool isDarkMode) {
    _pushPanel(_buildRegisterRoute(isDarkMode));
  }

  void _switchToLoginPanel(bool isDarkMode) {
    _replaceTopPanel(_buildLoginRoute(isDarkMode));
  }

  void _switchToRegisterPanel(bool isDarkMode) {
    _replaceTopPanel(_buildRegisterRoute(isDarkMode));
  }

  void _openManagePetsPanel(bool isDarkMode) {
    _pushPanel(_buildManagePetsRoute(isDarkMode));
  }

  void _openAddPetPanel(bool isDarkMode) {
    _pushPanel(_buildAddPetRoute(isDarkMode));
  }

  void _openEditPetPanel(bool isDarkMode, PetRecord pet) {
    _pushPanel(_buildEditPetRoute(isDarkMode, pet));
  }

  void _openManageRoutesPanel(bool isDarkMode) {
    _pushPanel(_buildManageRoutesRoute(isDarkMode));
  }

  void _openReportHazardPanel(bool isDarkMode) {
    if (_hasOpenPanels) {
      return;
    }
    setState(() {
      _isSelectingHazardLocationOnMap = false;
      _developerHazardLocation = null;
    });
    _pushPanel(_buildReportHazardRoute(isDarkMode));
  }

  void _openHazardLayersSettingsPanel(bool isDarkMode) {
    if (_hasOpenPanels) {
      return;
    }

    _pushPanel(_buildHazardLayersSettingsRoute());
  }

  Future<void> _openHazardDetailsPanel(
    bool isDarkMode,
    HazardReportRecord hazard,
  ) async {
    if (_hasOpenPanels && !_panelStack.last.isHazardDetailsPanel) {
      final _PanelRoute currentPanel = _panelStack.last;

      if (currentPanel.isAddRoutePanel && _draftRoutePoints.isNotEmpty) {
        final bool discard = await _confirmDiscardDraftRoute();
        if (!discard || !mounted) {
          return;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        if (currentPanel.isAddRoutePanel) {
          _clearDraftRouteVisuals();
        }
        if (currentPanel.isReportHazardPanel) {
          _isSelectingHazardLocationOnMap = false;
          _developerHazardLocation = null;
        }
        if (currentPanel.isHazardDetailsPanel) {
          _selectedHazard = null;
        }
        _panelStack.removeLast();
      });
    }

    setState(() {
      _selectedHazard = hazard;
      _hazardFocusRevision += 1;
    });

    final _PanelRoute route = _buildHazardDetailsRoute(isDarkMode, hazard);
    if (_hasOpenPanels && _panelStack.last.isHazardDetailsPanel) {
      _replaceTopPanel(route);
      return;
    }

    if (_hasOpenPanels) {
      return;
    }

    _pushPanel(route);
  }

  void _openHazardCommentsPanel(bool isDarkMode, HazardReportRecord hazard) {
    _pushPanel(_buildHazardCommentsRoute(isDarkMode, hazard));
  }

  void _startDeveloperHazardMapSelection() {
    setState(() {
      _isSelectingHazardLocationOnMap = true;
    });
  }

  void _clearDeveloperHazardMapSelection() {
    setState(() {
      _isSelectingHazardLocationOnMap = false;
      _developerHazardLocation = null;
    });
  }

  void _openAddRoutePanel(bool isDarkMode) {
    setState(() {
      _draftRoutePoints = <LatLng>[];
      _draftRoutePolyline = <LatLng>[];
      _activeRouteTool = _RouteMapTool.addPoint;
      _selectedPointIndexForEdit = null;
      _selectedRouteId = null;
      _editingRouteId = null;
      _editingRouteName = null;
    });
    _pushPanel(_buildAddRouteRoute(isDarkMode));
  }

  void _openEditRoutePanel(bool isDarkMode, RouteRecord route) {
    final List<LatLng> points = route.points.map((RoutePoint p) => p.toLatLng()).toList();
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
    _pushPanel(_buildAddRouteRoute(isDarkMode));
  }

  void _showRouteOnMap(RouteRecord route) {
    final List<LatLng> points = route.points.map((RoutePoint p) => p.toLatLng()).toList();
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

  _PanelRoute _buildProfileRoute(bool isDarkMode) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: null,
      anchor: PanelAnchor.topLeft,
      width: 360,
      height: 510,
      maxHeight: 510,
      adaptHeightToContent: true,
      expandHorizontal: false,
      expandVertical: false,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return ProfileMenuPanel(
          isDarkMode: isDarkMode,
          onLoginPressed: () => _openLoginPanel(isDarkMode),
          onRegisterPressed: () => _openRegisterPanel(isDarkMode),
          onManagePetsPressed: () => _openManagePetsPanel(isDarkMode),
          onManageRoutesPressed: () => _openManageRoutesPanel(isDarkMode),
        );
      },
    );
  }

  _PanelRoute _buildManageRoutesRoute(bool isDarkMode) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Gestionar Rutas',
      anchor: PanelAnchor.topLeft,
      width: 380,
      maxHeightFactor: 0.40,
      adaptHeightToContent: false,
      expandHorizontal: false,
      expandVertical: false,
      scrollContent: false,
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

  _PanelRoute _buildReportHazardRoute(bool isDarkMode) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Reportar Peligro',
      anchor: PanelAnchor.bottomLeft,
      width: 380,
      height: 620,
      maxHeight: 620,
      adaptHeightToContent: false,
      expandHorizontal: false,
      expandVertical: false,
      scrollContent: false,
      isReportHazardPanel: true,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return ReportHazardPanelContent(
          isDarkMode: isDarkMode,
          developerSelectedLocation: _developerHazardLocation,
          isDeveloperSelectingOnMap: _isSelectingHazardLocationOnMap,
          onStartDeveloperMapSelection: _startDeveloperHazardMapSelection,
          onClearDeveloperLocation: _clearDeveloperHazardMapSelection,
          onReported: () {
            _closeCurrentPanel();
          },
        );
      },
    );
  }

  _PanelRoute _buildHazardLayersSettingsRoute() {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Configuración de mapa',
      anchor: PanelAnchor.topRight,
      width: 360,
      height: 260,
      maxHeight: 320,
      adaptHeightToContent: false,
      expandHorizontal: false,
      expandVertical: false,
      scrollContent: false,
      isHazardSettingsPanel: true,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? child) {
            final bool currentDarkMode = ref.watch(themeModeProvider);

            return HazardLayersPanelContent(
              isDarkMode: currentDarkMode,
              isDarkModeEnabled: currentDarkMode,
              showLowRiskCircles: _showLowRiskHazardCircles,
              showMediumRiskCircles: _showMediumRiskHazardCircles,
              showHighRiskCircles: _showHighRiskHazardCircles,
              onToggleDarkMode: (bool value) {
                ref.read(themeModeProvider.notifier).state = value;
              },
              onToggleLowRisk: (bool value) {
                setState(() {
                  _showLowRiskHazardCircles = value;
                });
              },
              onToggleMediumRisk: (bool value) {
                setState(() {
                  _showMediumRiskHazardCircles = value;
                });
              },
              onToggleHighRisk: (bool value) {
                setState(() {
                  _showHighRiskHazardCircles = value;
                });
              },
            );
          },
        );
      },
    );
  }

  _PanelRoute _buildHazardDetailsRoute(
    bool isDarkMode,
    HazardReportRecord hazard,
  ) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Detalle de Peligro',
      anchor: PanelAnchor.bottomLeft,
      width: 380,
      height: 560,
      maxHeight: 620,
      adaptHeightToContent: false,
      expandHorizontal: false,
      expandVertical: false,
      scrollContent: false,
      isHazardDetailsPanel: true,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return HazardDetailsPanelContent(
          isDarkMode: isDarkMode,
          hazard: hazard,
          onViewComments: () => _openHazardCommentsPanel(isDarkMode, hazard),
        );
      },
    );
  }

  _PanelRoute _buildHazardCommentsRoute(
    bool isDarkMode,
    HazardReportRecord hazard,
  ) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Comentarios',
      anchor: PanelAnchor.bottomLeft,
      width: 380,
      height: 560,
      maxHeight: 620,
      adaptHeightToContent: false,
      expandHorizontal: false,
      expandVertical: false,
      scrollContent: false,
      isHazardCommentsPanel: true,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return HazardCommentsPanelContent(
          isDarkMode: isDarkMode,
          hazard: hazard,
        );
      },
    );
  }

  _PanelRoute _buildAddRouteRoute(bool isDarkMode) {
    final bool isEditing = _editingRouteId != null;

    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: isEditing ? 'Editar Ruta' : 'Agregar Ruta',
      anchor: PanelAnchor.topLeft,
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
            setState(() {
              _clearDraftRouteVisuals();
            });
            _closeCurrentPanel();
          },
        );
      },
    );
  }

  void _clearDraftRouteVisuals() {
    _draftRoutePoints = <LatLng>[];
    _draftRoutePolyline = <LatLng>[];
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

  Future<void> _refreshDraftRoutePolyline(List<LatLng> waypoints) async {
    if (waypoints.length < 2) {
      if (!mounted) return;
      setState(() {
        _draftRoutePolyline = List<LatLng>.from(waypoints);
      });
      return;
    }

    try {
      final List<LatLng> polyline =
          await _routingService.buildRoadRoute(waypoints: waypoints);
      if (!mounted) return;
      setState(() {
        _draftRoutePolyline = polyline;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _draftRoutePolyline = List<LatLng>.from(waypoints);
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
      if (!mounted) return;
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

  _PanelRoute _buildLoginRoute(bool isDarkMode) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Iniciar Sesión',
      anchor: PanelAnchor.topLeft,
      width: 360,
      height: 430,
      maxHeight: 520,
      adaptHeightToContent: true,
      expandHorizontal: false,
      expandVertical: false,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return LoginPanelContent(
          isDarkMode: isDarkMode,
          onSwitchToRegister: () => _switchToRegisterPanel(isDarkMode),
          onSubmit: () {},
        );
      },
    );
  }

  _PanelRoute _buildManagePetsRoute(bool isDarkMode) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Gestionar Mascotas',
      anchor: PanelAnchor.topLeft,
      width: 380,
      height: 620,
      maxHeight: 620,
      adaptHeightToContent: false,
      expandHorizontal: false,
      expandVertical: true,
      scrollContent: false,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return ManagePetsPanelContent(
          isDarkMode: isDarkMode,
          onAddPetPressed: () => _openAddPetPanel(isDarkMode),
          onEditPetPressed: (PetRecord pet) => _openEditPetPanel(isDarkMode, pet),
        );
      },
    );
  }

  _PanelRoute _buildAddPetRoute(bool isDarkMode) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Agregar mascota',
      anchor: PanelAnchor.topLeft,
      width: 380,
      height: 620,
      maxHeight: 620,
      adaptHeightToContent: false,
      expandHorizontal: false,
      expandVertical: true,
      scrollContent: false,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return AddPetPanelContent(
          isDarkMode: isDarkMode,
          onSaved: _closeCurrentPanel,
        );
      },
    );
  }

  _PanelRoute _buildEditPetRoute(bool isDarkMode, PetRecord pet) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Editar mascota',
      anchor: PanelAnchor.topLeft,
      width: 380,
      height: 620,
      maxHeight: 620,
      adaptHeightToContent: false,
      expandHorizontal: false,
      expandVertical: true,
      scrollContent: false,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return EditPetPanelContent(
          pet: pet,
          isDarkMode: isDarkMode,
          onSaved: _closeCurrentPanel,
        );
      },
    );
  }

  _PanelRoute _buildRegisterRoute(bool isDarkMode) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Registrarse',
      anchor: PanelAnchor.topLeft,
      width: 360,
      height: 520,
      maxHeight: 620,
      adaptHeightToContent: true,
      expandHorizontal: false,
      expandVertical: false,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return RegisterPanelContent(
          isDarkMode: isDarkMode,
          onSwitchToLogin: () => _switchToLoginPanel(isDarkMode),
          onSubmit: () {},
        );
      },
    );
  }

  void _closeCurrentPanel() async {
    if (!_hasOpenPanels) {
      return;
    }

    final _PanelRoute currentPanel = _panelStack.last;

    if (currentPanel.isAddRoutePanel && _draftRoutePoints.isNotEmpty) {
      final bool discard = await _confirmDiscardDraftRoute();
      if (!discard || !mounted) {
        return;
      }

      setState(() {
        _clearDraftRouteVisuals();
        _panelStack.removeLast();
      });
      return;
    }

    setState(() {
      if (currentPanel.isAddRoutePanel) {
        _clearDraftRouteVisuals();
      }
      if (currentPanel.isReportHazardPanel) {
        _isSelectingHazardLocationOnMap = false;
        _developerHazardLocation = null;
      }
      if (currentPanel.isHazardDetailsPanel) {
        _selectedHazard = null;
      }
      _panelStack.removeLast();
    });
  }

  Widget _buildPanelOverlay(bool isDarkMode) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 190),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final Animation<Offset> slide = Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: slide,
            child: child,
          ),
        );
      },
      child: _hasOpenPanels
          ? _buildOpenedPanelOverlay(isDarkMode)
          : const SizedBox.shrink(key: ValueKey<String>('no-panel')),
    );
  }

  Widget _buildOpenedPanelOverlay(bool isDarkMode) {
    final _PanelRoute currentPanel = _panelStack.last;

    return Stack(
      key: ValueKey<int>(currentPanel.transitionKey),
      children: [
        AppModalPanel(
          isDarkMode: isDarkMode,
          title: currentPanel.title,
          anchor: currentPanel.anchor,
          width: currentPanel.width,
          height: currentPanel.height,
          maxHeight: currentPanel.maxHeight,
          maxHeightFactor: currentPanel.maxHeightFactor,
          adaptHeightToContent: currentPanel.adaptHeightToContent,
          expandHorizontal: currentPanel.expandHorizontal,
          expandVertical: currentPanel.expandVertical,
          scrollContent: currentPanel.scrollContent,
          borderRadius: currentPanel.borderRadius,
          showBackButton: _panelStack.length > 1,
          onClosePressed: _closeCurrentPanel,
          child: currentPanel.contentBuilder(context),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = ref.watch(themeModeProvider);
    final List<HazardReportRecord> hazardReports =
        ref.watch(hazardReportsControllerProvider).asData?.value ??
            const <HazardReportRecord>[];
    final List<HazardReportRecord> visibleHazardCircles = hazardReports.where(
      (HazardReportRecord report) {
        switch (report.riskLevelCode) {
          case 'low':
            return _showLowRiskHazardCircles;
          case 'medium':
            return _showMediumRiskHazardCircles;
          case 'high':
            return _showHighRiskHazardCircles;
          default:
            return _showHighRiskHazardCircles;
        }
      },
    ).toList(growable: false);

    return Scaffold(
      body: MapWidget(
        isDarkMode: isDarkMode,
        center: const LatLng(3.4516, -76.5320),
        zoom: 13,
        hideDefaultControls: _hasOpenPanels,
        onProfileTap: () => _openProfilePanel(isDarkMode),
        panelOverlay: _buildPanelOverlay(isDarkMode),
        routePoints: _draftRoutePoints,
        routePolylinePoints: _draftRoutePolyline,
        selectedRoutePointIndex: _selectedPointIndexForEdit,
        onRoutePointPointerDown: (int index) {
          if (_activeRouteTool != _RouteMapTool.editPoint) {
            return;
          }
          setState(() {
            _selectedPointIndexForEdit = index;
          });
        },
        canDragRoutePoints: _hasOpenPanels &&
            _panelStack.last.isAddRoutePanel &&
            _activeRouteTool == _RouteMapTool.editPoint,
        onRoutePointDragStart: _onRoutePointDragStart,
        onRoutePointDragUpdate: _onRoutePointDragUpdate,
        onRoutePointDragEnd: _onRoutePointDragEnd,
        onRoutePointTap: (int index) {
          if (_activeRouteTool != _RouteMapTool.editPoint) {
            return;
          }
          setState(() {
            _selectedPointIndexForEdit = index;
          });
        },
        isSelectingRoutePoint: _hasOpenPanels &&
            _panelStack.last.isAddRoutePanel &&
            _activeRouteTool == _RouteMapTool.addPoint,
        hazardReports: hazardReports,
        visibleHazardCircles: visibleHazardCircles,
        highlightedHazard: _selectedHazard,
        onHazardTap: (HazardReportRecord hazard) {
          _openHazardDetailsPanel(isDarkMode, hazard);
        },
        cameraFocusTarget: _selectedHazard == null
            ? null
            : LatLng(
                _selectedHazard!.incidentLatitude,
                _selectedHazard!.incidentLongitude,
              ),
        cameraFocusZoom: _selectedHazard == null ? null : 16,
        cameraFocusRevision: _hazardFocusRevision,
        onMapTap: _onMapTap,
        onSettingsTap: () => _openHazardLayersSettingsPanel(isDarkMode),
        onStartTrip: () {
          // TODO: Implement start trip logic
          print('Start trip triggered');
        },
        onReportDangerTap: () => _openReportHazardPanel(isDarkMode),
      ),
    );
  }
}

class _PanelRoute {
  final int transitionKey;
  final String? title;
  final PanelAnchor anchor;
  final double? width;
  final double? height;
  final double? maxHeight;
  final double? maxHeightFactor;
  final bool adaptHeightToContent;
  final bool expandHorizontal;
  final bool expandVertical;
  final bool scrollContent;
  final bool isAddRoutePanel;
  final bool isReportHazardPanel;
  final bool isHazardDetailsPanel;
  final bool isHazardSettingsPanel;
  final bool isHazardCommentsPanel;
  final BorderRadius borderRadius;
  final Widget Function(BuildContext context) contentBuilder;

  _PanelRoute({
    required this.transitionKey,
    required this.contentBuilder,
    this.title,
    this.anchor = PanelAnchor.topLeft,
    this.width,
    this.height,
    this.maxHeight,
    this.maxHeightFactor,
    this.adaptHeightToContent = false,
    this.expandHorizontal = false,
    this.expandVertical = false,
    this.scrollContent = true,
    this.isAddRoutePanel = false,
    this.isReportHazardPanel = false,
    this.isHazardDetailsPanel = false,
    this.isHazardSettingsPanel = false,
    this.isHazardCommentsPanel = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });
}
