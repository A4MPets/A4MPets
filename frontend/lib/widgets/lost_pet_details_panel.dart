import 'package:flutter/material.dart';

import '../models/lost_pet_report_record.dart';
import '../theme/app_palette.dart';
import 'shared/panel_scroll_view.dart';
import 'shared/local_image_widget.dart';

class LostPetDetailsPanelContent extends StatelessWidget {
  final bool isDarkMode;
  final LostPetReportRecord report;
  final VoidCallback onViewComments;
  final String? debugDeleteLabel;
  final VoidCallback? onDebugDelete;

  const LostPetDetailsPanelContent({
    super.key,
    required this.isDarkMode,
    required this.report,
    required this.onViewComments,
    this.debugDeleteLabel,
    this.onDebugDelete,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = AppPalette.textPrimary(isDarkMode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: PanelScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (report.photoUrl != null && report.photoUrl!.isNotEmpty)
                  SizedBox(
                    height: 180,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: buildLocalImageWidget(
                        source: report.photoUrl,
                        fit: BoxFit.cover,
                        fallback: const _ImageFallback(),
                        errorBuilder: (_, _, _) => const _ImageFallback(),
                      ),
                    ),
                  ),
                if (report.photoUrl != null && report.photoUrl!.isNotEmpty)
                  const SizedBox(height: 12),
                Text(
                  'Mascota perdida',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _DetailsRow(
                  label: 'Fecha',
                  value: _formatDate(report.disappearanceDate),
                ),
                const SizedBox(height: 8),
                _DetailsRow(label: 'Detalles', value: report.details),
                if (report.phone != null &&
                    report.phone!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _DetailsRow(label: 'Telefono', value: report.phone!),
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

class _DetailsRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailsRow({required this.label, required this.value});

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
          style: const TextStyle(
            color: AppPalette.charcoal,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
