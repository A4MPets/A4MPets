import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class ReportTypeSelectorPanelContent extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onHazardPressed;
  final VoidCallback onLostPetPressed;
  final VoidCallback onFoundPetPressed;
  final VoidCallback onGenericPressed;

  const ReportTypeSelectorPanelContent({
    super.key,
    required this.isDarkMode,
    required this.onHazardPressed,
    required this.onLostPetPressed,
    required this.onFoundPetPressed,
    required this.onGenericPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReportTypeButton(
          label: 'Peligro',
          color: AppPalette.dangerRed,
          onPressed: onHazardPressed,
        ),
        const SizedBox(height: 8),
        _ReportTypeButton(
          label: 'Mascota perdida',
          color: AppPalette.reportYellow,
          onPressed: onLostPetPressed,
        ),
        const SizedBox(height: 8),
        _ReportTypeButton(
          label: 'Mascota encontrada',
          color: AppPalette.reportGreen,
          onPressed: onFoundPetPressed,
        ),
        const SizedBox(height: 8),
        _ReportTypeButton(
          label: 'Otro',
          color: AppPalette.charcoal,
          onPressed: onGenericPressed,
        ),
      ],
    );
  }
}

class _ReportTypeButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ReportTypeButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
