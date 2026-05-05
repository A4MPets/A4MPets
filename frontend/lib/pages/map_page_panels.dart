part of 'map_page.dart';

extension _MapPagePanelsState on _MapPageState {
  void _pushPanel(_PanelRoute route) {
    _updatePageState(() {
      _panelStack.add(route);
    });
  }

  void _replaceTopPanel(_PanelRoute route) {
    _updatePageState(() {
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
    final bool returningToReportSelector =
        _panelStack.length > 1 &&
        _panelStack[_panelStack.length - 2].isReportSelectorPanel &&
        (currentPanel.isReportHazardPanel ||
            currentPanel.isLostPetReportPanel ||
            currentPanel.isFoundPetReportPanel ||
            currentPanel.isGenericReportPanel);
    final bool returningToTripRouteSelection =
        currentPanel.isAddRoutePanel &&
        _panelStack.length > 1 &&
        _panelStack[_panelStack.length - 2].isTripRouteSelectionPanel;

    if (currentPanel.isTripStartPanel) {
      _updatePageState(() {
        _clearTripSetupState();
        _isTripStartPanelMinimized = false;
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

      _updatePageState(() {
        _clearDraftRouteVisuals();
        _panelStack.removeLast();
      });
      if (returningToTripRouteSelection) {
        await _restoreTripRouteSelectionAfterEditorClose();
      }
      return;
    }

    _updatePageState(() {
      if (currentPanel.isAddRoutePanel) {
        _clearDraftRouteVisuals();
      }
      if (currentPanel.isTripStartPanel) {
        _isTripStartPanelMinimized = false;
      }
      if (currentPanel.isManageRoutesPanel) {
        _clearDraftRouteVisuals();
      }
      if (currentPanel.isReportHazardPanel) {
        _isSelectingHazardLocationOnMap = false;
        _activeReportSelectionContext = null;
        _manualHazardLocation = null;
        _hazardDraftPreview = null;
        _isReportHazardPanelMinimized = false;
      }
      if (currentPanel.isLostPetReportPanel) {
        _activeReportSelectionContext = null;
        _manualLostPetLocation = null;
        _selectedLostPetForReport = null;
      }
      if (currentPanel.isFoundPetReportPanel) {
        _activeReportSelectionContext = null;
        _manualFoundPetLocation = null;
      }
      if (currentPanel.isGenericReportPanel) {
        _activeReportSelectionContext = null;
        _manualGenericReportLocation = null;
        _genericReportDraftPreview = null;
      }
      if (currentPanel.isHazardDetailsPanel) {
        _selectedHazard = null;
      }
      if (currentPanel.isLostPetDetailsPanel) {
        _selectedLostPetReport = null;
      }
      if (currentPanel.isFoundPetDetailsPanel) {
        _selectedFoundPetReport = null;
      }
      if (currentPanel.isGenericReportDetailsPanel) {
        _selectedGenericReport = null;
      }
      _panelStack.removeLast();
      if (returningToReportSelector) {
        _reloadReportData();
      }
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
    final bool panelCanMinimize =
        currentPanel.isReportHazardPanel || currentPanel.isTripStartPanel
        ? true
        : currentPanel.canMinimize;
    final bool panelIsMinimized = currentPanel.isReportHazardPanel
        ? _isReportHazardPanelMinimized
        : (currentPanel.isTripStartPanel
              ? _isTripStartPanelMinimized
              : currentPanel.isMinimized);
    final VoidCallback? panelToggleMinimize = currentPanel.isReportHazardPanel
        ? _toggleReportHazardPanelMinimized
        : (currentPanel.isTripStartPanel
              ? _toggleTripStartPanelMinimized
              : currentPanel.onToggleMinimize);

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
          mobileMaxHeightFactor: currentPanel.mobileMaxHeightFactor,
          desktopMaxHeightFactor: currentPanel.desktopMaxHeightFactor,
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
          canMinimize: panelCanMinimize,
          isMinimized: panelIsMinimized,
          minimizedHeight: currentPanel.minimizedHeight,
          onToggleMinimize: panelToggleMinimize,
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

    if (panel.isManagePetsPanel ||
        panel.isLostPetPetSelectionPanel ||
        panel.isTripPetSelectionPanel) {
      final AsyncValue<List<PetRecord>> petsValue = ref.watch(
        myPetsControllerProvider,
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
        panel.isLostPetDetailsPanel ||
        panel.isFoundPetDetailsPanel ||
        panel.isGenericReportDetailsPanel ||
        panel.isHazardCommentsPanel ||
        panel.isHazardSettingsPanel) {
      final AsyncValue<List<HazardReportRecord>> hazardsValue = ref.watch(
        hazardReportsControllerProvider,
      );
      final AsyncValue<List<LostPetReportRecord>> lostPetReportsValue = ref
          .watch(lostPetReportsControllerProvider);
      final AsyncValue<List<FoundPetReportRecord>> foundPetReportsValue = ref
          .watch(foundPetReportsControllerProvider);
      final AsyncValue<List<GenericReportRecord>> genericReportsValue = ref
          .watch(genericReportsControllerProvider);
      loading =
          loading ||
          hazardsValue.isLoading ||
          lostPetReportsValue.isLoading ||
          foundPetReportsValue.isLoading ||
          genericReportsValue.isLoading;
    }

    if (panel.isReportHazardPanel ||
        panel.isLostPetReportPanel ||
        panel.isFoundPetReportPanel ||
        panel.isGenericReportPanel) {
      loading = loading || _isUserLocationLoading;
    }

    return loading;
  }
}
