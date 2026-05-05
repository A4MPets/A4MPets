part of 'map_page.dart';

extension _MapPageHazardsState on _MapPageState {
  double _hazardFocusZoomFor(HazardReportRecord hazard) {
    final int radiusMeters = hazard.impactRadiusMeters;
    if (radiusMeters <= 5) {
      return 18.4;
    }
    if (radiusMeters <= 10) {
      return 18.0;
    }
    if (radiusMeters <= 25) {
      return 17.5;
    }
    if (radiusMeters <= 50) {
      return 17.0;
    }
    if (radiusMeters <= 100) {
      return 16.4;
    }
    if (radiusMeters <= 300) {
      return 15.8;
    }
    return 15.2;
  }

  void _openReportHazardPanel(bool isDarkMode) {
    if (_hasOpenPanels &&
        !_panelStack.last.isTripPanel &&
        !_panelStack.last.isTripStartPanel &&
        !_panelStack.last.isReportSelectorPanel) {
      return;
    }
    ref.read(hazardReportsControllerProvider.notifier).reload();
    _updatePageState(() {
      _isSelectingHazardLocationOnMap = false;
      _activeReportSelectionContext = null;
      _manualHazardLocation = null;
      _isReportHazardPanelMinimized = false;
      _hazardDraftPreview = const HazardDraftPreview(
        location: null,
        impactRadiusMeters: 10,
        riskLevelCode: 'undefined',
        isSelectingOnMap: false,
      );
    });
    _replaceOrPushReportPanel(_buildReportHazardRoute(isDarkMode));
  }

  void _openHazardLayersSettingsPanel(bool isDarkMode) {
    if (_hasOpenPanels) {
      return;
    }

    _reloadReportData();
    _pushPanel(_buildHazardLayersSettingsRoute());
  }

  Future<void> _openHazardDetailsPanel(
    bool isDarkMode,
    HazardReportRecord hazard,
  ) async {
    ref.read(hazardReportsControllerProvider.notifier).reload();
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

      _updatePageState(() {
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

    _updatePageState(() {
      _selectedHazard = hazard;
      _selectedLostPetReport = null;
      _selectedFoundPetReport = null;
      _selectedGenericReport = null;
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
    _updatePageState(() {
      _isSelectingHazardLocationOnMap = true;
      _activeReportSelectionContext = _ReportMapSelectionContext.hazard;
      _isReportHazardPanelMinimized = true;
    });
  }

  void _toggleReportHazardPanelMinimized() {
    _updatePageState(() {
      _isReportHazardPanelMinimized = !_isReportHazardPanelMinimized;
    });
  }

  void _useCurrentHazardLocation() {
    _updatePageState(() {
      _isSelectingHazardLocationOnMap = false;
      _activeReportSelectionContext = null;
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

    _updatePageState(() {
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

    _updatePageState(() {
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
      mobileMaxHeightFactor: 0.72,
      desktopMaxHeightFactor: 0.48,
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
          onReported: _closeReportingFlowAfterSubmit,
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
      height: 420,
      maxHeight: 500,
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
            final bool audioFeedbackEnabled = ref.watch(
              audioFeedbackEnabledProvider,
            );

            return HazardLayersPanelContent(
              isDarkMode: currentDarkMode,
              isDarkModeEnabled: currentDarkMode,
              showLowRiskCircles: _showLowRiskHazardCircles,
              showMediumRiskCircles: _showMediumRiskHazardCircles,
              showHighRiskCircles: _showHighRiskHazardCircles,
              showLostPetReports: _showLostPetReports,
              showFoundPetReports: _showFoundPetReports,
              showGenericReports: _showGenericReports,
              audioFeedbackEnabled: audioFeedbackEnabled,
              onToggleDarkMode: (bool value) {
                ref.read(themeModeProvider.notifier).setThemeMode(value);
              },
              onToggleAudioFeedback: (bool value) {
                ref
                    .read(audioFeedbackEnabledProvider.notifier)
                    .setEnabled(value);
              },
              onToggleLowRisk: (bool value) {
                _updatePageState(() {
                  _showLowRiskHazardCircles = value;
                });
              },
              onToggleMediumRisk: (bool value) {
                _updatePageState(() {
                  _showMediumRiskHazardCircles = value;
                });
              },
              onToggleHighRisk: (bool value) {
                _updatePageState(() {
                  _showHighRiskHazardCircles = value;
                });
              },
              onToggleLostPetReports: (bool value) {
                _updatePageState(() {
                  _showLostPetReports = value;
                });
              },
              onToggleFoundPetReports: (bool value) {
                _updatePageState(() {
                  _showFoundPetReports = value;
                });
              },
              onToggleGenericReports: (bool value) {
                _updatePageState(() {
                  _showGenericReports = value;
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
      title: 'Detalles del Peligro',
      anchor: PanelAnchor.bottomLeft,
      width: 380,
      height: 400,
      maxHeight: 500,
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
          debugDeleteLabel: kIsWeb && kDebugMode ? 'Borrar peligro' : null,
          onDebugDelete: kIsWeb && kDebugMode
              ? _confirmAndDeleteSelectedDebugItem
              : null,
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
          routeWaypoints: _routePolylineWaypoints,
          segmentColors: AppPalette.routeSegmentBlueVariants,
          hazards: visibleHazards,
          genericReports: _visibleGenericReports,
          hazardRiskFilters: _selectedTripHazardRiskFilters.toList(
            growable: false,
          ),
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
