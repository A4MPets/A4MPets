import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class ReportTypeSelectorPanelContent extends StatelessWidget {
  final bool isDarkMode;
  final bool isAuthenticated;
  final VoidCallback onHazardPressed;
  final VoidCallback onLostPetPressed;
  final VoidCallback onFoundPetPressed;
  final VoidCallback onGenericPressed;

  const ReportTypeSelectorPanelContent({
    super.key,
    required this.isDarkMode,
    required this.isAuthenticated,
    required this.onHazardPressed,
    required this.onLostPetPressed,
    required this.onFoundPetPressed,
    required this.onGenericPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!isAuthenticated) {
      return _AnonymousReportTypeSelector(
        onHazardPressed: onHazardPressed,
        onLostPetPressed: onLostPetPressed,
        onFoundPetPressed: onFoundPetPressed,
        onGenericPressed: onGenericPressed,
      );
    }

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

class _AnonymousReportTypeSelector extends StatelessWidget {
  final VoidCallback onHazardPressed;
  final VoidCallback onLostPetPressed;
  final VoidCallback onFoundPetPressed;
  final VoidCallback onGenericPressed;

  const _AnonymousReportTypeSelector({
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
        _LockedReportTypeButton(
          label: 'Mascota perdida',
          onPressed: onLostPetPressed,
        ),
        const SizedBox(height: 8),
        _LockedReportTypeButton(
          label: 'Mascota encontrada',
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

class ReportAuthRequiredPanelContent extends StatelessWidget {
  final bool isDarkMode;
  final String message;
  final VoidCallback onLoginPressed;

  const ReportAuthRequiredPanelContent({
    super.key,
    required this.isDarkMode,
    required this.message,
    required this.onLoginPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = AppPalette.textPrimary(isDarkMode);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          size: 46,
          color: AppPalette.textMutedDark,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            height: 1.25,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 46,
          child: ElevatedButton(
            onPressed: onLoginPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.primaryBlue,
              foregroundColor: AppPalette.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Iniciar sesion',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class _LockedReportTypeButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _LockedReportTypeButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.lock_outline, size: 17),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.textMutedDark,
          side: const BorderSide(color: AppPalette.textMutedDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
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
