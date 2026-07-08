import 'package:flutter/material.dart';

import '../models/generic_report_record.dart';
import '../theme/app_palette.dart';
import 'shared/panel_scroll_view.dart';
import 'shared/report_detail_widgets.dart';

class GenericReportDetailsPanelContent extends StatelessWidget {
  final bool isDarkMode;
  final GenericReportRecord report;
  final VoidCallback onViewComments;
  final String? debugDeleteLabel;
  final VoidCallback? onDebugDelete;

  const GenericReportDetailsPanelContent({
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
                  ReportPhotoBlock(isDarkMode: isDarkMode, label: 'Foto del reporte', source: report.photoUrl),
                if (report.photoUrl != null && report.photoUrl!.isNotEmpty) const SizedBox(height: 12),
                Text(
                  'Reporte',
                  style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ReportDetailsRow(isDarkMode: isDarkMode, label: 'Fecha', value: formatReportDate(report.reportedDate)),
                const SizedBox(height: 8),
                ReportDetailsRow(
                  isDarkMode: isDarkMode,
                  label: 'Riesgo',
                  value: GenericReportRecord.riskLabelFromCode(report.riskLevelCode),
                ),
                if (report.impactRadiusMeters > 0) ...[
                  const SizedBox(height: 8),
                  ReportDetailsRow(
                    isDarkMode: isDarkMode,
                    label: 'Radio de afectación',
                    value: '${report.impactRadiusMeters} m',
                  ),
                ],
                const SizedBox(height: 8),
                ReportDetailsRow(isDarkMode: isDarkMode, label: 'Descripción', value: report.description),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        ReportDetailsActions(
          onViewComments: onViewComments,
          debugDeleteLabel: debugDeleteLabel,
          onDebugDelete: onDebugDelete,
        ),
        const SizedBox(height: 8),
        Text(
          'Reportado por: ${report.reportedByUsername}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppPalette.textMutedDark, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
