import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../models/found_pet_report_record.dart';
import '../models/generic_report_record.dart';
import '../models/hazard_report_record.dart';
import '../models/lost_pet_report_record.dart';
import '../models/pet_record.dart';

enum ReportMapSelectionContext { hazard, lostPet, foundPet, generic }

class ReportDraftState {
  final LatLng? location;
  final int impactRadiusMeters;
  final String riskLevelCode;

  const ReportDraftState({
    this.location,
    this.impactRadiusMeters = 0,
    this.riskLevelCode = 'undefined',
  });

  ReportDraftState copyWith({
    Object? location = _sentinel,
    int? impactRadiusMeters,
    String? riskLevelCode,
  }) {
    return ReportDraftState(
      location: location == _sentinel ? this.location : location as LatLng?,
      impactRadiusMeters: impactRadiusMeters ?? this.impactRadiusMeters,
      riskLevelCode: riskLevelCode ?? this.riskLevelCode,
    );
  }
}

class ReportFlowState {
  final bool isSelectingHazardLocationOnMap;
  final ReportMapSelectionContext? activeSelectionContext;
  final LatLng? manualHazardLocation;
  final LatLng? manualLostPetLocation;
  final LatLng? manualFoundPetLocation;
  final LatLng? manualGenericReportLocation;
  final ReportDraftState? hazardDraftPreview;
  final ReportDraftState? genericReportDraftPreview;
  final HazardReportRecord? selectedHazard;
  final LostPetReportRecord? selectedLostPetReport;
  final FoundPetReportRecord? selectedFoundPetReport;
  final GenericReportRecord? selectedGenericReport;
  final PetRecord? selectedLostPetForReport;
  final LostPetReportRecord? selectedLostReportForFoundReport;
  final bool showLowRiskHazardCircles;
  final bool showMediumRiskHazardCircles;
  final bool showHighRiskHazardCircles;
  final bool showLostPetReports;
  final bool showFoundPetReports;
  final bool showGenericReports;

  const ReportFlowState({
    this.isSelectingHazardLocationOnMap = false,
    this.activeSelectionContext,
    this.manualHazardLocation,
    this.manualLostPetLocation,
    this.manualFoundPetLocation,
    this.manualGenericReportLocation,
    this.hazardDraftPreview,
    this.genericReportDraftPreview,
    this.selectedHazard,
    this.selectedLostPetReport,
    this.selectedFoundPetReport,
    this.selectedGenericReport,
    this.selectedLostPetForReport,
    this.selectedLostReportForFoundReport,
    this.showLowRiskHazardCircles = true,
    this.showMediumRiskHazardCircles = true,
    this.showHighRiskHazardCircles = true,
    this.showLostPetReports = true,
    this.showFoundPetReports = true,
    this.showGenericReports = true,
  });

