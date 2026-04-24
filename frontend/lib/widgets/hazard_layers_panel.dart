import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class HazardLayersPanelContent extends StatelessWidget {
  final bool isDarkMode;
  final bool isDarkModeEnabled;
  final bool showLowRiskCircles;
  final bool showMediumRiskCircles;
  final bool showHighRiskCircles;
  final bool showLostPetReports;
  final bool showFoundPetReports;
  final bool showGenericReports;
  final ValueChanged<bool> onToggleDarkMode;
  final ValueChanged<bool> onToggleLowRisk;
  final ValueChanged<bool> onToggleMediumRisk;
  final ValueChanged<bool> onToggleHighRisk;
  final ValueChanged<bool> onToggleLostPetReports;
  final ValueChanged<bool> onToggleFoundPetReports;
  final ValueChanged<bool> onToggleGenericReports;

  const HazardLayersPanelContent({
    super.key,
    required this.isDarkMode,
    required this.isDarkModeEnabled,
    required this.showLowRiskCircles,
    required this.showMediumRiskCircles,
    required this.showHighRiskCircles,
    required this.showLostPetReports,
    required this.showFoundPetReports,
    required this.showGenericReports,
    required this.onToggleDarkMode,
    required this.onToggleLowRisk,
    required this.onToggleMediumRisk,
    required this.onToggleHighRisk,
    required this.onToggleLostPetReports,
    required this.onToggleFoundPetReports,
    required this.onToggleGenericReports,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = AppPalette.textPrimary(isDarkMode);
    final ScrollController scrollController = ScrollController();

    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Indice de visualizacion',
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppPalette.border(isDarkMode)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Modo oscuro',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: isDarkModeEnabled,
                    activeThumbColor: AppPalette.primaryBlue,
                    activeTrackColor: AppPalette.primaryBlue.withValues(
                      alpha: 0.45,
                    ),
                    onChanged: onToggleDarkMode,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _LayerCheckbox(
              label: 'Circulos de peligros - nivel bajo',
              checked: showLowRiskCircles,
              color: AppPalette.dangerYellow,
              onChanged: onToggleLowRisk,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 8),
            _LayerCheckbox(
              label: 'Circulos de peligros - nivel medio',
              checked: showMediumRiskCircles,
              color: AppPalette.dangerOrange,
              onChanged: onToggleMediumRisk,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 8),
            _LayerCheckbox(
              label: 'Circulos de peligros - nivel alto',
              checked: showHighRiskCircles,
              color: AppPalette.dangerRed,
              onChanged: onToggleHighRisk,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 12),
            _LayerCheckbox(
              label: 'Mascotas perdidas',
              checked: showLostPetReports,
              color: AppPalette.reportYellow,
              onChanged: onToggleLostPetReports,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 8),
            _LayerCheckbox(
              label: 'Mascotas encontradas',
              checked: showFoundPetReports,
              color: AppPalette.reportGreen,
              onChanged: onToggleFoundPetReports,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 8),
            _LayerCheckbox(
              label: 'Otros reportes',
              checked: showGenericReports,
              color: AppPalette.charcoal,
              onChanged: onToggleGenericReports,
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      ),
    );
  }
}

class _LayerCheckbox extends StatelessWidget {
  final String label;
  final bool checked;
  final Color color;
  final ValueChanged<bool> onChanged;
  final bool isDarkMode;

  const _LayerCheckbox({
    required this.label,
    required this.checked,
    required this.color,
    required this.onChanged,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = AppPalette.textPrimary(isDarkMode);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onChanged(!checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: checked,
                onChanged: (bool? value) => onChanged(value ?? false),
                shape: const CircleBorder(),
                activeColor: color,
                side: BorderSide(
                  color: AppPalette.border(isDarkMode),
                  width: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
