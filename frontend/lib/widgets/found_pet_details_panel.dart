import 'package:flutter/material.dart';

import '../models/found_pet_report_record.dart';
import '../models/lost_pet_report_record.dart';
import '../models/pet_record.dart';
import '../theme/app_palette.dart';
import 'shared/panel_scroll_view.dart';
import 'shared/local_image_widget.dart';

class FoundPetDetailsPanelContent extends StatelessWidget {
  final bool isDarkMode;
  final FoundPetReportRecord report;
  final PetRecord? pet;
  final LostPetReportRecord? matchedLostPetReport;
  final VoidCallback onViewComments;
  final String? debugDeleteLabel;
  final VoidCallback? onDebugDelete;

  const FoundPetDetailsPanelContent({
    super.key,
    required this.isDarkMode,
    required this.report,
    required this.pet,
    required this.matchedLostPetReport,
    required this.onViewComments,
    this.debugDeleteLabel,
    this.onDebugDelete,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = AppPalette.textPrimary(isDarkMode);
    final PetRecord? selectedPet = pet;
    final LostPetReportRecord? linkedLostPetReport = matchedLostPetReport;
    final String? petImageSource = selectedPet?.photoPath;
    final String? reportImageSource = report.photoUrl;
    final bool showPetImage =
        petImageSource != null && petImageSource.trim().isNotEmpty;
    final bool showReportImage =
        reportImageSource != null && reportImageSource.trim().isNotEmpty;
    final String petName = selectedPet?.displayName ?? 'Mascota sin nombre';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: PanelScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: showPetImage
                        ? buildLocalImageWidget(
                            source: petImageSource,
                            fit: BoxFit.cover,
                            fallback: const _ImageFallback(),
                            errorBuilder: (_, _, _) => const _ImageFallback(),
                          )
                        : const _ImageFallback(),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Mascota encontrada',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  petName,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (selectedPet != null) ...[
                  _DetailsRow(
                    label: 'Nombre',
                    value: petName,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 8),
                  _DetailsRow(
                    label: 'Paseos completados',
                    value: '${selectedPet.totalWalks}',
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 8),
                  _DetailsRow(
                    label: 'Fecha de registro',
                    value: _formatDate(selectedPet.registeredAt),
                    isDarkMode: isDarkMode,
                  ),
                  if (selectedPet.adoptionDate != null) ...[
                    const SizedBox(height: 8),
                    _DetailsRow(
                      label: 'Fecha de adopcion',
                      value: _formatDate(selectedPet.adoptionDate!),
                      isDarkMode: isDarkMode,
                    ),
                  ],
                  if (selectedPet.birthDate != null) ...[
                    const SizedBox(height: 8),
                    _DetailsRow(
                      label: 'Fecha de nacimiento',
                      value: _formatDate(selectedPet.birthDate!),
                      isDarkMode: isDarkMode,
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
                _DetailsRow(
                  label: 'Fecha',
                  value: _formatDate(report.foundDate),
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 8),
                _DetailsRow(
                  label: 'Detalles',
                  value: report.details,
                  isDarkMode: isDarkMode,
                ),
                if (report.phone != null &&
                    report.phone!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _DetailsRow(
                    label: 'Telefono',
                    value: report.phone!,
                    isDarkMode: isDarkMode,
                  ),
                ],
                if (linkedLostPetReport != null) ...[
                  const SizedBox(height: 8),
                  _DetailsRow(
                    label: 'Perdida reportada',
                    value: _formatDate(linkedLostPetReport.disappearanceDate),
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 8),
                  _DetailsRow(
                    label: 'Detalles del reporte perdido',
                    value: linkedLostPetReport.details,
                    isDarkMode: isDarkMode,
                  ),
                  if ((linkedLostPetReport.phone ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _DetailsRow(
                      label: 'Telefono del reporte perdido',
                      value: linkedLostPetReport.phone!,
                      isDarkMode: isDarkMode,
                    ),
                  ],
                ],
                if (showReportImage) ...[
                  const SizedBox(height: 12),
                  _FoundImageSection(
                    title: 'Foto del reporte',
                    source: reportImageSource,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: onViewComments,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.placeholderGray,
              foregroundColor: AppPalette.charcoal,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Ver comentarios',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        if (onDebugDelete != null && debugDeleteLabel != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: OutlinedButton(
              onPressed: onDebugDelete,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppPalette.dangerRed,
                side: const BorderSide(color: AppPalette.dangerRed),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                debugDeleteLabel!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  static String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(color: AppPalette.placeholderGray);
  }
}

class _FoundImageSection extends StatelessWidget {
  final String title;
  final String source;

  const _FoundImageSection({required this.title, required this.source});

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
          height: 180,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
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

class _DetailsRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDarkMode;

  const _DetailsRow({
    required this.label,
    required this.value,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppPalette.textMutedDark,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: AppPalette.textPrimary(isDarkMode),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
