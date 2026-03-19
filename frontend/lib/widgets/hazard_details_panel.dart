import 'package:flutter/material.dart';

import '../models/hazard_report_record.dart';
import '../theme/app_palette.dart';
import 'shared/local_image_widget.dart';

class HazardDetailsPanelContent extends StatelessWidget {
  final bool isDarkMode;
  final HazardReportRecord hazard;
  final VoidCallback onViewComments;

  const HazardDetailsPanelContent({
    super.key,
    required this.isDarkMode,
    required this.hazard,
    required this.onViewComments,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DetailsRow(
                    label: 'Radio de afectación',
                    value: '${hazard.impactRadiusMeters} m',
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 10),
                  _DetailsRow(
                    label: 'Categoría',
                    value: HazardReportRecord.categoryLabelFromCode(
                      hazard.categoryCode,
                    ),
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 10),
                  _DetailsRow(
                    label: 'Descripción',
                    value: hazard.narrativeDescription,
                    isDarkMode: isDarkMode,
                    maxLines: 6,
                  ),
                  const SizedBox(height: 10),
                  _DetailsRow(
                    label: 'Fecha de reporte',
                    value: _formatDateTime(hazard.reportedAt),
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 10),
                  _DetailsRow(
                    label: 'Duración aproximada',
                    value: HazardReportRecord.durationLabelFromCode(
                      hazard.estimatedDurationCode,
                    ),
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 10),
                  _DetailsRow(
                    label: 'Nivel de riesgo',
                    value: HazardReportRecord.riskLabelFromCode(
                      hazard.riskLevelCode,
                    ),
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Foto del peligro',
                    style: TextStyle(
                      color: AppPalette.textMutedDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _HazardPhotoPreview(
                    photoSource: hazard.evidencePhotoUrl,
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
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
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Reportado por: ${hazard.reportedByUsername}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppPalette.textMutedDark,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String year = dateTime.year.toString();
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

class _DetailsRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDarkMode;
  final int maxLines;

  const _DetailsRow({
    required this.label,
    required this.value,
    required this.isDarkMode,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = AppPalette.textPrimary(isDarkMode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppPalette.textMutedDark,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppPalette.fieldBackground(isDarkMode),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _HazardPhotoPreview extends StatelessWidget {
  final String? photoSource;
  final bool isDarkMode;

  const _HazardPhotoPreview({
    required this.photoSource,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border(isDarkMode)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: photoSource != null && photoSource!.isNotEmpty
            ? buildLocalImageWidget(
                source: photoSource,
                fit: BoxFit.cover,
                fallback: const _NoPhotoPlaceholder(),
                errorBuilder: (_, __, ___) => const _NoPhotoPlaceholder(),
              )
            : const _NoPhotoPlaceholder(),
      ),
    );
  }
}

class _NoPhotoPlaceholder extends StatelessWidget {
  const _NoPhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppPalette.placeholderGray,
      child: const Center(
        child: Text(
          'Sin foto',
          style: TextStyle(
            color: AppPalette.iconGray,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
