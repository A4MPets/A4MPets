import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';

class PanelActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isBusy;
  final double height;
  final double fontSize;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? disabledBackgroundColor;
  final Color? borderColor;

  const PanelActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isBusy = false,
    this.height = 44,
    this.fontSize = 14,
    this.backgroundColor = AppPalette.primaryBlue,
    this.foregroundColor = AppPalette.white,
    this.disabledBackgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: borderColor == null
          ? ElevatedButton(
              onPressed: isBusy ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                elevation: 0,
                disabledBackgroundColor: disabledBackgroundColor,
                shape: _shape,
              ),
              child: _content,
            )
          : OutlinedButton(
              onPressed: isBusy ? null : onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: foregroundColor,
                side: BorderSide(color: borderColor!),
                shape: _shape,
              ),
              child: _content,
            ),
    );
  }

  RoundedRectangleBorder get _shape => RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

  Widget get _content {
    if (isBusy) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppPalette.white),
      );
    }
    return Text(
      label,
      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
    );
  }
}
