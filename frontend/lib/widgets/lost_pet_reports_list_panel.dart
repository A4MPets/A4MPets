import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/lost_pet_report_record.dart';
import '../models/pet_record.dart';
import '../theme/app_palette.dart';
import 'reporting_form_widgets.dart';
import 'shared/local_image_widget.dart';
import 'shared/panel_scroll_view.dart';

class LostPetReportsListPanelContent extends StatefulWidget {
  final bool isDarkMode;
  final List<LostPetReportRecord> reports;
  final List<PetRecord> pets;
  final ValueChanged<LostPetReportRecord>? onSelectReport;
  final ValueChanged<LatLng> onGoToLocation;

  const LostPetReportsListPanelContent({
    super.key,
    required this.isDarkMode,
    required this.reports,
    required this.pets,
    this.onSelectReport,
    required this.onGoToLocation,
  });

  @override
  State<LostPetReportsListPanelContent> createState() =>
      _LostPetReportsListPanelContentState();
}

class _LostPetReportsListPanelContentState
    extends State<LostPetReportsListPanelContent> {
  final TextEditingController _queryController = TextEditingController();
  DateTime? _fromDate;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showReportingDatePicker(
      context: context,
      isDarkMode: widget.isDarkMode,
      initialDate: _fromDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked != null) setState(() => _fromDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = AppPalette.textPrimary(widget.isDarkMode);
    final Map<String, PetRecord> petsByUuid = <String, PetRecord>{
      for (final PetRecord pet in widget.pets) pet.localUuid: pet,
    };
    final Map<int, PetRecord> petsById = <int, PetRecord>{
      for (final PetRecord pet in widget.pets) pet.id: pet,
    };
    final List<String> tokens = _queryController.text
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((String token) => token.trim().isNotEmpty)
        .toList(growable: false);
    final List<LostPetReportRecord> visible = widget.reports
        .where((report) {
          if (_fromDate != null &&
              report.disappearanceDate.isBefore(_fromDate!)) {
            return false;
          }
          final String haystack = report.details.toLowerCase();
          return tokens.every(haystack.contains);
        })
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReportingTextField(
          isDarkMode: widget.isDarkMode,
          controller: _queryController,
          onChanged: (_) => setState(() {}),
          hintText: 'Buscar caracteristicas',
        ),
        const SizedBox(height: 8),
        ReportingDateField(
          isDarkMode: widget.isDarkMode,
          valueText: _fromDate == null
              ? 'Filtrar por fecha'
              : 'Desde: ${_formatDate(_fromDate!)}',
          onTap: _pickDate,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: PanelScrollView(
            child: visible.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No hay mascotas perdidas',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : Column(
                    children: visible
                        .map((LostPetReportRecord report) {
                          final PetRecord? pet = report.petId == null
                              ? petsByUuid[report.petLocalUuid]
                              : petsById[report.petId!] ??
                                    petsByUuid[report.petLocalUuid];
                          return _LostReportCard(
                            isDarkMode: widget.isDarkMode,
                            report: report,
                            pet: pet,
                            onSelectReport: widget.onSelectReport,
                            onGoToLocation: widget.onGoToLocation,
                          );
                        })
                        .toList(growable: false),
                  ),
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _LostReportCard extends StatelessWidget {
  final bool isDarkMode;
  final LostPetReportRecord report;
  final PetRecord? pet;
  final ValueChanged<LostPetReportRecord>? onSelectReport;
  final ValueChanged<LatLng> onGoToLocation;

  const _LostReportCard({
    required this.isDarkMode,
    required this.report,
    required this.pet,
    required this.onSelectReport,
    required this.onGoToLocation,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = AppPalette.textPrimary(isDarkMode);
    final Color borderColor = AppPalette.border(isDarkMode);
    final String? photo =
        pet?.photoPath ?? report.petPhotoUrl ?? report.photoUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.cardBackground(isDarkMode),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 156,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: photo == null || photo.isEmpty
                  ? const _ImageFallback()
                  : buildLocalImageWidget(
                      source: photo,
                      fit: BoxFit.cover,
                      fallback: const _ImageFallback(),
                      errorBuilder: (_, _, _) => const _ImageFallback(),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pet?.displayName ?? 'Mascota perdida',
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _LostPetReportsListPanelContentState._formatDate(
              report.disappearanceDate,
            ),
            style: const TextStyle(
              color: AppPalette.textMutedDark,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            report.details,
            style: TextStyle(color: textColor, fontSize: 13),
          ),
          if (report.phone != null && report.phone!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Telefono: ${report.phone}',
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ReportingSecondaryButton(
                  isDarkMode: isDarkMode,
                  label: 'Ubicacion',
                  onPressed: () => onGoToLocation(
                    LatLng(report.lastSeenLatitude, report.lastSeenLongitude),
                  ),
                ),
              ),
              if (onSelectReport != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ReportingPrimaryButton(
                    label: 'Seleccionar',
                    isBusy: false,
                    onPressed: () => onSelectReport!(report),
                    backgroundColor: AppPalette.primaryBlue,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppPalette.placeholderGray,
      alignment: Alignment.center,
      child: const Icon(Icons.pets, color: AppPalette.iconGray, size: 42),
    );
  }
}
