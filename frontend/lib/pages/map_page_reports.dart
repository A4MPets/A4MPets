part of 'map_page.dart';

extension _MapPageReportsState on _MapPageState {
  List<LostPetReportRecord> get _visibleLostPetReports {
    if (!_showLostPetReports) {
      return const <LostPetReportRecord>[];
    }

    return ref
        .watch(lostPetReportsControllerProvider)
        .maybeWhen(
          data: (reports) => reports,
          orElse: () => <LostPetReportRecord>[],
        );
  }

  List<FoundPetReportRecord> get _visibleFoundPetReports {
    if (!_showFoundPetReports) {
      return const <FoundPetReportRecord>[];
    }

    return ref
        .watch(foundPetReportsControllerProvider)
        .maybeWhen(
          data: (reports) => reports,
          orElse: () => <FoundPetReportRecord>[],
        );
  }

  List<GenericReportRecord> get _visibleGenericReports {
    if (!_showGenericReports) {
      return const <GenericReportRecord>[];
    }

    return ref
        .watch(genericReportsControllerProvider)
        .maybeWhen(
          data: (reports) => reports,
          orElse: () => <GenericReportRecord>[],
        );
  }

  void _openReportTypeSelectorPanel(bool isDarkMode) {
    if (_hasOpenPanels &&
        !_panelStack.last.isTripPanel &&
        !_panelStack.last.isTripStartPanel) {
      return;
    }

    _pushPanel(_buildReportSelectorRoute(isDarkMode));
  }

  void _openLostPetReportPanel(bool isDarkMode) {
    _updatePageState(() {
      _manualLostPetLocation = null;
      _activeReportSelectionContext = null;
    });
    _replaceOrPushReportPanel(_buildLostPetReportRoute(isDarkMode));
  }

  void _openFoundPetReportPanel(bool isDarkMode) {
    _updatePageState(() {
      _manualFoundPetLocation = null;
      _activeReportSelectionContext = null;
    });
    _replaceOrPushReportPanel(_buildFoundPetReportRoute(isDarkMode));
  }

  void _openGenericReportPanel(bool isDarkMode) {
    _updatePageState(() {
      _manualGenericReportLocation = null;
      _activeReportSelectionContext = null;
    });
    _replaceOrPushReportPanel(_buildGenericReportRoute(isDarkMode));
  }

  void _replaceOrPushReportPanel(_PanelRoute route) {
    if (_hasOpenPanels && _panelStack.last.isReportSelectorPanel) {
      _replaceTopPanel(route);
      return;
    }
    _pushPanel(route);
  }

  void _startLostPetMapSelection() {
    _updatePageState(() {
      _activeReportSelectionContext = _ReportMapSelectionContext.lostPet;
    });
  }

  void _startFoundPetMapSelection() {
    _updatePageState(() {
      _activeReportSelectionContext = _ReportMapSelectionContext.foundPet;
    });
  }

  void _startGenericReportMapSelection() {
    _updatePageState(() {
      _activeReportSelectionContext = _ReportMapSelectionContext.generic;
    });
  }

  void _useCurrentLostPetLocation() {
    _updatePageState(() {
      _manualLostPetLocation = null;
      _activeReportSelectionContext = null;
      if (_latestUserLocation == null || _userLocationErrorText != null) {
        _isUserLocationLoading = true;
        _userLocationErrorText = null;
        _userLocationRefreshRevision += 1;
      }
    });
  }

  void _useCurrentFoundPetLocation() {
    _updatePageState(() {
      _manualFoundPetLocation = null;
      _activeReportSelectionContext = null;
      if (_latestUserLocation == null || _userLocationErrorText != null) {
        _isUserLocationLoading = true;
        _userLocationErrorText = null;
        _userLocationRefreshRevision += 1;
      }
    });
  }

  void _useCurrentGenericReportLocation() {
    _updatePageState(() {
      _manualGenericReportLocation = null;
      _activeReportSelectionContext = null;
      if (_latestUserLocation == null || _userLocationErrorText != null) {
        _isUserLocationLoading = true;
        _userLocationErrorText = null;
        _userLocationRefreshRevision += 1;
      }
    });
  }

  Future<void> _openLostPetDetailsPanel(
    bool isDarkMode,
    LostPetReportRecord report,
  ) async {
    if (_hasOpenPanels && !_panelStack.last.isLostPetDetailsPanel) {
      return;
    }
    final _PanelRoute route = _buildLostPetDetailsRoute(isDarkMode, report);
    if (_hasOpenPanels && _panelStack.last.isLostPetDetailsPanel) {
      _replaceTopPanel(route);
      return;
    }
    _pushPanel(route);
  }

  Future<void> _openFoundPetDetailsPanel(
    bool isDarkMode,
    FoundPetReportRecord report,
  ) async {
    if (_hasOpenPanels && !_panelStack.last.isFoundPetDetailsPanel) {
      return;
    }
    final _PanelRoute route = _buildFoundPetDetailsRoute(isDarkMode, report);
    if (_hasOpenPanels && _panelStack.last.isFoundPetDetailsPanel) {
      _replaceTopPanel(route);
      return;
    }
    _pushPanel(route);
  }

  Future<void> _openGenericReportDetailsPanel(
    bool isDarkMode,
    GenericReportRecord report,
  ) async {
    if (_hasOpenPanels && !_panelStack.last.isGenericReportDetailsPanel) {
      return;
    }
    final _PanelRoute route = _buildGenericReportDetailsRoute(
      isDarkMode,
      report,
    );
    if (_hasOpenPanels && _panelStack.last.isGenericReportDetailsPanel) {
      _replaceTopPanel(route);
      return;
    }
    _pushPanel(route);
  }

