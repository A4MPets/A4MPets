import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../providers/local_data_providers.dart';
import '../theme/app_palette.dart';
import 'location_picker_widget.dart';
import 'reporting_form_widgets.dart';
import 'shared/panel_scroll_view.dart';

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
  ConsumerState<GenericReportPanelContent> createState() =>
      _GenericReportPanelContentState();
}

class _GenericReportPanelContentState
    extends ConsumerState<GenericReportPanelContent> {
  static const List<ReportingSelectionOption> _riskOptions =
      <ReportingSelectionOption>[
        ReportingSelectionOption('low', 'Bajo'),
        ReportingSelectionOption('medium', 'Medio'),
        ReportingSelectionOption('high', 'Alto'),
        ReportingSelectionOption('undefined', 'No lo se'),
      ];
  static const List<ReportingSelectionOption> _impactRadiusOptions =
      <ReportingSelectionOption>[
        ReportingSelectionOption('1', '1 m'),
        ReportingSelectionOption('10', '10 m'),
        ReportingSelectionOption('100', '100 m'),
        ReportingSelectionOption('300', '300 m'),
      ];

  late final TextEditingController _descriptionController;
  late DateTime _reportedDate;
  String _selectedRiskLevelCode = 'undefined';
  bool _isPetDanger = false;
  String _selectedImpactRadiusCode = '10';
  String? _storedPhotoUrl;
  bool _isSaving = false;
  bool _isPickingPhoto = false;
  String? _locationErrorText;
  String? _descriptionErrorText;
  String? _submitValidationErrorText;
  String? _saveErrorText;

  LatLng? get _effectiveLocation {
    return widget.selectedLocation ?? widget.currentDeviceLocation;
  }

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _reportedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) => _emitPreview());
  }

  @override
  void didUpdateWidget(covariant GenericReportPanelContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentDeviceLocation != widget.currentDeviceLocation ||
        oldWidget.selectedLocation != widget.selectedLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _emitPreview());
    }
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
        impactRadiusMeters: _isPetDanger
            ? int.parse(_selectedImpactRadiusCode)
            : 0,
      ),
    );
  }

  Future<void> _pickPhoto() async {
    setState(() {
      _isPickingPhoto = true;
      _saveErrorText = null;
    });

    try {
      final String? storedPath = await ref
          .read(localMediaStorageServiceProvider)
          .pickAndStoreGenericReportPhoto();
      if (!mounted) {
        return;
      }
      setState(() {
        _storedPhotoUrl = storedPath;
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

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showReportingDatePicker(
      context: context,
      isDarkMode: widget.isDarkMode,
      initialDate: _reportedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year, now.month, now.day),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _reportedDate = picked;
    });
  }

  Future<void> _save() async {
    final LatLng? resolvedLocation = _effectiveLocation;

    setState(() {
      _locationErrorText = null;
      _descriptionErrorText = null;
      _submitValidationErrorText = null;
      _saveErrorText = null;
    });

    if (resolvedLocation == null) {
      setState(() {
        _locationErrorText =
            'Necesitamos una ubicacion valida para crear el reporte.';
      });
    }

    if (_descriptionController.text.trim().isEmpty) {
      setState(() {
        _descriptionErrorText = 'La descripcion es obligatoria.';
      });
    }

    if (_locationErrorText != null || _descriptionErrorText != null) {
      setState(() {
        _submitValidationErrorText =
            'Completa los campos obligatorios para reportar.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(genericReportsControllerProvider.notifier)
          .addGenericReport(
            latitude: resolvedLocation!.latitude,
            longitude: resolvedLocation.longitude,
            description: _descriptionController.text.trim(),
            reportedDate: _reportedDate,
            riskLevelCode: _selectedRiskLevelCode,
            impactRadiusMeters: _isPetDanger
                ? int.parse(_selectedImpactRadiusCode)
                : 0,
            photoUrl: _storedPhotoUrl,
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

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final String? locationError =
        _locationErrorText ??
        (widget.selectedLocation == null
            ? widget.currentLocationErrorText
            : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: PanelScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LocationPickerWidget(
                  isDarkMode: widget.isDarkMode,
                  title: 'Ubicacion del reporte',
                  subtitle: 'Selecciona donde ocurre la situacion.',
                  hasManualLocation: widget.selectedLocation != null,
                  hasCurrentLocation: widget.currentDeviceLocation != null,
                  errorText: locationError,
                  onStartSelection: widget.onStartMapSelection,
                  onUseCurrentLocation: widget.onUseCurrentLocation,
                ),
                const SizedBox(height: 10),
                ReportingLabeledField(
                  label: 'Descripcion',
                  child: ReportingTextField(
                    isDarkMode: widget.isDarkMode,
                    controller: _descriptionController,
                    hintText: 'Describe lo que esta ocurriendo',
                    maxLines: 3,
                    errorText: _descriptionErrorText,
                    onChanged: (_) {
                      if (_descriptionErrorText != null) {
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
                  label: 'Fecha',
                  child: ReportingDateField(
                    isDarkMode: widget.isDarkMode,
                    valueText: _formatDate(_reportedDate),
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
                    subtitle:
                        'Activalo si este reporte debe afectar el calculo de rutas.',
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
                    label: 'Radio de afectacion',
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
                    photoSource: _storedPhotoUrl,
                    isBusy: _isPickingPhoto,
                    onPickPressed: _pickPhoto,
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
          label: 'Crear reporte',
          isBusy: _isSaving,
          onPressed: _save,
          backgroundColor: AppPalette.charcoal,
        ),
      ],
    );
  }
}
