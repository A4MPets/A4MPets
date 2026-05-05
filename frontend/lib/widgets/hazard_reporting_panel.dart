import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../providers/local_data_providers.dart';
import '../theme/app_palette.dart';
import 'location_picker_widget.dart';
import 'reporting_form_widgets.dart';

class HazardDraftPreview {
  final LatLng? location;
  final int impactRadiusMeters;
  final String riskLevelCode;
  final bool isSelectingOnMap;

  const HazardDraftPreview({
    required this.location,
    required this.impactRadiusMeters,
    required this.riskLevelCode,
    required this.isSelectingOnMap,
  });
}

class ReportHazardPanelContent extends ConsumerStatefulWidget {
  final bool isDarkMode;
  final LatLng? currentDeviceLocation;
  final bool isLoadingCurrentLocation;
  final String? currentLocationErrorText;
  final LatLng? selectedHazardLocation;
  final bool isSelectingHazardLocationOnMap;
  final VoidCallback onStartMapSelection;
  final VoidCallback onUseCurrentLocation;
  final ValueChanged<HazardDraftPreview> onPreviewChanged;
  final VoidCallback onReported;

  const ReportHazardPanelContent({
    super.key,
    required this.isDarkMode,
    required this.currentDeviceLocation,
    required this.isLoadingCurrentLocation,
    required this.currentLocationErrorText,
    required this.selectedHazardLocation,
    required this.isSelectingHazardLocationOnMap,
    required this.onStartMapSelection,
    required this.onUseCurrentLocation,
    required this.onPreviewChanged,
    required this.onReported,
  });

  @override
  ConsumerState<ReportHazardPanelContent> createState() =>
      _ReportHazardPanelContentState();
}

