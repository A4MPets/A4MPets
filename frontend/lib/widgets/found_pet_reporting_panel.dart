import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../models/lost_pet_report_record.dart';
import '../models/pet_record.dart';
import '../providers/local_data_providers.dart';
import '../theme/app_palette.dart';
import 'location_picker_widget.dart';
import 'reporting_form_widgets.dart';
import 'reporting_panel_state.dart';
import 'shared/local_image_widget.dart';

class FoundPetDraftPreview {
  final LatLng? location;

  const FoundPetDraftPreview({required this.location});
}

class FoundPetReportingPanelContent extends ConsumerStatefulWidget {
  final bool isDarkMode;
  final LatLng? currentDeviceLocation;
  final String? currentLocationErrorText;
  final LatLng? selectedLocation;
  final bool isSelectingOnMap;
  final VoidCallback onStartMapSelection;
  final VoidCallback onUseCurrentLocation;
  final ValueChanged<FoundPetDraftPreview> onPreviewChanged;
  final LostPetReportRecord? selectedLostPetReport;
  final PetRecord? selectedLostPet;
  final VoidCallback onViewLostReportsPressed;
  final VoidCallback onReported;

  const FoundPetReportingPanelContent({
    super.key,
    required this.isDarkMode,
    required this.currentDeviceLocation,
    required this.currentLocationErrorText,
    required this.selectedLocation,
    required this.isSelectingOnMap,
    required this.onStartMapSelection,
    required this.onUseCurrentLocation,
    required this.onPreviewChanged,
    required this.selectedLostPetReport,
    required this.selectedLostPet,
    required this.onViewLostReportsPressed,
    required this.onReported,
  });

  @override
  ConsumerState<FoundPetReportingPanelContent> createState() => _FoundPetReportingPanelContentState();
}

