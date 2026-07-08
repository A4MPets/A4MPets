import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/found_pet_report_record.dart';
import '../models/lost_pet_report_record.dart';
import '../models/pet_record.dart';
import '../theme/app_palette.dart';
import 'reporting_form_widgets.dart';
import 'shared/panel_scroll_view.dart';
import 'shared/report_detail_widgets.dart';

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
    final Map<int, PetRecord> petsById = <int, PetRecord>{for (final PetRecord pet in pets) pet.id: pet};
    final Map<String, LostPetReportRecord> lostReportsByPetUuid = <String, LostPetReportRecord>{
      for (final LostPetReportRecord report in lostPetReports)
        if (report.petLocalUuid.isNotEmpty) report.petLocalUuid: report,
    };
    final Map<int, LostPetReportRecord> lostReportsByPetId = <int, LostPetReportRecord>{
      for (final LostPetReportRecord report in lostPetReports)
        if (report.petId != null) report.petId!: report,
    };
    final Map<int, LostPetReportRecord> lostReportsById = <int, LostPetReportRecord>{
      for (final LostPetReportRecord report in lostPetReports) report.id: report,
    };
    final Map<String, LostPetReportRecord> lostReportsByRemoteId = <String, LostPetReportRecord>{
      for (final LostPetReportRecord report in lostPetReports)
        if (report.remoteId != null && report.remoteId!.trim().isNotEmpty) report.remoteId!: report,
    };
    return PanelScrollView(
      child: reports.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No hay mascotas encontradas',
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            )
          : Column(
              children: reports
                  .map((FoundPetReportRecord report) {
                    final bool hasPetLocalUuid = (report.petLocalUuid ?? '').isNotEmpty;
                    final LostPetReportRecord? matchedLostPetReport = !hasPetLocalUuid
                        ? (report.matchedLostPetReportId == null
                              ? null
                              : lostReportsById[report.matchedLostPetReportId!] ??
                                    lostReportsByRemoteId[report.matchedLostPetReportId!.toString()])
                        : lostReportsByPetUuid[report.petLocalUuid!] ??
                              (report.matchedLostPetReportId == null
                                  ? null
                                  : lostReportsById[report.matchedLostPetReportId!] ??
                                        lostReportsByRemoteId[report.matchedLostPetReportId!.toString()]);
                    final PetRecord? matchedPet = !hasPetLocalUuid
                        ? (report.petId == null ? null : petsById[report.petId!])
                        : petsByUuid[report.petLocalUuid!] ??
                              (matchedLostPetReport == null
                                  ? (report.petId == null ? null : petsById[report.petId!])
                                  : petsByUuid[matchedLostPetReport.petLocalUuid] ??
                                        (matchedLostPetReport.petId == null
                                            ? null
                                            : petsById[matchedLostPetReport.petId!]));
                    final LostPetReportRecord? resolvedLostPetReport =
                        matchedLostPetReport ?? (report.petId == null ? null : lostReportsByPetId[report.petId!]);
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
    final bool showReportPhoto = reportPhoto != null && reportPhoto.trim().isNotEmpty;
    final String petName = pet?.displayName ?? 'Mascota sin nombre';
    Text primaryText(String text, {double size = 13, FontWeight weight = FontWeight.w500}) {
      return Text(
        text,
        style: TextStyle(color: textColor, fontSize: size, fontWeight: weight),
      );
    }

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
            ReportPhotoBlock(
              isDarkMode: isDarkMode,
              label: 'Foto de la mascota',
              source: petPhoto,
              fallbackIcon: Icons.pets,
              height: 156,
              imageBorderRadius: 12,
            ),
            const SizedBox(height: 8),
          ],
          if (!showPetPhoto) ...[
            const SizedBox(height: 156, child: ReportImageFallback(icon: Icons.pets)),
            const SizedBox(height: 8),
          ],
          primaryText('Mascota encontrada', size: 15, weight: FontWeight.w800),
          const SizedBox(height: 4),
          primaryText(petName, size: 14, weight: FontWeight.w700),
          const SizedBox(height: 6),
          Text(
            formatReportDate(report.foundDate),
            style: const TextStyle(color: AppPalette.textMutedDark, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          primaryText(report.details),
          if (pet != null) ...[
            const SizedBox(height: 8),
            _FoundPetInfoSummary(isDarkMode: isDarkMode, pet: pet!, matchedLostPetReport: matchedLostPetReport),
          ],
          if (report.phone != null && report.phone!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            primaryText('Telefono: ${report.phone}'),
          ],
          if (showReportPhoto) ...[
            const SizedBox(height: 8),
            ReportPhotoBlock(
              isDarkMode: isDarkMode,
              label: 'Foto del reporte',
              source: reportPhoto,
              fallbackIcon: Icons.pets,
              height: 156,
              imageBorderRadius: 12,
            ),
          ],
          const SizedBox(height: 10),
          ReportingSecondaryButton(
            isDarkMode: isDarkMode,
            label: 'Ir a ubicación',
            onPressed: () => onGoToLocation(LatLng(report.latitude, report.longitude)),
          ),
        ],
      ),
    );
  }
}

class _FoundPetInfoSummary extends StatelessWidget {
  final bool isDarkMode;
  final PetRecord pet;
  final LostPetReportRecord? matchedLostPetReport;

  const _FoundPetInfoSummary({required this.isDarkMode, required this.pet, required this.matchedLostPetReport});

  @override
  Widget build(BuildContext context) {
    final Color textColor = AppPalette.textPrimary(isDarkMode);
    final Color borderColor = AppPalette.border(isDarkMode);
    Text infoLine(String text, {double size = 12, FontWeight weight = FontWeight.w500}) {
      return Text(
        text,
        style: TextStyle(color: textColor, fontSize: size, fontWeight: weight),
      );
    }

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
          infoLine('Información de la mascota', size: 13, weight: FontWeight.w700),
          const SizedBox(height: 6),
          infoLine('Nombre: ${pet.displayName}', weight: FontWeight.w600),
          const SizedBox(height: 4),
          infoLine('Paseos: ${pet.totalWalks}'),
          infoLine('Registro: ${formatReportDate(pet.registeredAt)}'),
          if (pet.adoptionDate != null) infoLine('Adopcion: ${formatReportDate(pet.adoptionDate!)}'),
          if (pet.birthDate != null) infoLine('Nacimiento: ${formatReportDate(pet.birthDate!)}'),
          if (matchedLostPetReport != null) ...[
            const SizedBox(height: 6),
            infoLine(
              'Reporte de perdida: ${formatReportDate(matchedLostPetReport!.disappearanceDate)}',
              weight: FontWeight.w600,
            ),
            if ((matchedLostPetReport!.phone ?? '').trim().isNotEmpty)
              infoLine('Contacto previo: ${matchedLostPetReport!.phone}'),
          ],
        ],
      ),
    );
  }
}
