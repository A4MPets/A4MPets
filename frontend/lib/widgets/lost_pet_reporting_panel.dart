import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../providers/local_data_providers.dart';
import '../theme/app_palette.dart';
import 'location_picker_widget.dart';
import 'reporting_form_widgets.dart';
import 'shared/panel_scroll_view.dart';

class LostPetDraftPreview {
  final LatLng? location;

  const LostPetDraftPreview({required this.location});
}

class LostPetReportingPanelContent extends ConsumerStatefulWidget {
  final bool isDarkMode;
  final LatLng? currentDeviceLocation;
  final String? currentLocationErrorText;
  final LatLng? selectedLocation;
  final bool isSelectingOnMap;
  final VoidCallback onStartMapSelection;
  final VoidCallback onUseCurrentLocation;
  final ValueChanged<LostPetDraftPreview> onPreviewChanged;
  final VoidCallback onReported;

  const LostPetReportingPanelContent({
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
  ConsumerState<LostPetReportingPanelContent> createState() =>
      _LostPetReportingPanelContentState();
}

class _LostPetReportingPanelContentState
    extends ConsumerState<LostPetReportingPanelContent> {
  late final TextEditingController _nameController;
  late final TextEditingController _detailsController;
  late final TextEditingController _phoneController;
  late DateTime _disappearanceDate;
  String? _storedPhotoUrl;
  bool _isSaving = false;
  bool _isPickingPhoto = false;
  String? _locationErrorText;
  String? _nameErrorText;
  String? _detailsErrorText;
  String? _phoneErrorText;
  String? _photoErrorText;
  String? _submitValidationErrorText;
  String? _saveErrorText;

  LatLng? get _effectiveLocation {
    return widget.selectedLocation ?? widget.currentDeviceLocation;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _detailsController = TextEditingController();
    _phoneController = TextEditingController();
    _disappearanceDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) => _emitPreview());
  }

  @override
  void didUpdateWidget(covariant LostPetReportingPanelContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentDeviceLocation != widget.currentDeviceLocation ||
        oldWidget.selectedLocation != widget.selectedLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _emitPreview());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _detailsController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _emitPreview() {
    widget.onPreviewChanged(LostPetDraftPreview(location: _effectiveLocation));
  }

  Future<void> _pickPhoto() async {
    setState(() {
      _isPickingPhoto = true;
      _saveErrorText = null;
    });

    try {
      final String? storedPath = await ref
          .read(localMediaStorageServiceProvider)
          .pickAndStoreLostPetPhoto();
      if (!mounted) {
        return;
      }
      setState(() {
        _storedPhotoUrl = storedPath;
        _photoErrorText = null;
        _submitValidationErrorText = null;
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
      initialDate: _disappearanceDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year, now.month, now.day),
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _disappearanceDate = picked;
    });
  }

  Future<void> _save() async {
    final LatLng? resolvedLocation = _effectiveLocation;

    setState(() {
      _locationErrorText = null;
      _nameErrorText = null;
      _detailsErrorText = null;
      _phoneErrorText = null;
      _photoErrorText = null;
      _submitValidationErrorText = null;
      _saveErrorText = null;
    });

    if (resolvedLocation == null) {
      setState(() {
        _locationErrorText =
            'Necesitamos una ubicación valida para reportar la mascota perdida.';
      });
    }

    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _nameErrorText = 'El nombre es obligatorio.';
      });
    }

    if (_detailsController.text.trim().isEmpty) {
      setState(() {
        _detailsErrorText = 'Los detalles son obligatorios.';
      });
    }

    if (_phoneController.text.trim().isEmpty) {
      setState(() {
        _phoneErrorText = 'El telefono es obligatorio.';
      });
    }

    if (_storedPhotoUrl == null || _storedPhotoUrl!.trim().isEmpty) {
      setState(() {
        _photoErrorText = 'La foto es obligatoria.';
      });
    }

    if (_locationErrorText != null ||
        _nameErrorText != null ||
        _detailsErrorText != null ||
        _phoneErrorText != null ||
        _photoErrorText != null) {
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
          .read(lostPetReportsControllerProvider.notifier)
          .addLostPetReport(
            lastSeenLatitude: resolvedLocation!.latitude,
            lastSeenLongitude: resolvedLocation.longitude,
            name: _nameController.text.trim(),
            details: _detailsController.text.trim(),
            disappearanceDate: _disappearanceDate,
            photoUrl: _storedPhotoUrl!,
            phone: _phoneController.text.trim(),
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
                  title: 'Última ubicación vista',
                  subtitle: 'Selecciona donde fue vista por ultima vez.',
                  hasManualLocation: widget.selectedLocation != null,
                  hasCurrentLocation: widget.currentDeviceLocation != null,
                  errorText: locationError,
                  onStartSelection: widget.onStartMapSelection,
                  onUseCurrentLocation: widget.onUseCurrentLocation,
                ),
                const SizedBox(height: 10),
                ReportingLabeledField(
                  label: 'Nombre',
                  child: ReportingTextField(
                    isDarkMode: widget.isDarkMode,
                    controller: _nameController,
                    hintText: 'Nombre de la mascota',
                    errorText: _nameErrorText,
                    onChanged: (_) {
                      if (_nameErrorText != null) {
                        setState(() {
                          _nameErrorText = null;
                          _submitValidationErrorText = null;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                ReportingLabeledField(
                  label: 'Detalles',
                  child: ReportingTextField(
                    isDarkMode: widget.isDarkMode,
                    controller: _detailsController,
                    hintText: 'Senas particulares, collar, color, zona...',
                    maxLines: 3,
                    errorText: _detailsErrorText,
                    onChanged: (_) {
                      if (_detailsErrorText != null) {
                        setState(() {
                          _detailsErrorText = null;
                          _submitValidationErrorText = null;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                ReportingLabeledField(
                  label: 'Fecha de desaparicion',
                  child: ReportingDateField(
                    isDarkMode: widget.isDarkMode,
                    valueText: _formatDate(_disappearanceDate),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(height: 8),
                ReportingLabeledField(
                  label: 'Telefono',
                  child: ReportingTextField(
                    isDarkMode: widget.isDarkMode,
                    controller: _phoneController,
                    hintText: 'Numero de contacto',
                    errorText: _phoneErrorText,
                    keyboardType: TextInputType.phone,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9+\-\s()]'),
                      ),
                    ],
                    onChanged: (_) {
                      if (_phoneErrorText != null) {
                        setState(() {
                          _phoneErrorText = null;
                          _submitValidationErrorText = null;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                ReportingLabeledField(
                  label: 'Foto',
                  child: ReportingPhotoField(
                    isDarkMode: widget.isDarkMode,
                    photoSource: _storedPhotoUrl,
                    isBusy: _isPickingPhoto,
                    onPickPressed: _pickPhoto,
                    errorText: _photoErrorText,
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
          label: 'Reportar mascota perdida',
          isBusy: _isSaving,
          onPressed: _save,
          backgroundColor: AppPalette.reportYellow,
        ),
      ],
    );
  }
}
