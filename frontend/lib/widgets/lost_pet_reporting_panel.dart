import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../models/pet_record.dart';
import '../providers/local_data_providers.dart';
import '../theme/app_palette.dart';
import 'location_picker_widget.dart';
import 'reporting_form_widgets.dart';
import 'shared/local_image_widget.dart';
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
  final PetRecord? selectedPet;
  final bool isSelectingOnMap;
  final VoidCallback onStartMapSelection;
  final VoidCallback onUseCurrentLocation;
  final ValueChanged<LostPetDraftPreview> onPreviewChanged;
  final VoidCallback onSelectPetPressed;
  final VoidCallback onViewFoundReportsPressed;
  final VoidCallback onReported;

  const LostPetReportingPanelContent({
    super.key,
    required this.isDarkMode,
    required this.currentDeviceLocation,
    required this.currentLocationErrorText,
    required this.selectedLocation,
    required this.selectedPet,
    required this.isSelectingOnMap,
    required this.onStartMapSelection,
    required this.onUseCurrentLocation,
    required this.onPreviewChanged,
    required this.onSelectPetPressed,
    required this.onViewFoundReportsPressed,
    required this.onReported,
  });

  @override
  ConsumerState<LostPetReportingPanelContent> createState() =>
      _LostPetReportingPanelContentState();
}

class _LostPetReportingPanelContentState
    extends ConsumerState<LostPetReportingPanelContent> {
  late final TextEditingController _detailsController;
  late final TextEditingController _phoneController;
  late DateTime _disappearanceDate;
  bool _isSaving = false;
  String? _locationErrorText;
  String? _petErrorText;
  String? _detailsErrorText;
  String? _phoneErrorText;
  String? _submitValidationErrorText;
  String? _saveErrorText;

  LatLng? get _effectiveLocation {
    return widget.selectedLocation ?? widget.currentDeviceLocation;
  }

  @override
  void initState() {
    super.initState();
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
    if (oldWidget.selectedPet?.id != widget.selectedPet?.id &&
        _petErrorText != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _petErrorText = null;
          _submitValidationErrorText = null;
        });
      });
    }
  }

  @override
  void dispose() {
    _detailsController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _emitPreview() {
    widget.onPreviewChanged(LostPetDraftPreview(location: _effectiveLocation));
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

    if (picked == null || !mounted) return;
    setState(() => _disappearanceDate = picked);
  }

  Future<void> _save() async {
    final LatLng? resolvedLocation = _effectiveLocation;
    final PetRecord? selectedPet = widget.selectedPet;

    setState(() {
      _locationErrorText = null;
      _petErrorText = null;
      _detailsErrorText = null;
      _phoneErrorText = null;
      _submitValidationErrorText = null;
      _saveErrorText = null;
    });

    if (resolvedLocation == null) {
      _locationErrorText =
          'Necesitamos una ubicacion valida para reportar la mascota perdida.';
    }
    if (selectedPet == null) {
      _petErrorText = 'Selecciona la mascota perdida.';
    }
    if (_detailsController.text.trim().isEmpty) {
      _detailsErrorText = 'Los detalles son obligatorios.';
    }
    if (_phoneController.text.trim().isEmpty) {
      _phoneErrorText = 'El telefono es obligatorio.';
    }

    if (_locationErrorText != null ||
        _petErrorText != null ||
        _detailsErrorText != null ||
        _phoneErrorText != null) {
      setState(() {
        _submitValidationErrorText =
            'Completa los campos obligatorios para reportar.';
      });
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref
          .read(lostPetReportsControllerProvider.notifier)
          .addLostPetReport(
            petId: selectedPet!.id,
            petLocalUuid: selectedPet.localUuid,
            lastSeenLatitude: resolvedLocation!.latitude,
            lastSeenLongitude: resolvedLocation.longitude,
            details: _detailsController.text.trim(),
            disappearanceDate: _disappearanceDate,
            photoUrl: null,
            phone: _phoneController.text.trim(),
          );
      if (mounted) widget.onReported();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saveErrorText = _friendlySaveError(error);
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _friendlySaveError(Object error) {
    final String message = error.toString();
    if (message.contains('reporte activo')) {
      return 'Esta mascota ya tiene un reporte de perdida activo.';
    }
    if (message.contains('no existe localmente')) {
      return 'La mascota seleccionada no esta disponible. Seleccionala de nuevo.';
    }
    if (message.contains('persistir')) {
      return 'No se pudo guardar el reporte en este dispositivo. Intenta liberar espacio o recargar la app.';
    }
    return 'No se pudo guardar el reporte. Detalle: $message';
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
                  title: 'Ultima ubicacion vista',
                  subtitle: 'Selecciona donde fue vista por ultima vez.',
                  hasManualLocation: widget.selectedLocation != null,
                  hasCurrentLocation: widget.currentDeviceLocation != null,
                  errorText: locationError,
                  onStartSelection: widget.onStartMapSelection,
                  onUseCurrentLocation: widget.onUseCurrentLocation,
                ),
                const SizedBox(height: 8),
                ReportingSecondaryButton(
                  isDarkMode: widget.isDarkMode,
                  label: 'Ver mascotas encontradas',
                  onPressed: widget.onViewFoundReportsPressed,
                ),
                const SizedBox(height: 10),
                ReportingLabeledField(
                  label: 'Mascota',
                  child: _LostPetSelectionField(
                    isDarkMode: widget.isDarkMode,
                    selectedPet: widget.selectedPet,
                    errorText: _petErrorText,
                    onPressed: widget.onSelectPetPressed,
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

class _LostPetSelectionField extends StatelessWidget {
  final bool isDarkMode;
  final PetRecord? selectedPet;
  final String? errorText;
  final VoidCallback onPressed;

  const _LostPetSelectionField({
    required this.isDarkMode,
    required this.selectedPet,
    required this.errorText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReportingSelectionButton(
          isDarkMode: isDarkMode,
          label: selectedPet == null
              ? 'Seleccionar'
              : 'Mascota: ${selectedPet!.displayName}',
          onPressed: onPressed,
        ),
        if (selectedPet != null) ...[
          const SizedBox(height: 8),
          _SelectedPetPreview(isDarkMode: isDarkMode, pet: selectedPet!),
        ],
        if (errorText != null) ReportingFieldErrorText(message: errorText!),
      ],
    );
  }
}

class _SelectedPetPreview extends StatelessWidget {
  final bool isDarkMode;
  final PetRecord pet;

  const _SelectedPetPreview({required this.isDarkMode, required this.pet});

  @override
  Widget build(BuildContext context) {
    final Color background = AppPalette.cardBackground(isDarkMode);
    final Color border = AppPalette.border(isDarkMode);
    final Color textColor = AppPalette.textPrimary(isDarkMode);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 54,
              height: 54,
              child: pet.photoPath != null && pet.photoPath!.isNotEmpty
                  ? buildLocalImageWidget(
                      source: pet.photoPath,
                      fit: BoxFit.cover,
                      fallback: const _SelectedPetPlaceholder(),
                      errorBuilder: (_, _, _) =>
                          const _SelectedPetPlaceholder(),
                    )
                  : const _SelectedPetPlaceholder(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              pet.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedPetPlaceholder extends StatelessWidget {
  const _SelectedPetPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppPalette.placeholderGray,
      alignment: Alignment.center,
      child: const Icon(Icons.pets, color: AppPalette.iconGray, size: 24),
    );
  }
}