  ReportFlowState copyWith({
    bool? isSelectingHazardLocationOnMap,
    Object? activeSelectionContext = _sentinel,
    Object? manualHazardLocation = _sentinel,
    Object? manualLostPetLocation = _sentinel,
    Object? manualFoundPetLocation = _sentinel,
    Object? manualGenericReportLocation = _sentinel,
    Object? hazardDraftPreview = _sentinel,
    Object? genericReportDraftPreview = _sentinel,
    Object? selectedHazard = _sentinel,
    Object? selectedLostPetReport = _sentinel,
    Object? selectedFoundPetReport = _sentinel,
    Object? selectedGenericReport = _sentinel,
    Object? selectedLostPetForReport = _sentinel,
    Object? selectedLostReportForFoundReport = _sentinel,
    bool? showLowRiskHazardCircles,
    bool? showMediumRiskHazardCircles,
    bool? showHighRiskHazardCircles,
    bool? showLostPetReports,
    bool? showFoundPetReports,
    bool? showGenericReports,
  }) {
    return ReportFlowState(
      isSelectingHazardLocationOnMap:
          isSelectingHazardLocationOnMap ?? this.isSelectingHazardLocationOnMap,
      activeSelectionContext: activeSelectionContext == _sentinel
          ? this.activeSelectionContext
          : activeSelectionContext as ReportMapSelectionContext?,
      manualHazardLocation: manualHazardLocation == _sentinel
          ? this.manualHazardLocation
          : manualHazardLocation as LatLng?,
      manualLostPetLocation: manualLostPetLocation == _sentinel
          ? this.manualLostPetLocation
          : manualLostPetLocation as LatLng?,
      manualFoundPetLocation: manualFoundPetLocation == _sentinel
          ? this.manualFoundPetLocation
          : manualFoundPetLocation as LatLng?,
      manualGenericReportLocation: manualGenericReportLocation == _sentinel
          ? this.manualGenericReportLocation
          : manualGenericReportLocation as LatLng?,
      hazardDraftPreview: hazardDraftPreview == _sentinel
          ? this.hazardDraftPreview
          : hazardDraftPreview as ReportDraftState?,
      genericReportDraftPreview: genericReportDraftPreview == _sentinel
          ? this.genericReportDraftPreview
          : genericReportDraftPreview as ReportDraftState?,
      selectedHazard: selectedHazard == _sentinel
          ? this.selectedHazard
          : selectedHazard as HazardReportRecord?,
      selectedLostPetReport: selectedLostPetReport == _sentinel
          ? this.selectedLostPetReport
          : selectedLostPetReport as LostPetReportRecord?,
      selectedFoundPetReport: selectedFoundPetReport == _sentinel
          ? this.selectedFoundPetReport
          : selectedFoundPetReport as FoundPetReportRecord?,
      selectedGenericReport: selectedGenericReport == _sentinel
          ? this.selectedGenericReport
          : selectedGenericReport as GenericReportRecord?,
      selectedLostPetForReport: selectedLostPetForReport == _sentinel
          ? this.selectedLostPetForReport
          : selectedLostPetForReport as PetRecord?,
      selectedLostReportForFoundReport:
          selectedLostReportForFoundReport == _sentinel
          ? this.selectedLostReportForFoundReport
          : selectedLostReportForFoundReport as LostPetReportRecord?,
      showLowRiskHazardCircles:
          showLowRiskHazardCircles ?? this.showLowRiskHazardCircles,
      showMediumRiskHazardCircles:
          showMediumRiskHazardCircles ?? this.showMediumRiskHazardCircles,
      showHighRiskHazardCircles:
          showHighRiskHazardCircles ?? this.showHighRiskHazardCircles,
      showLostPetReports: showLostPetReports ?? this.showLostPetReports,
      showFoundPetReports: showFoundPetReports ?? this.showFoundPetReports,
      showGenericReports: showGenericReports ?? this.showGenericReports,
    );
  }
}

final reportFlowProvider =
    NotifierProvider<ReportFlowController, ReportFlowState>(
      ReportFlowController.new,
    );

class ReportFlowController extends Notifier<ReportFlowState> {
  @override
  ReportFlowState build() {
    return const ReportFlowState();
  }

  void beginLocationSelection(ReportMapSelectionContext context) {
    state = state.copyWith(
      activeSelectionContext: context,
      isSelectingHazardLocationOnMap:
          context == ReportMapSelectionContext.hazard,
    );
  }

  void setManualLocation(ReportMapSelectionContext context, LatLng? location) {
    state = switch (context) {
      ReportMapSelectionContext.hazard => state.copyWith(
        manualHazardLocation: location,
        activeSelectionContext: null,
        isSelectingHazardLocationOnMap: false,
      ),
      ReportMapSelectionContext.lostPet => state.copyWith(
        manualLostPetLocation: location,
        activeSelectionContext: null,
      ),
      ReportMapSelectionContext.foundPet => state.copyWith(
        manualFoundPetLocation: location,
        activeSelectionContext: null,
      ),
      ReportMapSelectionContext.generic => state.copyWith(
        manualGenericReportLocation: location,
        activeSelectionContext: null,
      ),
    };
  }

  void updateHazardDraft(ReportDraftState? preview) {
    state = state.copyWith(hazardDraftPreview: preview);
  }

  void updateGenericDraft(ReportDraftState? preview) {
    state = state.copyWith(genericReportDraftPreview: preview);
  }

  void setHazardRiskVisibility({bool? low, bool? medium, bool? high}) {
    state = state.copyWith(
      showLowRiskHazardCircles: low,
      showMediumRiskHazardCircles: medium,
      showHighRiskHazardCircles: high,
    );
  }

  void setReportLayerVisibility({
    bool? lostPets,
    bool? foundPets,
    bool? generic,
  }) {
    state = state.copyWith(
      showLostPetReports: lostPets,
      showFoundPetReports: foundPets,
      showGenericReports: generic,
    );
  }

  void clearReportingDrafts() {
    state = state.copyWith(
      isSelectingHazardLocationOnMap: false,
      activeSelectionContext: null,
      manualHazardLocation: null,
      manualLostPetLocation: null,
      manualFoundPetLocation: null,
      manualGenericReportLocation: null,
      hazardDraftPreview: null,
      genericReportDraftPreview: null,
      selectedLostPetForReport: null,
      selectedLostReportForFoundReport: null,
    );
  }

  void replace(ReportFlowState nextState) {
    state = nextState;
  }
}

const Object _sentinel = Object();
