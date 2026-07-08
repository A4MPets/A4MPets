import 'package:flutter/material.dart';

import '../models/lost_pet_report_record.dart';
import '../models/pet_record.dart';
import '../theme/app_palette.dart';
import 'shared/panel_scroll_view.dart';
import 'shared/report_detail_widgets.dart';

class LostPetDetailsPanelContent extends StatelessWidget {
  final bool isDarkMode;
  final LostPetReportRecord report;
  final PetRecord? pet;
  final VoidCallback onViewComments;
  final String? debugDeleteLabel;
  final VoidCallback? onDebugDelete;

  const LostPetDetailsPanelContent({
    super.key,
    required this.isDarkMode,
    required this.report,
    required this.pet,
    required this.onViewComments,
    this.debugDeleteLabel,
    this.onDebugDelete,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = AppPalette.textPrimary(isDarkMode);
    final String title = pet?.displayName ?? 'Mascota perdida';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: PanelScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                ReportPhotoBlock(
                  isDarkMode: isDarkMode,
                  label: 'Foto de la mascota',
                  source: pet?.photoPath ?? report.petPhotoUrl ?? report.photoUrl,
                  fallbackIcon: Icons.pets,
                  labelColor: textColor,
                  labelFontSize: 13,
                  labelFontWeight: FontWeight.w800,
                  labelSpacing: 8,
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 12),
                if (pet != null) ...[
                  ReportDetailsRow(
                    isDarkMode: isDarkMode,
                    label: 'Fecha de registro',
                    value: formatReportDate(pet!.registeredAt),
                    padding: const EdgeInsets.only(bottom: 8),
                  ),
                  if (pet!.adoptionDate != null)
                    ReportDetailsRow(
                      isDarkMode: isDarkMode,
                      label: 'Fecha de adopción',
                      value: formatReportDate(pet!.adoptionDate!),
                      padding: const EdgeInsets.only(bottom: 8),
                    ),
                  if (pet!.birthDate != null)
                    ReportDetailsRow(
                      isDarkMode: isDarkMode,
                      label: 'Fecha de nacimiento',
                      value: formatReportDate(pet!.birthDate!),
                      padding: const EdgeInsets.only(bottom: 8),
                    ),
                  const SizedBox(height: 10),
                ],
                _SectionTitle(isDarkMode: isDarkMode, label: 'Reporte'),
                const SizedBox(height: 8),
                ReportDetailsRow(
                  isDarkMode: isDarkMode,
                  label: 'Fecha de desaparición',
                  value: formatReportDate(report.disappearanceDate),
                  padding: const EdgeInsets.only(bottom: 8),
                ),
                ReportDetailsRow(
                  isDarkMode: isDarkMode,
                  label: 'Ultima ubicación',
                  value:
                      '${report.lastSeenLatitude.toStringAsFixed(5)}, ${report.lastSeenLongitude.toStringAsFixed(5)}',
                  padding: const EdgeInsets.only(bottom: 8),
                ),
                ReportDetailsRow(
                  isDarkMode: isDarkMode,
                  label: 'Detalles',
                  value: report.details,
                  padding: const EdgeInsets.only(bottom: 8),
                ),
                if (report.phone != null && report.phone!.trim().isNotEmpty)
                  ReportDetailsRow(
                    isDarkMode: isDarkMode,
                    label: 'Telefono',
                    value: report.phone!,
                    padding: const EdgeInsets.only(bottom: 8),
                  ),
                if (report.photoUrl != null && report.photoUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ReportPhotoBlock(
                    isDarkMode: isDarkMode,
                    label: 'Foto del reporte',
                    source: report.photoUrl,
                    fallbackIcon: Icons.image_outlined,
                    labelColor: textColor,
                    labelFontSize: 13,
                    labelFontWeight: FontWeight.w800,
                    labelSpacing: 8,
                  ),
                ],
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
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final bool isDarkMode;
  final String label;

  const _SectionTitle({required this.isDarkMode, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(color: AppPalette.textPrimary(isDarkMode), fontSize: 13, fontWeight: FontWeight.w800),
    );
  }
}