class _FoundPetReportingPanelContentState extends ConsumerState<FoundPetReportingPanelContent>
    with ReportingPanelState<FoundPetReportingPanelContent> {
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  DateTime _foundDate = DateTime.now();
  String? _detailsErrorText;

  LatLng? get _effectiveLocation {
    return effectiveReportLocation(widget.selectedLocation, widget.currentDeviceLocation);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _emitPreview());
  }

  @override
  void didUpdateWidget(covariant FoundPetReportingPanelContent oldWidget) {
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
    _detailsController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _emitPreview() {
    widget.onPreviewChanged(FoundPetDraftPreview(location: _effectiveLocation));
  }

  Future<void> _pickPhoto() => pickReportPhoto((service) => service.pickAndStoreFoundPetPhoto());

  Future<void> _pickDate() async {
    await pickReportDate(
      isDarkMode: widget.isDarkMode,
      initialDate: _foundDate,
      onPicked: (DateTime value) => _foundDate = value,
    );
  }

  Future<void> _save() async {
    final LatLng? resolvedLocation = _effectiveLocation;

    resetReportErrors(() {
      _detailsErrorText = null;
    });

    if (resolvedLocation == null) {
      locationErrorText = 'Necesitamos una ubicación valida para reportar la mascota encontrada.';
    }

    if (_detailsController.text.trim().isEmpty) _detailsErrorText = 'Los detalles son obligatorios.';

    if (locationErrorText != null || _detailsErrorText != null) {
      setSubmitValidationError();
      return;
    }

    await runReportSave(() async {
      final LostPetReportRecord? selectedReport = widget.selectedLostPetReport;
      final String selectedPetLocalUuid = widget.selectedLostPet?.localUuid ?? selectedReport?.petLocalUuid ?? '';

      await ref
          .read(foundPetReportsControllerProvider.notifier)
          .addFoundPetReport(
            petId: widget.selectedLostPet?.id ?? selectedReport?.petId,
            petLocalUuid: selectedPetLocalUuid.trim().isEmpty ? null : selectedPetLocalUuid,
            matchedLostPetReportId: selectedReport?.id,
            latitude: resolvedLocation!.latitude,
            longitude: resolvedLocation.longitude,
            details: _detailsController.text.trim(),
            foundDate: _foundDate,
            photoUrl: storedPhotoUrl,
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          );

      if (mounted) widget.onReported();
    }, errorMessage: _saveFailureMessage);
  }

  String _saveFailureMessage(Object error) {
    final String message = error.toString().replaceFirst('Exception: ', '');
    if (message.trim().isEmpty) return 'No se pudo guardar el reporte. Intenta nuevamente.';
    if (message.contains('Debes iniciar sesion')) return 'Debes iniciar sesion para reportar una mascota encontrada.';
    return 'No se pudo guardar el reporte. Detalle: $message';
  }

  @override
  Widget build(BuildContext context) {
    final String? locationError = resolvedLocationError(
      currentLocationErrorText: widget.currentLocationErrorText,
      hasManualLocation: widget.selectedLocation != null,
    );

    return ReportingPanelScaffold(
      submitLabel: 'Reportar mascota encontrada',
      isBusy: isSaving,
      onSubmit: _save,
      submitColor: AppPalette.reportGreen,
      submitValidationErrorText: submitValidationErrorText,
      children: [
        LocationPickerWidget(
          isDarkMode: widget.isDarkMode,
          title: 'Ubicación encontrada',
          subtitle: 'Selecciona el lugar donde encontraste la mascota.',
          hasManualLocation: widget.selectedLocation != null,
          hasCurrentLocation: widget.currentDeviceLocation != null,
          errorText: locationError,
          onStartSelection: widget.onStartMapSelection,
          onUseCurrentLocation: widget.onUseCurrentLocation,
        ),
        const SizedBox(height: 8),
        _FoundLostPetSelectionField(
          isDarkMode: widget.isDarkMode,
          selectedLostPetReport: widget.selectedLostPetReport,
          selectedLostPet: widget.selectedLostPet,
          onPressed: widget.onViewLostReportsPressed,
        ),
        const SizedBox(height: 10),
        ReportingLabeledField(
          label: 'Detalles',
          child: ReportingTextField(
            isDarkMode: widget.isDarkMode,
            controller: _detailsController,
            hintText: 'Describe la mascota y el contexto',
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
          label: 'Fecha',
          child: ReportingDateField(
            isDarkMode: widget.isDarkMode,
            valueText: formatReportingDate(_foundDate),
            onTap: _pickDate,
          ),
        ),
        const SizedBox(height: 8),
        ReportingLabeledField(
          label: 'Telefono (opcional)',
          child: ReportingTextField(
            isDarkMode: widget.isDarkMode,
            controller: _phoneController,
            hintText: 'Numero de contacto',
            keyboardType: TextInputType.phone,
            inputFormatters: reportingPhoneInputFormatters,
          ),
        ),
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

class _FoundLostPetSelectionField extends StatelessWidget {
  final bool isDarkMode;
  final LostPetReportRecord? selectedLostPetReport;
  final PetRecord? selectedLostPet;
  final VoidCallback onPressed;

  const _FoundLostPetSelectionField({
    required this.isDarkMode,
    required this.selectedLostPetReport,
    required this.selectedLostPet,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReportingSelectionButton(
          isDarkMode: isDarkMode,
          label: selectedLostPetReport == null
              ? 'Seleccionar mascota perdida'
              : 'Mascota perdida: ${selectedLostPet?.displayName ?? 'Seleccionada'}',
          onPressed: onPressed,
        ),
        if (selectedLostPetReport != null) ...[
          const SizedBox(height: 8),
          _SelectedLostPetPreview(isDarkMode: isDarkMode, report: selectedLostPetReport!, pet: selectedLostPet),
        ],
      ],
    );
  }
}

class _SelectedLostPetPreview extends StatelessWidget {
  final bool isDarkMode;
  final LostPetReportRecord report;
  final PetRecord? pet;

  const _SelectedLostPetPreview({required this.isDarkMode, required this.report, required this.pet});

  @override
  Widget build(BuildContext context) {
    final Color background = AppPalette.cardBackground(isDarkMode);
    final Color border = AppPalette.border(isDarkMode);
    final Color textColor = AppPalette.textPrimary(isDarkMode);
    final String? photoSource = pet?.photoPath ?? report.photoUrl;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 54,
              height: 54,
              child: photoSource != null && photoSource.isNotEmpty
                  ? buildLocalImageWidget(
                      source: photoSource,
                      fit: BoxFit.cover,
                      fallback: const _SelectedLostPetPlaceholder(),
                      errorBuilder: (_, _, _) => const _SelectedLostPetPlaceholder(),
                    )
                  : const _SelectedLostPetPlaceholder(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet?.displayName ?? 'Mascota perdida seleccionada',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  formatReportingDate(report.disappearanceDate),
                  style: const TextStyle(color: AppPalette.textMutedDark, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  report.details,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedLostPetPlaceholder extends StatelessWidget {
  const _SelectedLostPetPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppPalette.placeholderGray,
      alignment: Alignment.center,
      child: const Icon(Icons.pets, color: AppPalette.iconGray, size: 24),
    );
  }
}
