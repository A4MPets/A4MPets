part of 'map_page.dart';

extension _MapPageReportsState on _MapPageState {
  void _showProximityAlert(_ProximityAlertTarget target) {
    _updatePageState(() {
      _activeProximityAlert = target;
    });

    if (!_isAudioFeedbackEnabled) return;

    unawaited(
      ref
          .read(audioFeedbackServiceProvider)
          .playDangerAlertWithSpeech(NavigationAudioMessageBuilder.buildDangerMessage()),
    );
  }

  List<LostPetReportRecord> get _visibleLostPetReports {
    return _showLostPetReports
        ? _reportsOrEmpty(ref.watch(lostPetReportsControllerProvider))
        : const <LostPetReportRecord>[];
  }

  List<FoundPetReportRecord> get _visibleFoundPetReports {
    return _showFoundPetReports
        ? _reportsOrEmpty(ref.watch(foundPetReportsControllerProvider))
        : const <FoundPetReportRecord>[];
  }

  List<GenericReportRecord> get _visibleGenericReports {
    return _showGenericReports
        ? _reportsOrEmpty(ref.watch(genericReportsControllerProvider))
        : const <GenericReportRecord>[];
  }

  List<T> _reportsOrEmpty<T>(AsyncValue<List<T>> reports) {
    return reports.maybeWhen(data: (List<T> value) => value, orElse: () => []);
  }

  bool get _isAuthenticated {
    return ref
        .watch(localUserProfileProvider)
        .maybeWhen(data: (LocalUserProfile profile) => profile.isAuthenticated, orElse: () => false);
  }

  PetRecord? _findPetForLostReport(LostPetReportRecord report, List<PetRecord> pets) {
    return _findPetByReference(pets, petId: report.petId, localUuid: report.petLocalUuid);
  }

  PetRecord? _findPetByReference(List<PetRecord> pets, {int? petId, String? localUuid}) {
    for (final PetRecord pet in pets) {
      if ((petId != null && pet.id == petId) || _localUuidMatches(pet.localUuid, localUuid ?? '')) {
        return pet;
      }
    }
    return null;
  }

  bool _localUuidMatches(String itemUuid, String reportUuid) {
    return reportUuid.isNotEmpty && itemUuid == reportUuid;
  }

  PetRecord? _findPetForFoundReport(
    FoundPetReportRecord report,
    List<PetRecord> pets,
    List<LostPetReportRecord> lostReports,
  ) {
    final PetRecord? directMatch = _findPetByReference(pets, petId: report.petId, localUuid: report.petLocalUuid);
    if (directMatch != null) return directMatch;

    final LostPetReportRecord? matchedLostPetReport = _findLostReportForFoundReport(report, lostReports);
    return matchedLostPetReport == null ? null : _findPetForLostReport(matchedLostPetReport, pets);
  }

  LostPetReportRecord? _findLostReportForFoundReport(
    FoundPetReportRecord report,
    List<LostPetReportRecord> lostReports,
  ) {
    for (final LostPetReportRecord lostReport in lostReports) {
      if ((report.petLocalUuid ?? '').isNotEmpty && lostReport.petLocalUuid == report.petLocalUuid) {
        return lostReport;
      }
      if (report.petId != null && lostReport.petId == report.petId) return lostReport;
      if (report.matchedLostPetReportId != null &&
          (lostReport.id == report.matchedLostPetReportId ||
              lostReport.remoteId == report.matchedLostPetReportId.toString())) {
        return lostReport;
      }
    }

    return null;
  }

  bool get _hasProximityAudioTargets {
    if (_visibleHazardCircles.isNotEmpty) return true;
    for (final GenericReportRecord report in _visibleGenericReports) {
      if (report.impactRadiusMeters > 0) return true;
    }
    return false;
  }

