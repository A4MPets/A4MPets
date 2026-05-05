import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/found_pet_report_record.dart';
import '../models/lost_pet_report_record.dart';
import '../models/pet_record.dart';
import '../theme/app_palette.dart';
import 'reporting_form_widgets.dart';
import 'shared/local_image_widget.dart';
import 'shared/panel_scroll_view.dart';

class FoundPetReportsListPanelContent extends StatelessWidget {
  final bool isDarkMode;
  final List<FoundPetReportRecord> reports;
  final List<PetRecord> pets;
  final List<LostPetReportRecord> lostPetReports;
  final ValueChanged<LatLng> onGoToLocation;

  const FoundPetReportsListPanelContent({
    super.key,
    required this.isDarkMode,
    required this.reports,
    required this.pets,
    required this.lostPetReports,
    required this.onGoToLocation,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = AppPalette.textPrimary(isDarkMode);
    final Map<String, PetRecord> petsByUuid = <String, PetRecord>{
      for (final PetRecord pet in pets)
        if (pet.localUuid.isNotEmpty) pet.localUuid: pet,
    };
    final Map<int, PetRecord> petsById = <int, PetRecord>{
      for (final PetRecord pet in pets) pet.id: pet,
    };
    final Map<String, LostPetReportRecord> lostReportsByPetUuid =
        <String, LostPetReportRecord>{
          for (final LostPetReportRecord report in lostPetReports)
            if (report.petLocalUuid.isNotEmpty) report.petLocalUuid: report,
        };
    final Map<int, LostPetReportRecord> lostReportsByPetId =
        <int, LostPetReportRecord>{
          for (final LostPetReportRecord report in lostPetReports)
            if (report.petId != null) report.petId!: report,
        };
    final Map<int, LostPetReportRecord> lostReportsById =
        <int, LostPetReportRecord>{
          for (final LostPetReportRecord report in lostPetReports)
            report.id: report,
        };
    final Map<String, LostPetReportRecord> lostReportsByRemoteId =
        <String, LostPetReportRecord>{
          for (final LostPetReportRecord report in lostPetReports)
            if (report.remoteId != null && report.remoteId!.trim().isNotEmpty)
              report.remoteId!: report,
        };
    return PanelScrollView(
      child: reports.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No hay mascotas encontradas',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : Column(
              children: reports
                  .map((FoundPetReportRecord report) {
                    final bool hasPetLocalUuid =
                        (report.petLocalUuid ?? '').isNotEmpty;
                    final LostPetReportRecord? matchedLostPetReport =
                        !hasPetLocalUuid
                        ? (report.matchedLostPetReportId == null
                              ? null
                              : lostReportsById[report
                                        .matchedLostPetReportId!] ??
                                    lostReportsByRemoteId[report
                                        .matchedLostPetReportId!
                                        .toString()])
                        : lostReportsByPetUuid[report.petLocalUuid!] ??
                              (report.matchedLostPetReportId == null
                                  ? null
                                  : lostReportsById[report
                                            .matchedLostPetReportId!] ??
                                        lostReportsByRemoteId[report
                                            .matchedLostPetReportId!
                                            .toString()]);
                    final PetRecord? matchedPet = !hasPetLocalUuid
                        ? (report.petId == null
                              ? null
                              : petsById[report.petId!])
                        : petsByUuid[report.petLocalUuid!] ??
                              (matchedLostPetReport == null
                                  ? (report.petId == null
                                        ? null
                                        : petsById[report.petId!])
                                  : petsByUuid[matchedLostPetReport
                                            .petLocalUuid] ??
                                        (matchedLostPetReport.petId == null
                                            ? null
                                            : petsById[matchedLostPetReport
                                                  .petId!]));
                    final LostPetReportRecord? resolvedLostPetReport =
                        matchedLostPetReport ??
                        (report.petId == null
                            ? null
                            : lostReportsByPetId[report.petId!]);
                    return _FoundReportCard(
                      isDarkMode: isDarkMode,
                      report: report,
                      pet: matchedPet,
                      matchedLostPetReport: resolvedLostPetReport,
                      onGoToLocation: onGoToLocation,
                    );
                  })
                  .toList(growable: false),
            ),
    );
  }
}

