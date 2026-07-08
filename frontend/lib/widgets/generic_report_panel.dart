import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../providers/local_data_providers.dart';
import '../theme/app_palette.dart';
import 'location_picker_widget.dart';
import 'reporting_form_widgets.dart';
import 'reporting_panel_state.dart';

class GenericReportDraftPreview {
  final LatLng? location;
  final String riskLevelCode;
  final int impactRadiusMeters;

  const GenericReportDraftPreview({
    required this.location,
    required this.riskLevelCode,
    required this.impactRadiusMeters,
  });
}

class GenericReportPanelContent extends ConsumerStatefulWidget {
  final bool isDarkMode;
  final LatLng? currentDeviceLocation;
  final String? currentLocationErrorText;
  final LatLng? selectedLocation;
  final bool isSelectingOnMap;
  final VoidCallback onStartMapSelection;
  final VoidCallback onUseCurrentLocation;
  final ValueChanged<GenericReportDraftPreview> onPreviewChanged;
  final VoidCallback onReported;

  const GenericReportPanelContent({
    super.key,
    required this.isDarkMode,
    required this.currentDeviceLocation,
    required this.currentLocationErrorText,
    required this.selectedLocation,
    required this.isSelectingOnMap,
    required this.onStartMapSelection,
    required this.onUseCurrentLocation,
    required this.onPreviewChanged,
    required this.onReported,
  });

  @override
  ConsumerState<GenericReportPanelContent> createState() => _GenericReportPanelContentState();
}