  void _openReportTypeSelectorPanel(bool isDarkMode) {
    if (_hasOpenPanels && !_panelStack.last.isTripPanel && !_panelStack.last.isTripStartPanel) {
      return;
    }

    _reloadReportData();
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
      _panelStack.removeWhere((_PanelRoute route) => route.isReportFlowPanel);
      _selectedLostPetForReport = null;
      _selectedLostReportForFoundReport = null;
    });
  }

  void _openLostPetReportPanel(bool isDarkMode) {
    ref.read(myPetsControllerProvider.notifier).reload();
    ref.read(lostPetReportsControllerProvider.notifier).reload();
    ref.read(foundPetReportsControllerProvider.notifier).reload();
    _updatePageState(() {
      _manualLostPetLocation = null;
      _activeReportSelectionContext = null;
      _selectedLostPetForReport = null;
    });
    _pushPanel(_buildLostPetReportRoute(isDarkMode));
  }

  void _openFoundPetReportPanel(bool isDarkMode) {
    ref.read(petsControllerProvider.notifier).reload();
    ref.read(lostPetReportsControllerProvider.notifier).reload();
    ref.read(foundPetReportsControllerProvider.notifier).reload();
    _updatePageState(() {
      _manualFoundPetLocation = null;
      _activeReportSelectionContext = null;
      _selectedLostReportForFoundReport = null;
    });
    _pushPanel(_buildFoundPetReportRoute(isDarkMode));
  }

  void _focusReportLocation(LatLng location) {
    _updatePageState(() {
      _reportFocusTarget = location;
      _reportFocusRevision += 1;
    });
  }

  void _openLostPetReportsListPanel(bool isDarkMode) {
    ref.read(petsControllerProvider.notifier).reload();
    ref.read(lostPetReportsControllerProvider.notifier).reload();
    _pushPanel(_buildLostPetReportsListRoute(isDarkMode));
  }

  void _openLostPetPetSelectionPanel(bool isDarkMode) {
    ref.read(myPetsControllerProvider.notifier).reload();
    _syncAndReloadData();
    _pushPanel(_buildLostPetPetSelectionRoute(isDarkMode));
  }

  void _selectLostPetForReport(PetRecord pet) {
    _updatePageState(() {
      _selectedLostPetForReport = pet;
      _activeReportSelectionContext = null;
      if (_hasOpenPanels && _panelStack.last.isLostPetPetSelectionPanel) _panelStack.removeLast();
    });
  }

  void _openFoundPetReportsListPanel(bool isDarkMode) {
    ref.read(petsControllerProvider.notifier).reload();
    ref.read(foundPetReportsControllerProvider.notifier).reload();
    ref.read(lostPetReportsControllerProvider.notifier).reload();
    _pushPanel(_buildFoundPetReportsListRoute(isDarkMode));
  }

  void _openGenericReportPanel(bool isDarkMode) {
    ref.read(genericReportsControllerProvider.notifier).reload();
    _updatePageState(() {
      _manualGenericReportLocation = null;
      _activeReportSelectionContext = null;
      _genericReportDraftPreview = const GenericReportDraftPreview(
        location: null,
        riskLevelCode: 'undefined',
        impactRadiusMeters: 0,
      );
    });
    _pushPanel(_buildGenericReportRoute(isDarkMode));
  }

  void _updateGenericReportDraftPreview(GenericReportDraftPreview preview) {
    final GenericReportDraftPreview? currentPreview = _genericReportDraftPreview;
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

  void _startLostPetMapSelection() {
    _startReportMapSelection(_ReportMapSelectionContext.lostPet);
  }

  void _startFoundPetMapSelection() {
    _startReportMapSelection(_ReportMapSelectionContext.foundPet);
  }

  void _startGenericReportMapSelection() {
    _startReportMapSelection(_ReportMapSelectionContext.generic);
  }

  void _startReportMapSelection(_ReportMapSelectionContext context) {
    _updatePageState(() {
      _activeReportSelectionContext = context;
    });
  }

  void _useCurrentLostPetLocation() {
    _useCurrentReportLocation(() => _manualLostPetLocation = null);
  }

  void _useCurrentFoundPetLocation() {
    _useCurrentReportLocation(() => _manualFoundPetLocation = null);
  }

  void _useCurrentGenericReportLocation() {
    _useCurrentReportLocation(() => _manualGenericReportLocation = null);
  }

  void _useCurrentReportLocation(VoidCallback clearManualLocation) {
    _updatePageState(() {
      clearManualLocation();
      _activeReportSelectionContext = null;
      if (_latestUserLocation == null || _userLocationErrorText != null) {
        _isUserLocationLoading = true;
        _userLocationErrorText = null;
        _userLocationRefreshRevision += 1;
      }
    });
  }

  Future<void> _openLostPetDetailsPanel(bool isDarkMode, LostPetReportRecord report) async {
    ref.read(lostPetReportsControllerProvider.notifier).reload();
    ref.read(petsControllerProvider.notifier).reload();
    _openOrReplaceReportDetails(
      () => _buildLostPetDetailsRoute(isDarkMode, report),
      canReplace: (_PanelRoute route) =>
          route.kind == PanelKind.lostPetDetails || route.kind == PanelKind.foundPetDetails,
      selectReport: () {
        _selectedHazard = null;
        _selectedLostPetReport = report;
        _selectedFoundPetReport = null;
        _selectedGenericReport = null;
        _reportFocusTarget = LatLng(report.lastSeenLatitude, report.lastSeenLongitude);
        _reportFocusRevision += 1;
      },
    );
  }

  Future<void> _openFoundPetDetailsPanel(bool isDarkMode, FoundPetReportRecord report) async {
    ref.read(foundPetReportsControllerProvider.notifier).reload();
    ref.read(lostPetReportsControllerProvider.notifier).reload();
    ref.read(petsControllerProvider.notifier).reload();
    _openOrReplaceReportDetails(
      () => _buildFoundPetDetailsRoute(isDarkMode, report),
      canReplace: (_PanelRoute route) => route.isFoundPetDetailsPanel,
      selectReport: () {
        _selectedHazard = null;
        _selectedLostPetReport = null;
        _selectedFoundPetReport = report;
        _selectedGenericReport = null;
        _reportFocusTarget = LatLng(report.latitude, report.longitude);
        _reportFocusRevision += 1;
      },
    );
  }

  Future<void> _openGenericReportDetailsPanel(bool isDarkMode, GenericReportRecord report) async {
    ref.read(genericReportsControllerProvider.notifier).reload();
    _openOrReplaceReportDetails(
      () => _buildGenericReportDetailsRoute(isDarkMode, report),
      canReplace: (_PanelRoute route) => route.isGenericReportDetailsPanel,
      selectReport: () {
        _selectedHazard = null;
        _selectedLostPetReport = null;
        _selectedFoundPetReport = null;
        _selectedGenericReport = report;
        _reportFocusTarget = LatLng(report.latitude, report.longitude);
        _reportFocusRevision += 1;
      },
    );
  }

  void _openOrReplaceReportDetails(
    _PanelRoute Function() routeBuilder, {
    required bool Function(_PanelRoute route) canReplace,
    required VoidCallback selectReport,
  }) {
    if (_hasOpenPanels) {
      if (!canReplace(_panelStack.last)) return;
      _updatePageState(selectReport);
      _replaceTopPanel(routeBuilder());
      return;
    }
    _updatePageState(selectReport);
    _pushPanel(routeBuilder());
  }

  _PanelRoute _buildReportSelectorRoute(bool isDarkMode) {
    return _buildReportPanelRoute(
      title: 'Reportar',
      width: 290,
      adaptHeightToContent: true,
      expandHorizontal: true,
      kind: PanelKind.reportSelector,
      contentBuilder: (BuildContext context) {
        return ReportTypeSelectorPanelContent(
          isDarkMode: isDarkMode,
          isAuthenticated: _isAuthenticated,
          onHazardPressed: () => _openReportHazardPanel(isDarkMode),
          onLostPetPressed: () => _openLostPetReportPanel(isDarkMode),
          onFoundPetPressed: () => _openFoundPetReportPanel(isDarkMode),
          onGenericPressed: () => _openGenericReportPanel(isDarkMode),
        );
      },
    );
  }

  Widget _authRequiredReportPanel(bool isDarkMode, String message) {
    return ReportAuthRequiredPanelContent(
      isDarkMode: isDarkMode,
      message: message,
      onLoginPressed: () => _replaceTopPanel(_buildLoginRoute(isDarkMode)),
    );
  }

  _PanelRoute _buildLostPetReportRoute(bool isDarkMode) {
    return _buildReportPanelRoute(
      title: 'Mascota Perdida',
      mobileMaxHeightFactor: 0.5,
      desktopMaxHeightFactor: 0.5,
      kind: PanelKind.lostPetReport,
      contentBuilder: (BuildContext context) {
        if (!_isAuthenticated) {
          return _authRequiredReportPanel(isDarkMode, 'Inicia sesion para reportar una mascota perdida.');
        }

        return LostPetReportingPanelContent(
          isDarkMode: isDarkMode,
          currentDeviceLocation: _latestUserLocation,
          currentLocationErrorText: _userLocationErrorText,
          selectedLocation: _manualLostPetLocation,
          selectedPet: _selectedLostPetForReport,
          isSelectingOnMap: _activeReportSelectionContext == _ReportMapSelectionContext.lostPet,
          onStartMapSelection: _startLostPetMapSelection,
          onUseCurrentLocation: _useCurrentLostPetLocation,
          onPreviewChanged: (_) {},
          onSelectPetPressed: () => _openLostPetPetSelectionPanel(isDarkMode),
          onViewFoundReportsPressed: () => _openFoundPetReportsListPanel(isDarkMode),
          onReported: _closeReportingFlowAfterSubmit,
        );
      },
    );
  }

  _PanelRoute _buildLostPetPetSelectionRoute(bool isDarkMode) {
    return _buildReportPanelRoute(
      title: 'Seleccionar Mascota',
      anchor: PanelAnchor.topLeft,
      width: 380,
      height: 620,
      maxHeight: 620,
      expandVertical: true,
      kind: PanelKind.lostPetPetSelection,
      contentBuilder: (BuildContext context) {
        return ManagePetsPanelContent(
          isDarkMode: isDarkMode,
          selectionMode: true,
          selectedPetId: _selectedLostPetForReport?.id,
          onAddPetPressed: () => _openAddPetPanel(isDarkMode),
          onViewPetPressed: (PetRecord pet) => _selectLostPetForReport(pet),
          onEditPetPressed: (PetRecord pet) => _openEditPetPanel(isDarkMode, pet),
        );
      },
    );
  }

  _PanelRoute _buildFoundPetReportRoute(bool isDarkMode) {
    return _buildReportPanelRoute(
      title: 'Mascota Encontrada',
      mobileMaxHeightFactor: 0.5,
      desktopMaxHeightFactor: 0.5,
      kind: PanelKind.foundPetReport,
      contentBuilder: (BuildContext context) {
        if (!_isAuthenticated) {
          return _authRequiredReportPanel(isDarkMode, 'Inicia sesion para reportar una mascota encontrada.');
        }

        final List<PetRecord> pets = ref.watch(petsControllerProvider).asData?.value ?? const <PetRecord>[];
        final LostPetReportRecord? selectedLostPetReport = _selectedLostReportForFoundReport;
        final PetRecord? selectedLostPet = selectedLostPetReport == null
            ? null
            : _findPetForLostReport(selectedLostPetReport, pets);

        return FoundPetReportingPanelContent(
          isDarkMode: isDarkMode,
          currentDeviceLocation: _latestUserLocation,
          currentLocationErrorText: _userLocationErrorText,
          selectedLocation: _manualFoundPetLocation,
          isSelectingOnMap: _activeReportSelectionContext == _ReportMapSelectionContext.foundPet,
          onStartMapSelection: _startFoundPetMapSelection,
          onUseCurrentLocation: _useCurrentFoundPetLocation,
          onPreviewChanged: (_) {},
          selectedLostPetReport: selectedLostPetReport,
          selectedLostPet: selectedLostPet,
          onViewLostReportsPressed: () => _openLostPetReportsListPanel(isDarkMode),
          onReported: _closeReportingFlowAfterSubmit,
        );
      },
    );
  }

  _PanelRoute _buildLostPetReportsListRoute(bool isDarkMode) {
    return _buildReportPanelRoute(
      title: 'Mascotas perdidas',
      anchor: PanelAnchor.topLeft,
      width: 380,
      height: 620,
      maxHeight: 620,
      expandVertical: true,
      kind: PanelKind.lostPetReportsList,
      contentBuilder: (BuildContext context) {
        final List<LostPetReportRecord> reports =
            ref.watch(lostPetReportsControllerProvider).asData?.value ?? const <LostPetReportRecord>[];
        final List<PetRecord> pets = ref.watch(petsControllerProvider).asData?.value ?? const <PetRecord>[];
        return LostPetReportsListPanelContent(
          isDarkMode: isDarkMode,
          reports: reports,
          pets: pets,
          onSelectReport: (LostPetReportRecord report) {
            _updatePageState(() {
              _selectedLostReportForFoundReport = report;
              if (_hasOpenPanels) _panelStack.removeLast();
            });
          },
          onGoToLocation: _focusReportLocation,
        );
      },
    );
  }

  _PanelRoute _buildFoundPetReportsListRoute(bool isDarkMode) {
    return _buildReportPanelRoute(
      title: 'Mascotas encontradas',
      anchor: PanelAnchor.topLeft,
      width: 380,
      height: 620,
      maxHeight: 620,
      expandVertical: true,
      kind: PanelKind.foundPetReportsList,
      contentBuilder: (BuildContext context) {
        final List<FoundPetReportRecord> reports =
            ref.watch(foundPetReportsControllerProvider).asData?.value ?? const <FoundPetReportRecord>[];
        final List<PetRecord> pets = ref.watch(petsControllerProvider).asData?.value ?? const <PetRecord>[];
        final List<LostPetReportRecord> lostReports =
            ref.watch(lostPetReportsControllerProvider).asData?.value ?? const <LostPetReportRecord>[];
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
    return _buildReportPanelRoute(
      title: 'Reporte',
      height: 340,
      kind: PanelKind.genericReport,
      contentBuilder: (BuildContext context) {
        return GenericReportPanelContent(
          isDarkMode: isDarkMode,
          currentDeviceLocation: _latestUserLocation,
          currentLocationErrorText: _userLocationErrorText,
          selectedLocation: _manualGenericReportLocation,
          isSelectingOnMap: _activeReportSelectionContext == _ReportMapSelectionContext.generic,
          onStartMapSelection: _startGenericReportMapSelection,
          onUseCurrentLocation: _useCurrentGenericReportLocation,
          onPreviewChanged: _updateGenericReportDraftPreview,
          onReported: _closeReportingFlowAfterSubmit,
        );
      },
    );
  }

  _PanelRoute _buildLostPetDetailsRoute(bool isDarkMode, LostPetReportRecord report) {
    return _buildReportDetailsShell(
      title: 'Mascota Perdida',
      kind: PanelKind.lostPetDetails,
      contentBuilder: (BuildContext context) {
        final List<PetRecord> pets = ref.watch(petsControllerProvider).asData?.value ?? const <PetRecord>[];
        return LostPetDetailsPanelContent(
          isDarkMode: isDarkMode,
          report: report,
          pet: _findPetForLostReport(report, pets),
          onViewComments: () => _openLostPetCommentsPanel(isDarkMode, report),
          debugDeleteLabel: kDebugMode ? 'Borrar mascota perdida' : null,
          onDebugDelete: kDebugMode ? _confirmAndDeleteSelectedDebugItem : null,
        );
      },
    );
  }

  _PanelRoute _buildFoundPetDetailsRoute(bool isDarkMode, FoundPetReportRecord report) {
    return _buildReportDetailsShell(
      title: 'Mascota Encontrada',
      kind: PanelKind.foundPetDetails,
      contentBuilder: (BuildContext context) {
        final List<PetRecord> pets = ref.watch(petsControllerProvider).asData?.value ?? const <PetRecord>[];
        final List<LostPetReportRecord> lostReports =
            ref.watch(lostPetReportsControllerProvider).asData?.value ?? const <LostPetReportRecord>[];
        final PetRecord? matchedPet = _findPetForFoundReport(report, pets, lostReports);
        final LostPetReportRecord? matchedLostPetReport = _findLostReportForFoundReport(report, lostReports);

        return FoundPetDetailsPanelContent(
          isDarkMode: isDarkMode,
          report: report,
          pet: matchedPet,
          matchedLostPetReport: matchedLostPetReport,
          onViewMatchedLostReport: matchedLostPetReport == null
              ? null
              : () => _openLostPetDetailsPanel(isDarkMode, matchedLostPetReport),
          onViewComments: () => _openFoundPetCommentsPanel(isDarkMode, report),
          debugDeleteLabel: kDebugMode ? 'Borrar mascota encontrada' : null,
          onDebugDelete: kDebugMode ? _confirmAndDeleteSelectedDebugItem : null,
        );
      },
    );
  }

  _PanelRoute _buildGenericReportDetailsRoute(bool isDarkMode, GenericReportRecord report) {
    return _buildReportDetailsShell(
      title: 'Reporte',
      kind: PanelKind.genericReportDetails,
      contentBuilder: (BuildContext context) {
        return GenericReportDetailsPanelContent(
          isDarkMode: isDarkMode,
          report: report,
          onViewComments: () => _openGenericReportCommentsPanel(isDarkMode, report),
          debugDeleteLabel: kDebugMode ? 'Borrar reporte' : null,
          onDebugDelete: kDebugMode ? _confirmAndDeleteSelectedDebugItem : null,
        );
      },
    );
  }

  _PanelRoute _buildReportDetailsShell({
    required String title,
    required PanelKind kind,
    required Widget Function(BuildContext context) contentBuilder,
  }) {
    return _buildReportPanelRoute(
      title: title,
      kind: kind,
      width: 380,
      height: 420,
      maxHeight: 520,
      contentBuilder: contentBuilder,
    );
  }

  void _openLostPetCommentsPanel(bool isDarkMode, LostPetReportRecord report) {
    _openReportCommentsPanel(isDarkMode, report.id, ReportCommentSubjectType.lostPet);
  }

  void _openFoundPetCommentsPanel(bool isDarkMode, FoundPetReportRecord report) {
    _openReportCommentsPanel(isDarkMode, report.id, ReportCommentSubjectType.foundPet);
  }

  void _openGenericReportCommentsPanel(bool isDarkMode, GenericReportRecord report) {
    _openReportCommentsPanel(isDarkMode, report.id, ReportCommentSubjectType.generic);
  }

  void _openReportCommentsPanel(bool isDarkMode, int reportId, ReportCommentSubjectType subjectType) {
    _pushPanel(_buildReportCommentsRoute(isDarkMode: isDarkMode, reportId: reportId, subjectType: subjectType));
  }

  _PanelRoute _buildReportCommentsRoute({
    required bool isDarkMode,
    required int reportId,
    required ReportCommentSubjectType subjectType,
  }) {
    return _buildReportPanelRoute(
      title: 'Comentarios',
      kind: PanelKind.hazardComments,
      width: 380,
      height: 560,
      maxHeight: 620,
      contentBuilder: (BuildContext context) {
        return ReportCommentsPanelContent(isDarkMode: isDarkMode, subjectType: subjectType, reportId: reportId);
      },
    );
  }

  _PanelRoute _buildReportPanelRoute({
    required String title,
    required PanelKind kind,
    required Widget Function(BuildContext context) contentBuilder,
    PanelAnchor anchor = PanelAnchor.bottomLeft,
    double width = 340,
    double? height,
    double? maxHeight,
    double? mobileMaxHeightFactor,
    double? desktopMaxHeightFactor,
    bool adaptHeightToContent = false,
    bool expandHorizontal = false,
    bool expandVertical = false,
    bool scrollContent = false,
  }) {
    return _PanelRoute(
      transitionKey: ++_panelTransitionSeed,
      title: title,
      anchor: anchor,
      width: width,
      height: height,
      maxHeight: maxHeight,
      mobileMaxHeightFactor: mobileMaxHeightFactor,
      desktopMaxHeightFactor: desktopMaxHeightFactor,
      adaptHeightToContent: adaptHeightToContent,
      expandHorizontal: expandHorizontal,
      expandVertical: expandVertical,
      scrollContent: scrollContent,
      kind: kind,
      borderRadius: BorderRadius.circular(22),
      contentBuilder: contentBuilder,
    );
  }

  Widget _buildProximityAlertOverlay(bool isDarkMode) {
    final _ProximityAlertTarget? alert = _activeProximityAlert;
    if (alert == null) return const SizedBox.shrink();

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
    final List<_ProximityAlertTarget> activeTargets = _collectProximityTargets(location)
      ..sort((_ProximityAlertTarget a, _ProximityAlertTarget b) => a.distanceMeters.compareTo(b.distanceMeters));

    final Set<String> nextZoneKeys = activeTargets.map((_ProximityAlertTarget target) => target.zoneKey).toSet();
    final Set<String> exitedZoneKeys = _currentProximityZoneKeys.difference(nextZoneKeys);
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

    if (_activeProximityAlert != null) return;

    for (final _ProximityAlertTarget target in activeTargets) {
      if (_acknowledgedProximityZoneKeys.contains(target.zoneKey)) continue;

      _showProximityAlert(target);
      return;
    }
  }

  _ProximityAlertTarget? _currentProximityAlertTarget() {
    final _ProximityAlertTarget? active = _activeProximityAlert;
    if (active == null) return null;

    for (final _ProximityAlertTarget target in _buildCurrentProximityTargets()) {
      if (target.zoneKey == active.zoneKey) return target;
    }

    return active;
  }

  List<_ProximityAlertTarget> _buildCurrentProximityTargets() {
    final LatLng? location = _latestUserLocation;
    if (location == null) return const <_ProximityAlertTarget>[];

    return _collectProximityTargets(location);
  }

  List<_ProximityAlertTarget> _collectProximityTargets(LatLng location) {
    final List<_ProximityAlertTarget> targets = <_ProximityAlertTarget>[];

    for (final HazardReportRecord report in _visibleHazardCircles) {
      final LatLng center = LatLng(report.incidentLatitude, report.incidentLongitude);
      final double distanceMeters = _distanceCalculator.distance(location, center);
      if (distanceMeters > report.impactRadiusMeters) continue;
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
      if (report.impactRadiusMeters <= 0) continue;
      final LatLng center = LatLng(report.latitude, report.longitude);
      final double distanceMeters = _distanceCalculator.distance(location, center);
      if (distanceMeters > report.impactRadiusMeters) continue;
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
    if (alert == null) return;

    _updatePageState(() {
      _acknowledgedProximityZoneKeys.add(alert.zoneKey);
      _activeProximityAlert = null;
    });

    final LatLng? location = _latestUserLocation;
    if (location != null) _evaluateProximityAlerts(location);
  }

  void _openCommentsFromProximityAlert() {
    final _ProximityAlertTarget? alert = _currentProximityAlertTarget();
    if (alert == null) return;

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
        if (hazard != null) _openHazardCommentsPanel(isDarkMode, hazard);
        break;
      case ReportCommentSubjectType.generic:
        GenericReportRecord? report;
        for (final GenericReportRecord item in _visibleGenericReports) {
          if (item.id == alert.reportId) {
            report = item;
            break;
          }
        }
        if (report != null) _openGenericReportCommentsPanel(isDarkMode, report);
        break;
      case ReportCommentSubjectType.lostPet:
      case ReportCommentSubjectType.foundPet:
        break;
    }
  }

  Future<void> _confirmAndDeleteSelectedDebugItem() async {
    if (!_isDebugDetailPanelOpen) return;

    final String label = _debugDeleteLabel ?? 'Borrar registro';
    final bool isDarkMode = ref.read(themeModeProvider);
    final bool confirmed = await showAppConfirmationDialog(
      context: context,
      isDarkMode: isDarkMode,
      title: label,
      message: 'Esta accion no se puede deshacer. Deseas continuar?',
      confirmLabel: 'Borrar',
    );

    if (!confirmed) return;

    try {
      switch (_panelStack.last.kind) {
        case PanelKind.hazardDetails:
          final HazardReportRecord? hazard = _selectedHazard;
          if (hazard == null) return;
          await ref
              .read(hazardReportsControllerProvider.notifier)
              .deleteHazardReport(hazardId: hazard.id, remoteId: hazard.remoteId);
        case PanelKind.lostPetDetails:
          final LostPetReportRecord? report = _selectedLostPetReport;
          if (report == null) return;
          await ref
              .read(lostPetReportsControllerProvider.notifier)
              .deleteLostPetReport(reportId: report.id, remoteId: report.remoteId);
        case PanelKind.foundPetDetails:
          final FoundPetReportRecord? report = _selectedFoundPetReport;
          if (report == null) return;
          await ref
              .read(foundPetReportsControllerProvider.notifier)
              .deleteFoundPetReport(reportId: report.id, remoteId: report.remoteId);
        case PanelKind.genericReportDetails:
          final GenericReportRecord? report = _selectedGenericReport;
          if (report == null) return;
          await ref
              .read(genericReportsControllerProvider.notifier)
              .deleteGenericReport(reportId: report.id, remoteId: report.remoteId);
        default:
          return;
      }

      if (!mounted) return;

      _closeCurrentPanel();
      _updatePageState(() {
        _activeProximityAlert = null;
      });
      _analyzeRouteForHazards();
      if (_latestUserLocation != null) _evaluateProximityAlerts(_latestUserLocation!);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registro borrado.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
    }
  }
}
