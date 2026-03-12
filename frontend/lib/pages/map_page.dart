import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/pet_record.dart';
import '../models/route_record.dart';
import '../providers/theme_provider.dart';
import '../services/osm_routing_service.dart';
import '../theme/app_palette.dart';
import '../widgets/auth_panels.dart';
import '../widgets/map_widget.dart';
import '../widgets/panel_modal.dart';
import '../widgets/pet_management_panels.dart';
import '../widgets/profile_menu_panel.dart';
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
      height: 620,
      maxHeight: 620,
      adaptHeightToContent: false,
      expandHorizontal: false,
      expandVertical: true,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo trazar por vías en este momento.'),
        ),
      );
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Permiso de ubicación denegado')),
          );
        }
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
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo obtener la ubicación: $error')),
        );
      }
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
        onMapTap: _onMapTap,
        onThemeToggle: () {
          ref.read(themeModeProvider.notifier).state = !isDarkMode;
        },
        onStartTrip: () {
          // TODO: Implement start trip logic
          print('Start trip triggered');
        },
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
  final bool adaptHeightToContent;
  final bool expandHorizontal;
  final bool expandVertical;
  final bool scrollContent;
  final bool isAddRoutePanel;
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
    this.adaptHeightToContent = false,
    this.expandHorizontal = false,
    this.expandVertical = false,
    this.scrollContent = true,
    this.isAddRoutePanel = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });
}