class _GenericReportPanelContentState extends ConsumerState<GenericReportPanelContent>
    with ReportingPanelState<GenericReportPanelContent> {
  static const List<ReportingSelectionOption> _riskOptions = <ReportingSelectionOption>[
    ReportingSelectionOption('low', 'Bajo'),
    ReportingSelectionOption('medium', 'Medio'),
    ReportingSelectionOption('high', 'Alto'),
    ReportingSelectionOption('undefined', 'No lo se'),
  ];
  static const List<ReportingSelectionOption> _impactRadiusOptions = <ReportingSelectionOption>[
    ReportingSelectionOption('1', '1 m'),
    ReportingSelectionOption('10', '10 m'),
    ReportingSelectionOption('100', '100 m'),
    ReportingSelectionOption('300', '300 m'),
  ];

  final TextEditingController _descriptionController = TextEditingController();
  DateTime _reportedDate = DateTime.now();
  String _selectedRiskLevelCode = 'undefined';
  bool _isPetDanger = false;
  String _selectedImpactRadiusCode = '10';
  String? _descriptionErrorText;

  LatLng? get _effectiveLocation {
    return effectiveReportLocation(widget.selectedLocation, widget.currentDeviceLocation);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _emitPreview());
  }

  @override
  void didUpdateWidget(covariant GenericReportPanelContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    emitPreviewWhenLocationChanges(
      oldWidget.currentDeviceLocation,
      widget.currentDeviceLocation,
      oldWidget.selectedLocation,
      widget.selectedLocation,
      _emitPreview,
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _emitPreview() {
    widget.onPreviewChanged(
      GenericReportDraftPreview(
        location: _effectiveLocation,
        riskLevelCode: _selectedRiskLevelCode,
        impactRadiusMeters: _isPetDanger ? int.parse(_selectedImpactRadiusCode) : 0,
      ),
    );
  }

  Future<void> _pickPhoto() => pickReportPhoto((service) => service.pickAndStoreGenericReportPhoto());

  Future<void> _pickDate() async {
    await pickReportDate(
      isDarkMode: widget.isDarkMode,
      initialDate: _reportedDate,
      onPicked: (DateTime value) => _reportedDate = value,
    );
  }

  Future<void> _save() async {
    final LatLng? resolvedLocation = _effectiveLocation;

    resetReportErrors(() {
      _descriptionErrorText = null;
    });

    if (resolvedLocation == null) {
      locationErrorText = 'Necesitamos una ubicación valida para crear el reporte.';
    }

    if (_descriptionController.text.trim().isEmpty) _descriptionErrorText = 'La descripción es obligatoria.';

    if (locationErrorText != null || _descriptionErrorText != null) {
      setSubmitValidationError();
      return;
    }

    await runReportSave(() async {
      await ref
          .read(genericReportsControllerProvider.notifier)
          .addGenericReport(
            latitude: resolvedLocation!.latitude,
            longitude: resolvedLocation.longitude,
            description: _descriptionController.text.trim(),
            reportedDate: _reportedDate,
            riskLevelCode: _selectedRiskLevelCode,
            impactRadiusMeters: _isPetDanger ? int.parse(_selectedImpactRadiusCode) : 0,
            photoUrl: storedPhotoUrl,
          );

      if (mounted) widget.onReported();
    });
  }

  @override
  Widget build(BuildContext context) {
    final String? locationError = resolvedLocationError(
      currentLocationErrorText: widget.currentLocationErrorText,
      hasManualLocation: widget.selectedLocation != null,
    );

    return ReportingPanelScaffold(
      submitLabel: 'Crear reporte',
      isBusy: isSaving,
      onSubmit: _save,
      submitColor: AppPalette.charcoal,
      submitValidationErrorText: submitValidationErrorText,
      children: [
        LocationPickerWidget(
          isDarkMode: widget.isDarkMode,
          title: 'Ubicación del reporte',
          subtitle: 'Selecciona donde ocurre la situacion.',
          hasManualLocation: widget.selectedLocation != null,
          hasCurrentLocation: widget.currentDeviceLocation != null,
          errorText: locationError,
          onStartSelection: widget.onStartMapSelection,
          onUseCurrentLocation: widget.onUseCurrentLocation,
        ),
        const SizedBox(height: 10),
        ReportingLabeledField(
          label: 'Descripción',
          child: ReportingTextField(
            isDarkMode: widget.isDarkMode,
            controller: _descriptionController,
            hintText: 'Describe lo que está ocurriendo',
            maxLines: 3,
            errorText: _descriptionErrorText,
            onChanged: (_) {
              if (_descriptionErrorText != null) {
                setState(() {
                  _descriptionErrorText = null;
                  submitValidationErrorText = null;
                });
              }
            },
          ),
        ),
        const SizedBox(height: 8),
        ReportingLabeledField(
          label: 'Fecha',
          child: ReportingDateField(
            isDarkMode: widget.isDarkMode,
            valueText: formatReportingDate(_reportedDate),
            onTap: _pickDate,
          ),
        ),
        const SizedBox(height: 8),
        ReportingLabeledField(
          label: 'Nivel de riesgo',
          child: ReportingDropdownField(
            isDarkMode: widget.isDarkMode,
            value: _selectedRiskLevelCode,
            items: _riskOptions,
            onChanged: (String value) {
              setState(() {
                _selectedRiskLevelCode = value;
              });
              _emitPreview();
            },
          ),
        ),
        const SizedBox(height: 8),
        ReportingLabeledField(
          label: 'Impacto en rutas',
          child: ReportingCheckboxField(
            isDarkMode: widget.isDarkMode,
            value: _isPetDanger,
            title: 'Peligro para las mascotas',
            subtitle: 'Activalo si este reporte debe afectar el calculo de rutas.',
            onChanged: (bool value) {
              setState(() {
                _isPetDanger = value;
              });
              _emitPreview();
            },
          ),
        ),
        if (_isPetDanger) ...[
          const SizedBox(height: 8),
          ReportingLabeledField(
            label: 'Radio de afectación',
            child: ReportingDropdownField(
              isDarkMode: widget.isDarkMode,
              value: _selectedImpactRadiusCode,
              items: _impactRadiusOptions,
              onChanged: (String value) {
                setState(() {
                  _selectedImpactRadiusCode = value;
                });
                _emitPreview();
              },
            ),
          ),
        ],
        const SizedBox(height: 8),
        ReportingLabeledField(
          label: 'Foto (opcional)',
          child: ReportingPhotoField(
            isDarkMode: widget.isDarkMode,
            photoSource: storedPhotoUrl,
            isBusy: isPickingPhoto,
            onPickPressed: _pickPhoto,
          ),
        ),
        if (saveErrorText != null) ...[const SizedBox(height: 10), ReportingFieldErrorText(message: saveErrorText!)],
      ],
    );
  }
}
