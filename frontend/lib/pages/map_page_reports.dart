part of 'map_page.dart';

extension _MapPageReportsState on _MapPageState {
  void _showProximityAlert(_ProximityAlertTarget target) {
    _updatePageState(() {
      _activeProximityAlert = target;
    });

    if (!_isAudioFeedbackEnabled) {
      return;
    }

    unawaited(
      ref
          .read(audioFeedbackServiceProvider)
          .playDangerAlertWithSpeech(
            NavigationAudioMessageBuilder.buildDangerMessage(),
          ),
    );
  }

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

  PetRecord? _findPetForFoundReport(
    FoundPetReportRecord report,
    List<PetRecord> pets,
    List<LostPetReportRecord> lostReports,
  ) {
    for (final PetRecord pet in pets) {
      if (pet.localUuid == report.petLocalUuid ||
          (report.petId != null && pet.id == report.petId)) {
        return pet;
      }
    }

    final LostPetReportRecord? matchedLostPetReport =
        _findLostReportForFoundReport(report, lostReports);
    if (matchedLostPetReport == null) {
      return null;
    }

    for (final PetRecord pet in pets) {
      if (pet.localUuid == matchedLostPetReport.petLocalUuid) {
        return pet;
      }
    }

    return null;
  }

  LostPetReportRecord? _findLostReportForFoundReport(
    FoundPetReportRecord report,
    List<LostPetReportRecord> lostReports,
  ) {
    for (final LostPetReportRecord lostReport in lostReports) {
      if (lostReport.petLocalUuid == report.petLocalUuid) {
        return lostReport;
      }
      if (report.matchedLostPetReportId != null &&
          (lostReport.id == report.matchedLostPetReportId ||
              lostReport.remoteId ==
                  report.matchedLostPetReportId.toString())) {
        return lostReport;
      }
    }

    return null;
  }

  bool get _hasProximityAudioTargets {
    if (_visibleHazardCircles.isNotEmpty) {
      return true;
    }
    for (final GenericReportRecord report in _visibleGenericReports) {
      if (report.impactRadiusMeters > 0) {
        return true;
      }
    }
    return false;
  }

  void _openReportTypeSelectorPanel(bool isDarkMode) {
    if (_hasOpenPanels &&
        !_panelStack.last.isTripPanel &&
        !_panelStack.last.isTripStartPanel) {
      return;
    }

    _pushPanel(_buildReportSelectorRoute(isDarkMode));
  }

  void _closeReportingFlowAfterSubmit() {
    _updatePageState(() {
      _isSelectingHazardLocationOnMap = false;
      _activeReportSelectionContext = null;
      _manualHazardLocation = null;
      _hazardDraftPreview = null;
      _isReportHazardPanelMinimized = false;
      _manualLostPetLocation = null;
      _manualFoundPetLocation = null;
      _manualGenericReportLocation = null;
      _genericReportDraftPreview = null;
      _panelStack.removeWhere(
        (_PanelRoute route) =>
            route.isReportSelectorPanel ||
            route.isReportHazardPanel ||
            route.isLostPetReportPanel ||
            route.isLostPetPetSelectionPanel ||
            route.isFoundPetReportPanel ||
            route.isLostPetReportsListPanel ||
            route.isFoundPetReportsListPanel ||
            route.isGenericReportPanel,
      );
      _selectedLostPetForReport = null;
      _selectedLostReportForFoundReport = null;
    });
  }

  void _openLostPetReportPanel(bool isDarkMode) {
    _updatePageState(() {
      _manualLostPetLocation = null;
      _activeReportSelectionContext = null;
      _selectedLostPetForReport = null;
    });
    _replaceOrPushReportPanel(_buildLostPetReportRoute(isDarkMode));
  }

  void _openFoundPetReportPanel(bool isDarkMode) {
    _updatePageState(() {
      _manualFoundPetLocation = null;
      _activeReportSelectionContext = null;
      _selectedLostReportForFoundReport = null;
    });
    _replaceOrPushReportPanel(_buildFoundPetReportRoute(isDarkMode));
  }

  void _focusReportLocation(LatLng location) {
    _updatePageState(() {
      _reportFocusTarget = location;
      _reportFocusRevision += 1;
    });
  }

  void _openLostPetReportsListPanel(bool isDarkMode) {
    _pushPanel(_buildLostPetReportsListRoute(isDarkMode));
  }

