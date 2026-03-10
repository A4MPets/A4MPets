import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../providers/theme_provider.dart';
import '../models/pet_record.dart';
import '../widgets/auth_panels.dart';
import '../widgets/map_widget.dart';
import '../widgets/panel_modal.dart';
import '../widgets/pet_management_panels.dart';
import '../widgets/profile_menu_panel.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final List<_PanelRoute> _panelStack = <_PanelRoute>[];
  int _panelTransitionSeed = 0;

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
          onManageRoutesPressed: () {},
        );
      },
    );
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

  void _closeCurrentPanel() {
    if (!_hasOpenPanels) {
      return;
    }

    setState(() {
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
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.18),
          ),
        ),
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
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });
}
