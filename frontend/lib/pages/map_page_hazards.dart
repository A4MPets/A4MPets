// ignore_for_file: invalid_use_of_protected_member

part of 'map_page.dart';

extension _MapPageHazardsState on _MapPageState {
  void _openReportHazardPanel(bool isDarkMode) {
    if (_hasOpenPanels &&
        !_panelStack.last.isTripPanel &&
        !_panelStack.last.isTripStartPanel) {
      return;
    }
    setState(() {
      _isSelectingHazardLocationOnMap = false;
      _manualHazardLocation = null;
      _isReportHazardPanelMinimized = false;
      _hazardDraftPreview = const HazardDraftPreview(
        location: null,
        impactRadiusMeters: 10,
        riskLevelCode: 'undefined',
        isSelectingOnMap: false,
      );
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
          _manualHazardLocation = null;
          _isReportHazardPanelMinimized = false;
          _hazardDraftPreview = null;
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

  void _startHazardMapSelection() {
    setState(() {
      _isSelectingHazardLocationOnMap = true;
      _isReportHazardPanelMinimized = true;
    });
  }

  void _toggleReportHazardPanelMinimized() {
    setState(() {
      _isReportHazardPanelMinimized = !_isReportHazardPanelMinimized;
    });
  }

  void _useCurrentHazardLocation() {
    setState(() {
      _isSelectingHazardLocationOnMap = false;
      _manualHazardLocation = null;
      _isReportHazardPanelMinimized = false;
      if (_latestUserLocation == null || _userLocationErrorText != null) {
        _isUserLocationLoading = true;
        _userLocationErrorText = null;
        _userLocationRefreshRevision += 1;
      }
    });
  }

  void _handleUserLocationStatusChanged(bool isLoading, String? errorText) {
    if (_isUserLocationLoading == isLoading &&
        _userLocationErrorText == errorText) {
      return;
    }

    setState(() {
      _isUserLocationLoading = isLoading;
      _userLocationErrorText = errorText;
    });
  }

  void _updateHazardDraftPreview(HazardDraftPreview preview) {
    final HazardDraftPreview? currentPreview = _hazardDraftPreview;
    if (currentPreview != null &&
        currentPreview.impactRadiusMeters == preview.impactRadiusMeters &&
        currentPreview.riskLevelCode == preview.riskLevelCode) {
      return;
    }

    setState(() {
      _hazardDraftPreview = HazardDraftPreview(
        location: currentPreview?.location,
        impactRadiusMeters: preview.impactRadiusMeters,
        riskLevelCode: preview.riskLevelCode,
        isSelectingOnMap: currentPreview?.isSelectingOnMap ?? false,
      );
    });
  }

  _PanelRoute _buildReportHazardRoute(bool isDarkMode) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Reportar Peligro',
      anchor: PanelAnchor.bottomLeft,
      width: 340,
      mobileMaxHeightFactor: 0.5,
      desktopMaxHeightFactor: 0.5,
      adaptHeightToContent: false,
      expandHorizontal: false,
      expandVertical: false,
      scrollContent: false,
      isReportHazardPanel: true,
      canMinimize: true,
      isMinimized: _isReportHazardPanelMinimized,
      minimizedHeight: 72,
      onToggleMinimize: _toggleReportHazardPanelMinimized,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return ReportHazardPanelContent(
          isDarkMode: isDarkMode,
          currentDeviceLocation: _latestUserLocation,
          isLoadingCurrentLocation: _isUserLocationLoading,
          currentLocationErrorText: _userLocationErrorText,
          selectedHazardLocation: _manualHazardLocation,
          isSelectingHazardLocationOnMap: _isSelectingHazardLocationOnMap,
          onStartMapSelection: _startHazardMapSelection,
          onUseCurrentLocation: _useCurrentHazardLocation,
          onPreviewChanged: _updateHazardDraftPreview,
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
      expandVertical: true,
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

  void _analyzeRouteForHazards() {
    if (_draftRoutePolyline.length < 2) {
      _hazardColoredRouteSegments = <dynamic>[];
      return;
    }

    final List<HazardReportRecord> visibleHazards = _filteredHazards;
    final List<ColoredRouteSegment> segments =
        RouteHazardVisualizerService.analyzeRouteHazards(
          routePolyline: _draftRoutePolyline,
          hazards: visibleHazards,
        );

    _hazardColoredRouteSegments = segments;
  }

  List<HazardReportRecord> get _filteredHazards {
    return ref
        .read(hazardReportsControllerProvider)
        .whenData((hazards) {
          return hazards.where((HazardReportRecord h) {
            if (h.riskLevelCode == 'low' && !_showLowRiskHazardCircles) {
              return false;
            }
            if (h.riskLevelCode == 'medium' && !_showMediumRiskHazardCircles) {
              return false;
            }
            if (h.riskLevelCode == 'high' && !_showHighRiskHazardCircles) {
              return false;
            }
            if (h.riskLevelCode == 'undefined' && !_showHighRiskHazardCircles) {
              return false;
            }
            return true;
          }).toList();
        })
        .maybeWhen(
          data: (hazards) => hazards,
          orElse: () => <HazardReportRecord>[],
        );
  }
}
