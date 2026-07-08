import 'package:flutter/material.dart';

import '../models/hazard_report_record.dart';
import '../theme/app_palette.dart';
import 'shared/panel_action_button.dart';
import 'shared/panel_scroll_view.dart';
import 'shared/report_detail_widgets.dart';

class HazardDetailsPanelContent extends StatelessWidget {
  final bool isDarkMode;
  final HazardReportRecord hazard;
  final VoidCallback onViewComments;
  final String? debugDeleteLabel;
  final VoidCallback? onDebugDelete;

  const HazardDetailsPanelContent({
    super.key,
    required this.isDarkMode,
    required this.hazard,
    required this.onViewComments,
    this.debugDeleteLabel,
    this.onDebugDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(14)),
            child: PanelScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ReportDetailsRow(
                    label: 'Radio de afectación',
                    value: '${hazard.impactRadiusMeters} m',
                    isDarkMode: isDarkMode,
                    boxed: true,
                  ),
                  const SizedBox(height: 10),
                  ReportDetailsRow(
                    label: 'Categoría',
                    value: HazardReportRecord.categoryLabelFromCode(hazard.categoryCode),
                    isDarkMode: isDarkMode,
                    boxed: true,
                  ),
                  const SizedBox(height: 10),
                  ReportDetailsRow(
                    label: 'Descripción',
                    value: hazard.narrativeDescription,
                    isDarkMode: isDarkMode,
                    boxed: true,
                    maxLines: 6,
                  ),
                  const SizedBox(height: 10),
                  ReportDetailsRow(
                    label: 'Fecha de reporte',
                    value: formatReportDateTime(hazard.reportedAt),
                    isDarkMode: isDarkMode,
                    boxed: true,
                  ),
                  const SizedBox(height: 10),
                  ReportDetailsRow(
                    label: 'Duración aproximada',
                    value: HazardReportRecord.durationLabelFromCode(hazard.estimatedDurationCode),
                    isDarkMode: isDarkMode,
                    boxed: true,
                  ),
                  const SizedBox(height: 10),
                  ReportDetailsRow(
                    label: 'Nivel de riesgo',
                    value: HazardReportRecord.riskLabelFromCode(hazard.riskLevelCode),
                    isDarkMode: isDarkMode,
                    boxed: true,
                  ),
                  const SizedBox(height: 10),
                  ReportPhotoBlock(
                    label: 'Foto del peligro',
                    source: hazard.evidencePhotoUrl,
                    isDarkMode: isDarkMode,
                    fallbackText: 'Sin foto',
                    height: 160,
                    labelFontWeight: FontWeight.w600,
                    imageBorderRadius: 12,
                    boxed: true,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Reportado por: ${hazard.reportedByUsername}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppPalette.textMutedDark, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  if (onDebugDelete != null && debugDeleteLabel != null) ...[
                    const SizedBox(height: 12),
                    PanelActionButton(
                      label: debugDeleteLabel!,
                      onPressed: onDebugDelete,
                      foregroundColor: AppPalette.dangerRed,
                      borderColor: AppPalette.dangerRed,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ReportDetailsActions(onViewComments: onViewComments),
      ],
    );
  }
}