  void _openLostPetPetSelectionPanel(bool isDarkMode) {
    ref.read(petsControllerProvider.notifier).reload();
    _syncAndReloadData();
    _pushPanel(_buildLostPetPetSelectionRoute(isDarkMode));
  }

  void _selectLostPetForReport(PetRecord pet) {
    _updatePageState(() {
      _selectedLostPetForReport = pet;
      _activeReportSelectionContext = null;
      if (_hasOpenPanels && _panelStack.last.isLostPetPetSelectionPanel) {
        _panelStack.removeLast();
      }
    });
  }

  void _openFoundPetReportsListPanel(bool isDarkMode) {
    _pushPanel(_buildFoundPetReportsListRoute(isDarkMode));
  }

  void _openGenericReportPanel(bool isDarkMode) {
    _updatePageState(() {
      _manualGenericReportLocation = null;
      _activeReportSelectionContext = null;
      _genericReportDraftPreview = const GenericReportDraftPreview(
        location: null,
        riskLevelCode: 'undefined',
        impactRadiusMeters: 0,
      );
    });
    _replaceOrPushReportPanel(_buildGenericReportRoute(isDarkMode));
  }

  void _updateGenericReportDraftPreview(GenericReportDraftPreview preview) {
    final GenericReportDraftPreview? currentPreview =
        _genericReportDraftPreview;
    if (currentPreview != null &&
        currentPreview.impactRadiusMeters == preview.impactRadiusMeters &&
        currentPreview.riskLevelCode == preview.riskLevelCode) {
      return;
    }

    _updatePageState(() {
      _genericReportDraftPreview = GenericReportDraftPreview(
        location: currentPreview?.location,
        riskLevelCode: preview.riskLevelCode,
        impactRadiusMeters: preview.impactRadiusMeters,
      );
    });
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
    _updatePageState(() {
      _selectedHazard = null;
      _selectedLostPetReport = report;
      _selectedFoundPetReport = null;
      _selectedGenericReport = null;
    });
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
    _updatePageState(() {
      _selectedHazard = null;
      _selectedLostPetReport = null;
      _selectedFoundPetReport = report;
      _selectedGenericReport = null;
    });
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
    _updatePageState(() {
      _selectedHazard = null;
      _selectedLostPetReport = null;
      _selectedFoundPetReport = null;
      _selectedGenericReport = report;
    });
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
          selectedPet: _selectedLostPetForReport,
          isSelectingOnMap:
              _activeReportSelectionContext ==
              _ReportMapSelectionContext.lostPet,
          onStartMapSelection: _startLostPetMapSelection,
          onUseCurrentLocation: _useCurrentLostPetLocation,
          onPreviewChanged: (_) {},
          onSelectPetPressed: () => _openLostPetPetSelectionPanel(isDarkMode),
          onViewFoundReportsPressed: () =>
              _openFoundPetReportsListPanel(isDarkMode),
          onReported: _closeReportingFlowAfterSubmit,
        );
      },
    );
  }

  _PanelRoute _buildLostPetPetSelectionRoute(bool isDarkMode) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Seleccionar Mascota',
      anchor: PanelAnchor.topLeft,
      width: 380,
      height: 620,
      maxHeight: 620,
      adaptHeightToContent: false,
      expandHorizontal: false,
      expandVertical: true,
      scrollContent: false,
      isLostPetPetSelectionPanel: true,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        return ManagePetsPanelContent(
          isDarkMode: isDarkMode,
          selectionMode: true,
          selectedPetId: _selectedLostPetForReport?.id,
          onAddPetPressed: () => _openAddPetPanel(isDarkMode),
          onViewPetPressed: (PetRecord pet) => _selectLostPetForReport(pet),
          onEditPetPressed: (PetRecord pet) =>
              _openEditPetPanel(isDarkMode, pet),
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
        final List<PetRecord> pets =
            ref.watch(petsControllerProvider).asData?.value ??
            const <PetRecord>[];
        final LostPetReportRecord? selectedLostPetReport =
            _selectedLostReportForFoundReport;
        PetRecord? selectedLostPet;
        if (selectedLostPetReport != null) {
          for (final PetRecord pet in pets) {
            if (pet.localUuid == selectedLostPetReport.petLocalUuid) {
              selectedLostPet = pet;
              break;
            }
          }
        }

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
          selectedLostPetReport: selectedLostPetReport,
          selectedLostPet: selectedLostPet,
          onViewLostReportsPressed: () =>
              _openLostPetReportsListPanel(isDarkMode),
          onReported: _closeReportingFlowAfterSubmit,
        );
      },
    );
  }

  _PanelRoute _buildLostPetReportsListRoute(bool isDarkMode) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Mascotas perdidas',
      anchor: PanelAnchor.topLeft,
      width: 380,
      height: 620,
      maxHeight: 620,
      adaptHeightToContent: false,
      expandHorizontal: false,
      expandVertical: true,
      scrollContent: false,
      isLostPetReportsListPanel: true,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        final List<LostPetReportRecord> reports =
            ref.watch(lostPetReportsControllerProvider).asData?.value ??
            const <LostPetReportRecord>[];
        final List<PetRecord> pets =
            ref.watch(petsControllerProvider).asData?.value ??
            const <PetRecord>[];
        return LostPetReportsListPanelContent(
          isDarkMode: isDarkMode,
          reports: reports,
          pets: pets,
          onSelectReport: (LostPetReportRecord report) {
            _updatePageState(() {
              _selectedLostReportForFoundReport = report;
              if (_hasOpenPanels) {
                _panelStack.removeLast();
              }
            });
          },
          onGoToLocation: _focusReportLocation,
        );
      },
    );
  }

  _PanelRoute _buildFoundPetReportsListRoute(bool isDarkMode) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Mascotas encontradas',
      anchor: PanelAnchor.topLeft,
      width: 380,
      height: 620,
      maxHeight: 620,
      adaptHeightToContent: false,
      expandHorizontal: false,
      expandVertical: true,
      scrollContent: false,
      isFoundPetReportsListPanel: true,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: (BuildContext context) {
        final List<FoundPetReportRecord> reports =
            ref.watch(foundPetReportsControllerProvider).asData?.value ??
            const <FoundPetReportRecord>[];
        final List<PetRecord> pets =
            ref.watch(petsControllerProvider).asData?.value ??
            const <PetRecord>[];
        final List<LostPetReportRecord> lostReports =
            ref.watch(lostPetReportsControllerProvider).asData?.value ??
            const <LostPetReportRecord>[];
        return FoundPetReportsListPanelContent(
          isDarkMode: isDarkMode,
          reports: reports,
          pets: pets,
          lostPetReports: lostReports,
          onGoToLocation: _focusReportLocation,
        );
      },
    );
  }

  _PanelRoute _buildGenericReportRoute(bool isDarkMode) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: 'Reporte',
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
          onPreviewChanged: _updateGenericReportDraftPreview,
          onReported: _closeReportingFlowAfterSubmit,
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
          onViewComments: () => _openLostPetCommentsPanel(isDarkMode, report),
          debugDeleteLabel: kIsWeb && kDebugMode
              ? 'Borrar mascota perdida'
              : null,
          onDebugDelete: kIsWeb && kDebugMode
              ? _confirmAndDeleteSelectedDebugItem
              : null,
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
        final List<PetRecord> pets =
            ref.watch(petsControllerProvider).asData?.value ??
            const <PetRecord>[];
        final List<LostPetReportRecord> lostReports =
            ref.watch(lostPetReportsControllerProvider).asData?.value ??
            const <LostPetReportRecord>[];
        final PetRecord? matchedPet = _findPetForFoundReport(
          report,
          pets,
          lostReports,
        );
        final LostPetReportRecord? matchedLostPetReport =
            _findLostReportForFoundReport(report, lostReports);

        return FoundPetDetailsPanelContent(
          isDarkMode: isDarkMode,
          report: report,
          pet: matchedPet,
          matchedLostPetReport: matchedLostPetReport,
          onViewComments: () => _openFoundPetCommentsPanel(isDarkMode, report),
          debugDeleteLabel: kIsWeb && kDebugMode
              ? 'Borrar mascota encontrada'
              : null,
          onDebugDelete: kIsWeb && kDebugMode
              ? _confirmAndDeleteSelectedDebugItem
              : null,
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
      title: 'Reporte',
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
          onViewComments: () =>
              _openGenericReportCommentsPanel(isDarkMode, report),
          debugDeleteLabel: kIsWeb && kDebugMode ? 'Borrar reporte' : null,
          onDebugDelete: kIsWeb && kDebugMode
              ? _confirmAndDeleteSelectedDebugItem
              : null,
        );
      },
    );
  }

  void _openLostPetCommentsPanel(bool isDarkMode, LostPetReportRecord report) {
    _pushPanel(
      _buildReportCommentsRoute(
        isDarkMode: isDarkMode,
        reportId: report.id,
        subjectType: ReportCommentSubjectType.lostPet,
      ),
    );
  }

  void _openFoundPetCommentsPanel(
    bool isDarkMode,
    FoundPetReportRecord report,
  ) {
    _pushPanel(
      _buildReportCommentsRoute(
        isDarkMode: isDarkMode,
        reportId: report.id,
        subjectType: ReportCommentSubjectType.foundPet,
      ),
    );
  }

  void _openGenericReportCommentsPanel(
    bool isDarkMode,
    GenericReportRecord report,
  ) {
    _pushPanel(
      _buildReportCommentsRoute(
        isDarkMode: isDarkMode,
        reportId: report.id,
        subjectType: ReportCommentSubjectType.generic,
      ),
    );
  }

  _PanelRoute _buildReportCommentsRoute({
    required bool isDarkMode,
    required int reportId,
    required ReportCommentSubjectType subjectType,
  }) {
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
        return ReportCommentsPanelContent(
          isDarkMode: isDarkMode,
          subjectType: subjectType,
          reportId: reportId,
        );
      },
    );
  }

  Widget _buildProximityAlertOverlay(bool isDarkMode) {
    final _ProximityAlertTarget? alert = _activeProximityAlert;
    if (alert == null) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0x4D000000),
        child: _ProximityAlertCard(
          isDarkMode: isDarkMode,
          onAcknowledge: _acknowledgeProximityAlert,
          onOpenComments: _openCommentsFromProximityAlert,
        ),
      ),
    );
  }

  void _evaluateProximityAlerts(LatLng location) {
    final List<_ProximityAlertTarget> activeTargets =
        _collectProximityTargets(location)..sort(
          (_ProximityAlertTarget a, _ProximityAlertTarget b) =>
              a.distanceMeters.compareTo(b.distanceMeters),
        );

    final Set<String> nextZoneKeys = activeTargets
        .map((_ProximityAlertTarget target) => target.zoneKey)
        .toSet();
    final Set<String> exitedZoneKeys = _currentProximityZoneKeys.difference(
      nextZoneKeys,
    );
    for (final String zoneKey in exitedZoneKeys) {
      _acknowledgedProximityZoneKeys.remove(zoneKey);
    }
    _currentProximityZoneKeys = nextZoneKeys;

    final _ProximityAlertTarget? activeAlert = _activeProximityAlert;
    if (activeAlert != null && !nextZoneKeys.contains(activeAlert.zoneKey)) {
      _updatePageState(() {
        _activeProximityAlert = null;
      });
    }

    if (_activeProximityAlert != null) {
      return;
    }

    for (final _ProximityAlertTarget target in activeTargets) {
      if (_acknowledgedProximityZoneKeys.contains(target.zoneKey)) {
        continue;
      }

      _showProximityAlert(target);
      return;
    }
  }

  _ProximityAlertTarget? _currentProximityAlertTarget() {
    final _ProximityAlertTarget? active = _activeProximityAlert;
    if (active == null) {
      return null;
    }

    for (final _ProximityAlertTarget target
        in _buildCurrentProximityTargets()) {
      if (target.zoneKey == active.zoneKey) {
        return target;
      }
    }

    return active;
  }

  List<_ProximityAlertTarget> _buildCurrentProximityTargets() {
    final LatLng? location = _latestUserLocation;
    if (location == null) {
      return const <_ProximityAlertTarget>[];
    }

    return _collectProximityTargets(location);
  }

  List<_ProximityAlertTarget> _collectProximityTargets(LatLng location) {
    final List<_ProximityAlertTarget> targets = <_ProximityAlertTarget>[];

    for (final HazardReportRecord report in _visibleHazardCircles) {
      final LatLng center = LatLng(
        report.incidentLatitude,
        report.incidentLongitude,
      );
      final double distanceMeters = _distanceCalculator.distance(
        location,
        center,
      );
      if (distanceMeters > report.impactRadiusMeters) {
        continue;
      }
      targets.add(
        _ProximityAlertTarget(
          zoneKey: 'hazard:${report.remoteId ?? report.localUuid}',
          subjectType: ReportCommentSubjectType.hazard,
          reportId: report.id,
          distanceMeters: distanceMeters,
        ),
      );
    }

    for (final GenericReportRecord report in _visibleGenericReports) {
      if (report.impactRadiusMeters <= 0) {
        continue;
      }
      final LatLng center = LatLng(report.latitude, report.longitude);
      final double distanceMeters = _distanceCalculator.distance(
        location,
        center,
      );
      if (distanceMeters > report.impactRadiusMeters) {
        continue;
      }
      targets.add(
        _ProximityAlertTarget(
          zoneKey: 'generic:${report.remoteId ?? report.localUuid}',
          subjectType: ReportCommentSubjectType.generic,
          reportId: report.id,
          distanceMeters: distanceMeters,
        ),
      );
    }

    return targets;
  }

  void _acknowledgeProximityAlert() {
    final _ProximityAlertTarget? alert = _activeProximityAlert;
    if (alert == null) {
      return;
    }

    _updatePageState(() {
      _acknowledgedProximityZoneKeys.add(alert.zoneKey);
      _activeProximityAlert = null;
    });

    final LatLng? location = _latestUserLocation;
    if (location != null) {
      _evaluateProximityAlerts(location);
    }
  }

  void _openCommentsFromProximityAlert() {
    final _ProximityAlertTarget? alert = _currentProximityAlertTarget();
    if (alert == null) {
      return;
    }

    _updatePageState(() {
      _acknowledgedProximityZoneKeys.add(alert.zoneKey);
      _activeProximityAlert = null;
    });

    final bool isDarkMode = ref.read(themeModeProvider);
    switch (alert.subjectType) {
      case ReportCommentSubjectType.hazard:
        HazardReportRecord? hazard;
        for (final HazardReportRecord item in _visibleHazardCircles) {
          if (item.id == alert.reportId) {
            hazard = item;
            break;
          }
        }
        if (hazard != null) {
          _openHazardCommentsPanel(isDarkMode, hazard);
        }
        break;
      case ReportCommentSubjectType.generic:
        GenericReportRecord? report;
        for (final GenericReportRecord item in _visibleGenericReports) {
          if (item.id == alert.reportId) {
            report = item;
            break;
          }
        }
        if (report != null) {
          _openGenericReportCommentsPanel(isDarkMode, report);
        }
        break;
      case ReportCommentSubjectType.lostPet:
      case ReportCommentSubjectType.foundPet:
        break;
    }
  }

  Future<void> _confirmAndDeleteSelectedDebugItem() async {
    if (!_isDebugDetailPanelOpen) {
      return;
    }

    final String label = _debugDeleteLabel ?? 'Borrar registro';
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
            label,
            style: TextStyle(
              color: AppPalette.dialogTitle(isDarkMode),
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Esta accion es solo para debug. ¿Deseas continuar?',
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

    try {
      if (_hasOpenPanels && _panelStack.last.isHazardDetailsPanel) {
        final HazardReportRecord? hazard = _selectedHazard;
        if (hazard == null) {
          return;
        }
        await ref
            .read(hazardReportsControllerProvider.notifier)
            .deleteHazardReport(hazardId: hazard.id, remoteId: hazard.remoteId);
      } else if (_hasOpenPanels && _panelStack.last.isLostPetDetailsPanel) {
        final LostPetReportRecord? report = _selectedLostPetReport;
        if (report == null) {
          return;
        }
        await ref
            .read(lostPetReportsControllerProvider.notifier)
            .deleteLostPetReport(
              reportId: report.id,
              remoteId: report.remoteId,
            );
      } else if (_hasOpenPanels && _panelStack.last.isFoundPetDetailsPanel) {
        final FoundPetReportRecord? report = _selectedFoundPetReport;
        if (report == null) {
          return;
        }
        await ref
            .read(foundPetReportsControllerProvider.notifier)
            .deleteFoundPetReport(
              reportId: report.id,
              remoteId: report.remoteId,
            );
      } else if (_hasOpenPanels &&
          _panelStack.last.isGenericReportDetailsPanel) {
        final GenericReportRecord? report = _selectedGenericReport;
        if (report == null) {
          return;
        }
        await ref
            .read(genericReportsControllerProvider.notifier)
            .deleteGenericReport(
              reportId: report.id,
              remoteId: report.remoteId,
            );
      } else {
        return;
      }

      if (!mounted) {
        return;
      }

      _closeCurrentPanel();
      _updatePageState(() {
        _activeProximityAlert = null;
      });
      _analyzeRouteForHazards();
      if (_latestUserLocation != null) {
        _evaluateProximityAlerts(_latestUserLocation!);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro borrado en modo debug.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }
}