class _FoundReportCard extends StatelessWidget {
  final bool isDarkMode;
  final FoundPetReportRecord report;
  final PetRecord? pet;
  final LostPetReportRecord? matchedLostPetReport;
  final ValueChanged<LatLng> onGoToLocation;

  const _FoundReportCard({
    required this.isDarkMode,
    required this.report,
    required this.pet,
    required this.matchedLostPetReport,
    required this.onGoToLocation,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = AppPalette.textPrimary(isDarkMode);
    final Color borderColor = AppPalette.border(isDarkMode);
    final String? petPhoto = pet?.photoPath ?? report.petPhotoUrl;
    final String? reportPhoto = report.photoUrl;
    final bool showPetPhoto = petPhoto != null && petPhoto.trim().isNotEmpty;
    final bool showReportPhoto =
        reportPhoto != null && reportPhoto.trim().isNotEmpty;
    final String petName = pet?.displayName ?? 'Mascota sin nombre';

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
          if (showPetPhoto) ...[
            _FoundReportImage(title: 'Foto de la mascota', source: petPhoto),
            const SizedBox(height: 8),
          ],
          if (!showPetPhoto) ...[
            const SizedBox(height: 156, child: _ImageFallback()),
            const SizedBox(height: 8),
          ],
          Text(
            'Mascota encontrada',
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            petName,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatDate(report.foundDate),
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
          if (pet != null) ...[
            const SizedBox(height: 8),
            _FoundPetInfoSummary(
              isDarkMode: isDarkMode,
              pet: pet!,
              matchedLostPetReport: matchedLostPetReport,
            ),
          ],
          if (report.phone != null && report.phone!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Telefono: ${report.phone}',
              style: TextStyle(color: textColor),
            ),
          ],
          if (showReportPhoto) ...[
            const SizedBox(height: 8),
            _FoundReportImage(title: 'Foto del reporte', source: reportPhoto),
          ],
          const SizedBox(height: 10),
          ReportingSecondaryButton(
            isDarkMode: isDarkMode,
            label: 'Ir a ubicación',
            onPressed: () =>
                onGoToLocation(LatLng(report.latitude, report.longitude)),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _FoundPetInfoSummary extends StatelessWidget {
  final bool isDarkMode;
  final PetRecord pet;
  final LostPetReportRecord? matchedLostPetReport;

  const _FoundPetInfoSummary({
    required this.isDarkMode,
    required this.pet,
    required this.matchedLostPetReport,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = AppPalette.textPrimary(isDarkMode);
    final Color borderColor = AppPalette.border(isDarkMode);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppPalette.fieldBackground(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información de la mascota',
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nombre: ${pet.displayName}',
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Paseos: ${pet.totalWalks}',
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'Registro: ${_formatDate(pet.registeredAt)}',
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (pet.adoptionDate != null)
            Text(
              'Adopcion: ${_formatDate(pet.adoptionDate!)}',
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          if (pet.birthDate != null)
            Text(
              'Nacimiento: ${_formatDate(pet.birthDate!)}',
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          if (matchedLostPetReport != null) ...[
            const SizedBox(height: 6),
            Text(
              'Reporte de perdida: ${_formatDate(matchedLostPetReport!.disappearanceDate)}',
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if ((matchedLostPetReport!.phone ?? '').trim().isNotEmpty)
              Text(
                'Contacto previo: ${matchedLostPetReport!.phone}',
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _FoundReportImage extends StatelessWidget {
  final String title;
  final String source;

  const _FoundReportImage({required this.title, required this.source});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppPalette.textMutedDark,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 156,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: buildLocalImageWidget(
              source: source,
              fit: BoxFit.cover,
              fallback: const _ImageFallback(),
              errorBuilder: (_, _, _) => const _ImageFallback(),
            ),
          ),
        ),
      ],
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
