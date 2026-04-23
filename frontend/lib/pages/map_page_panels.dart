// ignore_for_file: invalid_use_of_protected_member

part of 'map_page.dart';

extension _MapPagePanelsState on _MapPageState {
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

  void _closeCurrentPanel() async {
    if (!_hasOpenPanels) {
      return;
    }

    final _PanelRoute currentPanel = _panelStack.last;
    final bool returningToTripRouteSelection =
        currentPanel.isAddRoutePanel &&
        _panelStack.length > 1 &&
        _panelStack[_panelStack.length - 2].isTripRouteSelectionPanel;

    if (currentPanel.isTripStartPanel) {
      setState(() {
        _clearTripSetupState();
        _panelStack.removeWhere(
          (_PanelRoute route) =>
              route.isTripStartPanel ||
              route.isTripPetSelectionPanel ||
              route.isTripRouteSelectionPanel,
        );
      });
      return;
    }

    if (currentPanel.isTripPetSelectionPanel ||
        currentPanel.isTripRouteSelectionPanel) {
      final bool isDarkMode = ref.read(themeModeProvider);
      _returnToTripStartPanel(isDarkMode);
      return;
    }

    if (currentPanel.isTripPanel) {
      await _finishTripManually();
      return;
    }

    if (currentPanel.isAddRoutePanel && _draftRoutePoints.isNotEmpty) {
      final bool discard = await _confirmDiscardDraftRoute();
      if (!discard || !mounted) {
        return;
      }

      setState(() {
        _clearDraftRouteVisuals();
        _panelStack.removeLast();
      });
      if (returningToTripRouteSelection) {
        await _restoreTripRouteSelectionAfterEditorClose();
      }
      return;
    }

    setState(() {
      if (currentPanel.isAddRoutePanel) {
        _clearDraftRouteVisuals();
      }
      if (currentPanel.isManageRoutesPanel) {
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

    if (returningToTripRouteSelection) {
      await _restoreTripRouteSelectionAfterEditorClose();
    }
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
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: _hasOpenPanels
          ? _buildOpenedPanelOverlay(isDarkMode)
          : const SizedBox.shrink(key: ValueKey<String>('no-panel')),
    );
  }

  Widget _buildOpenedPanelOverlay(bool isDarkMode) {
    final _PanelRoute currentPanel = _panelStack.last;
    final bool panelLoading = _isPanelLoading(currentPanel);

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
          contentTopPadding: currentPanel.contentTopPadding,
          borderRadius: currentPanel.borderRadius,
          showBackButton:
              _panelStack.length > 1 &&
              !currentPanel.isTripStartPanel &&
              !currentPanel.isTripPanel &&
              !currentPanel.isTripPetSelectionPanel &&
              !currentPanel.isTripRouteSelectionPanel,
          showLoadingIndicator: panelLoading,
          onClosePressed: _closeCurrentPanel,
          child: currentPanel.contentBuilder(context),
        ),
      ],
    );
  }

  bool _isPanelLoading(_PanelRoute panel) {
    bool loading = false;

    if (panel.isLoginPanel || panel.isRegisterPanel || panel.isProfilePanel) {
      loading = loading || _isAuthRequestLoading;
    }

    if (panel.isManagePetsPanel || panel.isTripPetSelectionPanel) {
      final AsyncValue<List<PetRecord>> petsValue = ref.watch(
        petsControllerProvider,
      );
      final AsyncValue<LocalUserProfile> profileValue = ref.watch(
        localUserProfileProvider,
      );
      loading = loading || petsValue.isLoading || profileValue.isLoading;
    }

    if (panel.isManageRoutesPanel || panel.isTripRouteSelectionPanel) {
      final AsyncValue<List<RouteRecord>> routesValue = ref.watch(
        routesControllerProvider,
      );
      loading = loading || routesValue.isLoading;
    }

    if (panel.isHazardDetailsPanel ||
        panel.isHazardCommentsPanel ||
        panel.isHazardSettingsPanel) {
      final AsyncValue<List<HazardReportRecord>> hazardsValue = ref.watch(
        hazardReportsControllerProvider,
      );
      loading = loading || hazardsValue.isLoading;
    }

    return loading;
  }
}
