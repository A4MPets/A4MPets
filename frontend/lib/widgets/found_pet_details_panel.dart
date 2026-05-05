import 'package:flutter/material.dart';

import '../models/found_pet_report_record.dart';
import '../models/lost_pet_report_record.dart';
import '../models/pet_record.dart';
import '../theme/app_palette.dart';
import 'shared/image_preview_dialog.dart';
import 'shared/local_image_widget.dart';
import 'shared/panel_scroll_view.dart';

class FoundPetDetailsPanelContent extends StatelessWidget {
  final bool isDarkMode;
  final FoundPetReportRecord report;
  final PetRecord? pet;
  final LostPetReportRecord? matchedLostPetReport;
  final VoidCallback? onViewMatchedLostReport;
  final VoidCallback onViewComments;
  final String? debugDeleteLabel;
  final VoidCallback? onDebugDelete;

  const FoundPetDetailsPanelContent({
    super.key,
    required this.isDarkMode,
    required this.report,
    required this.pet,
    required this.matchedLostPetReport,
    required this.onViewMatchedLostReport,
    required this.onViewComments,
    this.debugDeleteLabel,
    this.onDebugDelete,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = AppPalette.textPrimary(isDarkMode);
    final PetRecord? selectedPet = pet;
    final LostPetReportRecord? linkedLostPetReport = matchedLostPetReport;
    final String? petImageSource =
        selectedPet?.photoPath ?? report.petPhotoUrl ?? report.photoUrl;
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
                        ? ExpandableImage(
                            source: petImageSource,
                            isDarkMode: isDarkMode,
                            title: petName,
                            child: buildLocalImageWidget(
                              source: petImageSource,
                              fit: BoxFit.cover,
                              fallback: const _ImageFallback(),
                              errorBuilder: (_, _, _) => const _ImageFallback(),
                            ),
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
                if (selectedPet != null) ...[
                  _DetailsRow(
                    label: 'Nombre',
                    value: petName,
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
                      label: 'Fecha de adopción',
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
                  const SizedBox(height: 12),
                  _LinkedLostPetReportCard(
                    isDarkMode: isDarkMode,
                    report: linkedLostPetReport,
                    pet: selectedPet,
                    onPressed: onViewMatchedLostReport,
                  ),
                ],
                if (showReportImage && reportImageSource != petImageSource) ...[
                  const SizedBox(height: 12),
                  _FoundImageSection(
                    title: 'Foto del reporte',
                    source: reportImageSource,
                    isDarkMode: isDarkMode,
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

class _LinkedLostPetReportCard extends StatelessWidget {
  final bool isDarkMode;
  final LostPetReportRecord report;
  final PetRecord? pet;
  final VoidCallback? onPressed;

  const _LinkedLostPetReportCard({
    required this.isDarkMode,
    required this.report,
    required this.pet,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = AppPalette.textPrimary(isDarkMode);
    final String? photoSource =
        pet?.photoPath ?? report.petPhotoUrl ?? report.photoUrl;
    final bool hasPhoto = photoSource != null && photoSource.trim().isNotEmpty;

    return Material(
      color: AppPalette.cardBackground(isDarkMode),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppPalette.border(isDarkMode)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: hasPhoto
                      ? buildLocalImageWidget(
                          source: photoSource,
                          fit: BoxFit.cover,
                          fallback: const _ImageFallback(),
                          errorBuilder: (_, _, _) => const _ImageFallback(),
                        )
                      : const _ImageFallback(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet?.displayName ?? 'Mascota perdida',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reporte de perdida: ${FoundPetDetailsPanelContent._formatDate(report.disappearanceDate)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDarkMode
                            ? AppPalette.textMutedDark
                            : AppPalette.iconGray,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.details,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: AppPalette.textPrimary(isDarkMode),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
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
  final bool isDarkMode;

  const _FoundImageSection({
    required this.title,
    required this.source,
    required this.isDarkMode,
  });

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
            child: ExpandableImage(
              source: source,
              isDarkMode: isDarkMode,
              title: title,
              child: buildLocalImageWidget(
                source: source,
                fit: BoxFit.cover,
                fallback: const _ImageFallback(),
                errorBuilder: (_, _, _) => const _ImageFallback(),
              ),
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