  _PanelRoute _buildReportSelectorRoute(bool isDarkMode) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Reportar',
      anchor: PanelAnchor.bottomLeft,
      width: 290,
      height: 280,
      maxHeight: 320,
      adaptHeightToContent: true,
      expandHorizontal: false,
      expandVertical: false,
      scrollContent: false,
      isReportSelectorPanel: true,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return ReportTypeSelectorPanelContent(
          isDarkMode: isDarkMode,
          onHazardPressed: () => _openReportHazardPanel(isDarkMode),
          onLostPetPressed: () => _openLostPetReportPanel(isDarkMode),
          onFoundPetPressed: () => _openFoundPetReportPanel(isDarkMode),
          onGenericPressed: () => _openGenericReportPanel(isDarkMode),
        );
      },
    );
  }

  _PanelRoute _buildLostPetReportRoute(bool isDarkMode) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Mascota Perdida',
      anchor: PanelAnchor.bottomLeft,
      width: 340,
      mobileMaxHeightFactor: 0.5,
      desktopMaxHeightFactor: 0.5,
      adaptHeightToContent: false,
      expandHorizontal: false,
      expandVertical: false,
      scrollContent: false,
      isLostPetReportPanel: true,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return LostPetReportingPanelContent(
          isDarkMode: isDarkMode,
          currentDeviceLocation: _latestUserLocation,
          currentLocationErrorText: _userLocationErrorText,
          selectedLocation: _manualLostPetLocation,
          isSelectingOnMap:
              _activeReportSelectionContext ==
              _ReportMapSelectionContext.lostPet,
          onStartMapSelection: _startLostPetMapSelection,
          onUseCurrentLocation: _useCurrentLostPetLocation,
          onPreviewChanged: (_) {},
          onReported: _closeCurrentPanel,
        );
      },
    );
  }

  _PanelRoute _buildFoundPetReportRoute(bool isDarkMode) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Mascota Encontrada',
      anchor: PanelAnchor.bottomLeft,
      width: 340,
      mobileMaxHeightFactor: 0.5,
      desktopMaxHeightFactor: 0.5,
      adaptHeightToContent: false,
      expandHorizontal: false,
      expandVertical: false,
      scrollContent: false,
      isFoundPetReportPanel: true,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return FoundPetReportingPanelContent(
          isDarkMode: isDarkMode,
          currentDeviceLocation: _latestUserLocation,
          currentLocationErrorText: _userLocationErrorText,
          selectedLocation: _manualFoundPetLocation,
          isSelectingOnMap:
              _activeReportSelectionContext ==
              _ReportMapSelectionContext.foundPet,
          onStartMapSelection: _startFoundPetMapSelection,
          onUseCurrentLocation: _useCurrentFoundPetLocation,
          onPreviewChanged: (_) {},
          onReported: _closeCurrentPanel,
        );
      },
    );
  }

  _PanelRoute _buildGenericReportRoute(bool isDarkMode) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Otro Reporte',
      anchor: PanelAnchor.bottomLeft,
      width: 340,
      mobileMaxHeightFactor: 0.5,
      desktopMaxHeightFactor: 0.5,
      adaptHeightToContent: false,
      expandHorizontal: false,
      expandVertical: false,
      scrollContent: false,
      isGenericReportPanel: true,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return GenericReportPanelContent(
          isDarkMode: isDarkMode,
          currentDeviceLocation: _latestUserLocation,
          currentLocationErrorText: _userLocationErrorText,
          selectedLocation: _manualGenericReportLocation,
          isSelectingOnMap:
              _activeReportSelectionContext ==
              _ReportMapSelectionContext.generic,
          onStartMapSelection: _startGenericReportMapSelection,
          onUseCurrentLocation: _useCurrentGenericReportLocation,
          onPreviewChanged: (_) {},
          onReported: _closeCurrentPanel,
        );
      },
    );
  }

  _PanelRoute _buildLostPetDetailsRoute(
    bool isDarkMode,
    LostPetReportRecord report,
  ) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Mascota Perdida',
      anchor: PanelAnchor.bottomLeft,
      width: 380,
      height: 420,
      maxHeight: 520,
      adaptHeightToContent: false,
      expandHorizontal: false,
      expandVertical: false,
      scrollContent: false,
      isLostPetDetailsPanel: true,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return LostPetDetailsPanelContent(
          isDarkMode: isDarkMode,
          report: report,
        );
      },
    );
  }

  _PanelRoute _buildFoundPetDetailsRoute(
    bool isDarkMode,
    FoundPetReportRecord report,
  ) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Mascota Encontrada',
      anchor: PanelAnchor.bottomLeft,
      width: 380,
      height: 420,
      maxHeight: 520,
      adaptHeightToContent: false,
      expandHorizontal: false,
      expandVertical: false,
      scrollContent: false,
      isFoundPetDetailsPanel: true,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return FoundPetDetailsPanelContent(
          isDarkMode: isDarkMode,
          report: report,
        );
      },
    );
  }

  _PanelRoute _buildGenericReportDetailsRoute(
    bool isDarkMode,
    GenericReportRecord report,
  ) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Otro Reporte',
      anchor: PanelAnchor.bottomLeft,
      width: 380,
      height: 420,
      maxHeight: 520,
      adaptHeightToContent: false,
      expandHorizontal: false,
      expandVertical: false,
      scrollContent: false,
      isGenericReportDetailsPanel: true,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return GenericReportDetailsPanelContent(
          isDarkMode: isDarkMode,
          report: report,
        );
      },
    );
  }
}
