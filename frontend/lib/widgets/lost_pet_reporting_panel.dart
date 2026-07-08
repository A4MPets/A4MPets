import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../models/pet_record.dart';
import '../providers/local_data_providers.dart';
import '../theme/app_palette.dart';
import 'location_picker_widget.dart';
import 'reporting_form_widgets.dart';
import 'reporting_panel_state.dart';
import 'shared/local_image_widget.dart';

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
  ConsumerState<LostPetReportingPanelContent> createState() => _LostPetReportingPanelContentState();
}

class _LostPetReportingPanelContentState extends ConsumerState<LostPetReportingPanelContent>
    with ReportingPanelState<LostPetReportingPanelContent> {
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  DateTime _disappearanceDate = DateTime.now();
  String? _petErrorText;
  String? _detailsErrorText;
  String? _phoneErrorText;

  LatLng? get _effectiveLocation {
    return effectiveReportLocation(widget.selectedLocation, widget.currentDeviceLocation);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _emitPreview());
  }

  @override
  void didUpdateWidget(covariant LostPetReportingPanelContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    emitPreviewWhenLocationChanges(
      oldWidget.currentDeviceLocation,
      widget.currentDeviceLocation,
      oldWidget.selectedLocation,
      widget.selectedLocation,
      _emitPreview,
    );
    if (oldWidget.selectedPet?.id != widget.selectedPet?.id && _petErrorText != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _petErrorText = null;
          submitValidationErrorText = null;
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
    await pickReportDate(
      isDarkMode: widget.isDarkMode,
      initialDate: _disappearanceDate,
      onPicked: (DateTime value) => _disappearanceDate = value,
    );
  }

  Future<void> _save() async {
    final LatLng? resolvedLocation = _effectiveLocation;
    final PetRecord? selectedPet = widget.selectedPet;

    resetReportErrors(() {
      _petErrorText = null;
      _detailsErrorText = null;
      _phoneErrorText = null;
    });

    if (resolvedLocation == null) {
      locationErrorText = 'Necesitamos una ubicación valida para reportar la mascota perdida.';
    }
    if (selectedPet == null) _petErrorText = 'Selecciona la mascota perdida.';
    if (_detailsController.text.trim().isEmpty) _detailsErrorText = 'Los detalles son obligatorios.';
    if (_phoneController.text.trim().isEmpty) _phoneErrorText = 'El telefono es obligatorio.';

    if (locationErrorText != null || _petErrorText != null || _detailsErrorText != null || _phoneErrorText != null) {
      setSubmitValidationError();
      return;
    }

    await runReportSave(() async {
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
    }, errorMessage: _friendlySaveError);
  }

  String _friendlySaveError(Object error) {
    final String message = error.toString();
    if (message.contains('reporte activo')) return 'Esta mascota ya tiene un reporte de perdida activo.';
    if (message.contains('no existe localmente'))
      return 'La mascota seleccionada no esta disponible. Seleccionala de nuevo.';
    if (message.contains('persistir'))
      return 'No se pudo guardar el reporte en este dispositivo. Intenta liberar espacio o recargar la app.';
    return 'No se pudo guardar el reporte. Detalle: $message';
  }

  @override
  Widget build(BuildContext context) {
    final String? locationError = resolvedLocationError(
      currentLocationErrorText: widget.currentLocationErrorText,
      hasManualLocation: widget.selectedLocation != null,
    );

    return ReportingPanelScaffold(
      submitLabel: 'Reportar mascota perdida',
      isBusy: isSaving,
      onSubmit: _save,
      submitColor: AppPalette.reportYellow,
      submitValidationErrorText: submitValidationErrorText,
      children: [
        LocationPickerWidget(
          isDarkMode: widget.isDarkMode,
          title: 'Ultima ubicación vista',
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
                  submitValidationErrorText = null;
                });
              }
            },
          ),
        ),
        const SizedBox(height: 8),
        ReportingLabeledField(
          label: 'Fecha de desaparición',
          child: ReportingDateField(
            isDarkMode: widget.isDarkMode,
            valueText: formatReportingDate(_disappearanceDate),
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
            inputFormatters: reportingPhoneInputFormatters,
            onChanged: (_) {
              if (_phoneErrorText != null) {
                setState(() {
                  _phoneErrorText = null;
                  submitValidationErrorText = null;
                });
              }
            },
          ),
        ),
        if (saveErrorText != null) ...[const SizedBox(height: 10), ReportingFieldErrorText(message: saveErrorText!)],
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
          label: selectedPet == null ? 'Seleccionar' : 'Mascota: ${selectedPet!.displayName}',
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
                      errorBuilder: (_, _, _) => const _SelectedPetPlaceholder(),
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
              style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w700),
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
