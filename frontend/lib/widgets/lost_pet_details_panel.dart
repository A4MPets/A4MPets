import 'package:flutter/material.dart';

import '../models/lost_pet_report_record.dart';
import '../models/pet_record.dart';
import '../theme/app_palette.dart';
import 'shared/image_preview_dialog.dart';
import 'shared/local_image_widget.dart';
import 'shared/panel_scroll_view.dart';

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
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                _PhotoBlock(
                  isDarkMode: isDarkMode,
                  label: 'Foto de la mascota',
                  source:
                      pet?.photoPath ?? report.petPhotoUrl ?? report.photoUrl,
                  placeholderIcon: Icons.pets,
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 12),
                if (pet != null) ...[
                  _DetailsRow(
                    isDarkMode: isDarkMode,
                    label: 'Fecha de registro',
                    value: _formatDate(pet!.registeredAt),
                  ),
                  if (pet!.adoptionDate != null)
                    _DetailsRow(
                      isDarkMode: isDarkMode,
                      label: 'Fecha de adopción',
                      value: _formatDate(pet!.adoptionDate!),
                    ),
                  if (pet!.birthDate != null)
                    _DetailsRow(
                      isDarkMode: isDarkMode,
                      label: 'Fecha de nacimiento',
                      value: _formatDate(pet!.birthDate!),
                    ),
                  const SizedBox(height: 10),
                ],
                _SectionTitle(isDarkMode: isDarkMode, label: 'Reporte'),
                const SizedBox(height: 8),
                _DetailsRow(
                  isDarkMode: isDarkMode,
                  label: 'Fecha de desaparición',
                  value: _formatDate(report.disappearanceDate),
                ),
                _DetailsRow(
                  isDarkMode: isDarkMode,
                  label: 'Ultima ubicación',
                  value:
                      '${report.lastSeenLatitude.toStringAsFixed(5)}, ${report.lastSeenLongitude.toStringAsFixed(5)}',
                ),
                _DetailsRow(
                  isDarkMode: isDarkMode,
                  label: 'Detalles',
                  value: report.details,
                ),
                if (report.phone != null && report.phone!.trim().isNotEmpty)
                  _DetailsRow(
                    isDarkMode: isDarkMode,
                    label: 'Telefono',
                    value: report.phone!,
                  ),
                if (report.photoUrl != null && report.photoUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _PhotoBlock(
                    isDarkMode: isDarkMode,
                    label: 'Foto del reporte',
                    source: report.photoUrl,
                    placeholderIcon: Icons.image_outlined,
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

class _PhotoBlock extends StatelessWidget {
  final bool isDarkMode;
  final String label;
  final String? source;
  final IconData placeholderIcon;

  const _PhotoBlock({
    required this.isDarkMode,
    required this.label,
    required this.source,
    required this.placeholderIcon,
  });

  @override
  Widget build(BuildContext context) {
    final String? imageSource = source?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(isDarkMode: isDarkMode, label: label),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: imageSource != null && imageSource.isNotEmpty
                ? ExpandableImage(
                    source: imageSource,
                    isDarkMode: isDarkMode,
                    title: label,
                    child: buildLocalImageWidget(
                      source: imageSource,
                      fit: BoxFit.cover,
                      fallback: _ImageFallback(icon: placeholderIcon),
                      errorBuilder: (_, _, _) =>
                          _ImageFallback(icon: placeholderIcon),
                    ),
                  )
                : _ImageFallback(icon: placeholderIcon),
          ),
        ),
      ],
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final IconData icon;

  const _ImageFallback({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppPalette.placeholderGray,
      alignment: Alignment.center,
      child: Icon(icon, color: AppPalette.iconGray, size: 34),
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
      style: TextStyle(
        color: AppPalette.textPrimary(isDarkMode),
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _DetailsRow extends StatelessWidget {
  final bool isDarkMode;
  final String label;
  final String value;

  const _DetailsRow({
    required this.isDarkMode,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
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
            value,
            style: TextStyle(
              color: AppPalette.textPrimary(isDarkMode),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