class _ReportHazardPanelContentState
    extends ConsumerState<ReportHazardPanelContent> {
  static const List<ReportingSelectionOption> _categoryOptions =
      <ReportingSelectionOption>[
        ReportingSelectionOption('contagious_disease', 'Enfermedad contagiosa'),
        ReportingSelectionOption('stagnant_water', 'Aguas estancadas'),
        ReportingSelectionOption(
          'waste_accumulation',
          'Acumulación de residuos',
        ),
        ReportingSelectionOption('pest_presence', 'Presencia de plagas'),
        ReportingSelectionOption(
          'possible_rabies_vectors',
          'Posibles transmisores de rabia',
        ),
      ];

  static const List<ReportingSelectionOption> _durationOptions =
      <ReportingSelectionOption>[
        ReportingSelectionOption('undefined', 'No lo se'),
        ReportingSelectionOption('1_day', '1 Dia'),
        ReportingSelectionOption('3_days', '3 Dias'),
        ReportingSelectionOption('1_week', '1 Semana'),
        ReportingSelectionOption('2_weeks', '2 Semanas'),
        ReportingSelectionOption('1_month', '1 Mes'),
        ReportingSelectionOption('3_months', '3 Meses'),
        ReportingSelectionOption('6_months', '6 Meses'),
        ReportingSelectionOption('1_year', '1 Ano'),
      ];

  static const List<ReportingSelectionOption> _riskOptions =
      <ReportingSelectionOption>[
        ReportingSelectionOption('low', 'Bajo'),
        ReportingSelectionOption('medium', 'Medio'),
        ReportingSelectionOption('high', 'Alto'),
        ReportingSelectionOption('undefined', 'No lo se'),
      ];

  static const List<int> _impactRadiusOptions = <int>[1, 10, 100, 300];

  late final TextEditingController _descriptionController;
  String _selectedCategoryCode = _categoryOptions.first.code;
  String _selectedDurationCode = 'undefined';
  String _selectedRiskLevelCode = 'undefined';
  int _selectedImpactRadiusMeters = 10;
  String? _storedEvidencePhotoUrl;
  late final DateTime _reportedAt;
  bool _isSaving = false;
  bool _isPickingPhoto = false;
  String? _locationErrorText;
  String? _descriptionErrorText;
  String? _submitValidationErrorText;
  String? _saveErrorText;

  LatLng? get _effectiveHazardLocation {
    return widget.selectedHazardLocation ?? widget.currentDeviceLocation;
  }

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _reportedAt = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) => _emitDraftPreview());
  }

  @override
  void didUpdateWidget(covariant ReportHazardPanelContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentDeviceLocation != widget.currentDeviceLocation ||
        oldWidget.selectedHazardLocation != widget.selectedHazardLocation ||
        oldWidget.isSelectingHazardLocationOnMap !=
            widget.isSelectingHazardLocationOnMap) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _emitDraftPreview());
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _emitDraftPreview() {
    widget.onPreviewChanged(
      HazardDraftPreview(
        location: _effectiveHazardLocation,
        impactRadiusMeters: _selectedImpactRadiusMeters,
        riskLevelCode: _selectedRiskLevelCode,
        isSelectingOnMap: widget.isSelectingHazardLocationOnMap,
      ),
    );
  }

  Future<void> _pickEvidencePhoto() async {
    setState(() {
      _isPickingPhoto = true;
      _saveErrorText = null;
    });

    try {
      final String? storedPath = await ref
          .read(localMediaStorageServiceProvider)
          .pickAndStoreHazardPhoto();

      if (!mounted) {
        return;
      }

      setState(() {
        _storedEvidencePhotoUrl = storedPath;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saveErrorText = 'No se pudo cargar la foto. Intenta nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPickingPhoto = false;
        });
      }
    }
  }

  Future<void> _saveHazardReport() async {
    final LatLng? resolvedLocation = _effectiveHazardLocation;

    setState(() {
      _locationErrorText = null;
      _descriptionErrorText = null;
      _submitValidationErrorText = null;
      _saveErrorText = null;
    });

    if (resolvedLocation == null) {
      setState(() {
        _locationErrorText =
            'Necesitamos una ubicación valida para reportar este peligro.';
        _submitValidationErrorText =
            'Completa los campos obligatorios para reportar.';
      });
      return;
    }

    final String narrativeDescription = _descriptionController.text.trim();
    if (narrativeDescription.isEmpty) {
      setState(() {
        _descriptionErrorText = 'La descripción del peligro es obligatoria.';
        _submitValidationErrorText =
            'Completa los campos obligatorios para reportar.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final profile = await ref.read(localUserProfileProvider.future);
      final String reporterName = profile.isAuthenticated
          ? profile.username
          : 'Anonimo';

      await ref
          .read(hazardReportsControllerProvider.notifier)
          .addHazardReport(
            incidentLatitude: resolvedLocation.latitude,
            incidentLongitude: resolvedLocation.longitude,
            impactRadiusMeters: _selectedImpactRadiusMeters,
            categoryCode: _selectedCategoryCode,
            narrativeDescription: narrativeDescription,
            reportedAt: _reportedAt,
            estimatedDurationCode: _selectedDurationCode,
            riskLevelCode: _selectedRiskLevelCode,
            evidencePhotoUrl: _storedEvidencePhotoUrl,
            reportedByUsername: reporterName,
          );

      if (!mounted) {
        return;
      }

      widget.onReported();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saveErrorText = 'No se pudo guardar el reporte. Intenta nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? resolvedLocationErrorText =
        _locationErrorText ??
        (widget.selectedHazardLocation == null &&
                !widget.isSelectingHazardLocationOnMap
            ? widget.currentLocationErrorText
            : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LocationPickerWidget(
                  isDarkMode: widget.isDarkMode,
                  title: 'Ubicación del peligro',
                  subtitle: 'Selecciona el lugar del peligro.',
                  hasManualLocation: widget.selectedHazardLocation != null,
                  hasCurrentLocation: widget.currentDeviceLocation != null,
                  errorText: resolvedLocationErrorText,
                  onStartSelection: widget.onStartMapSelection,
                  onUseCurrentLocation: widget.onUseCurrentLocation,
                ),
                const SizedBox(height: 10),
                ReportingLabeledField(
                  label: 'Radio de afectación ($_selectedImpactRadiusMeters m)',
                  child: ReportingDropdownField(
                    isDarkMode: widget.isDarkMode,
                    value: _selectedImpactRadiusMeters.toString(),
                    items: _impactRadiusOptions
                        .map(
                          (int value) =>
                              ReportingSelectionOption('$value', '$value m'),
                        )
                        .toList(growable: false),
                    onChanged: (String value) {
                      setState(() {
                        _selectedImpactRadiusMeters = int.parse(value);
                      });
                      _emitDraftPreview();
                    },
                  ),
                ),
                const SizedBox(height: 8),
                ReportingLabeledField(
                  label: 'Categoria',
                  child: ReportingDropdownField(
                    isDarkMode: widget.isDarkMode,
                    value: _selectedCategoryCode,
                    items: _categoryOptions,
                    onChanged: (String value) {
                      setState(() {
                        _selectedCategoryCode = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 8),
                ReportingLabeledField(
                  label: 'Descripción del peligro',
                  child: ReportingTextField(
                    isDarkMode: widget.isDarkMode,
                    controller: _descriptionController,
                    hintText: 'Describe lo que observas en el lugar',
                    maxLines: 3,
                    errorText: _descriptionErrorText,
                    onSubmitted: (_) {
                      if (!_isSaving) {
                        _saveHazardReport();
                      }
                    },
                    onChanged: (String value) {
                      if (_descriptionErrorText != null &&
                          value.trim().isNotEmpty) {
                        setState(() {
                          _descriptionErrorText = null;
                          _submitValidationErrorText = null;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                ReportingLabeledField(
                  label: 'Duración aproximada',
                  child: ReportingDropdownField(
                    isDarkMode: widget.isDarkMode,
                    value: _selectedDurationCode,
                    items: _durationOptions,
                    onChanged: (String value) {
                      setState(() {
                        _selectedDurationCode = value;
                      });
                    },
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
                      _emitDraftPreview();
                    },
                  ),
                ),
                const SizedBox(height: 8),
                ReportingLabeledField(
                  label: 'Foto (opcional)',
                  child: ReportingPhotoField(
                    isDarkMode: widget.isDarkMode,
                    photoSource: _storedEvidencePhotoUrl,
                    isBusy: _isPickingPhoto,
                    onPickPressed: _pickEvidencePhoto,
                  ),
                ),
                if (_saveErrorText != null) ...[
                  const SizedBox(height: 10),
                  ReportingFieldErrorText(message: _saveErrorText!),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_submitValidationErrorText != null) ...[
          ReportingFieldErrorText(message: _submitValidationErrorText!),
          const SizedBox(height: 8),
        ],
        ReportingPrimaryButton(
          label: 'Reportar peligro',
          isBusy: _isSaving,
          onPressed: _saveHazardReport,
          backgroundColor: AppPalette.dangerRed,
        ),
      ],
    );
  }
}
