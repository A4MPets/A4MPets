import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class LocationPickerWidget extends StatelessWidget {
  final bool isDarkMode;
  final String title;
  final String subtitle;
  final bool hasManualLocation;
  final bool hasCurrentLocation;
  final String? errorText;
  final VoidCallback onStartSelection;
  final VoidCallback onUseCurrentLocation;

  const LocationPickerWidget({
    super.key,
    required this.isDarkMode,
    required this.title,
    required this.subtitle,
    required this.hasManualLocation,
    required this.hasCurrentLocation,
    required this.errorText,
    required this.onStartSelection,
    required this.onUseCurrentLocation,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor = AppPalette.border(isDarkMode);
    final Color textColor = AppPalette.textPrimary(isDarkMode);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppPalette.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.place_rounded, color: AppPalette.primaryBlue, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppPalette.textMutedDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _LocationStatusChip(
                      isDarkMode: isDarkMode,
                      hasManualLocation: hasManualLocation,
                      hasCurrentLocation: hasCurrentLocation,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final Widget markOnMapButton = SizedBox(
                height: 38,
                child: OutlinedButton.icon(
                  onPressed: onStartSelection,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppPalette.primaryBlue,
                    side: const BorderSide(color: AppPalette.primaryBlue, width: 1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.place_rounded, size: 16),
                  label: const Text(
                    'Marcar en el mapa',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              );

              final Widget useCurrentLocationButton = SizedBox(
                height: 38,
                child: TextButton.icon(
                  onPressed: onUseCurrentLocation,
                  style: TextButton.styleFrom(
                    foregroundColor: textColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.my_location_rounded, size: 16),
                  label: const Text(
                    'Usar ubicación actual',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              );

              if (constraints.maxWidth < 310) {
                return Column(
                  children: [
                    SizedBox(width: double.infinity, child: markOnMapButton),
                    const SizedBox(height: 8),
                    SizedBox(width: double.infinity, child: useCurrentLocationButton),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: markOnMapButton),
                  const SizedBox(width: 8),
                  Expanded(child: useCurrentLocationButton),
                ],
              );
            },
          ),
          if (errorText != null) ...[
            const SizedBox(height: 6),
            Text(
              errorText!,
              style: const TextStyle(color: AppPalette.dangerRed, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

class _LocationStatusChip extends StatelessWidget {
  final bool isDarkMode;
  final bool hasManualLocation;
  final bool hasCurrentLocation;

  const _LocationStatusChip({
    required this.isDarkMode,
    required this.hasManualLocation,
    required this.hasCurrentLocation,
  });

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    late final String label;
    late final Color color;

    if (hasManualLocation) {
      icon = Icons.edit_location_alt_rounded;
      label = 'Ubicación marcada en el mapa';
      color = AppPalette.primaryBlue;
    } else if (hasCurrentLocation) {
      icon = Icons.my_location_rounded;
      label = 'Usando ubicación actual';
      color = isDarkMode ? AppPalette.textMutedDark : AppPalette.charcoal;
    } else {
      icon = Icons.location_off_rounded;
      label = 'Aún no hay ubicación lista';
      color = AppPalette.dangerRed;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
