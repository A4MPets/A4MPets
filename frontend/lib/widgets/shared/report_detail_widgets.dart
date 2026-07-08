import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import 'image_preview_dialog.dart';
import 'local_image_widget.dart';
import 'panel_action_button.dart';

String formatReportDate(DateTime date) {
  final String day = date.day.toString().padLeft(2, '0');
  final String month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String formatReportDateTime(DateTime dateTime) {
  final String hour = dateTime.hour.toString().padLeft(2, '0');
  final String minute = dateTime.minute.toString().padLeft(2, '0');
  return '${formatReportDate(dateTime)} $hour:$minute';
}

class ReportDetailsRow extends StatelessWidget {
  final bool isDarkMode;
  final String label;
  final String value;
  final bool boxed;
  final int maxLines;
  final EdgeInsets padding;

  const ReportDetailsRow({
    super.key,
    required this.isDarkMode,
    required this.label,
    required this.value,
    this.boxed = false,
    this.maxLines = 2,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final Color valueColor = AppPalette.textPrimary(isDarkMode);

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: TextStyle(
              color: boxed || isDarkMode ? AppPalette.textMutedDark : AppPalette.iconGray,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: boxed ? 6 : 4),
          boxed
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppPalette.fieldBackground(isDarkMode),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _ReportValueText(value: value, color: valueColor, maxLines: maxLines),
                )
              : _ReportValueText(value: value, color: valueColor),
        ],
      ),
    );
  }
}

class ReportImageFallback extends StatelessWidget {
  final IconData? icon;
  final String? text;

  const ReportImageFallback({super.key, this.icon, this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppPalette.placeholderGray,
      alignment: Alignment.center,
      child: icon == null
          ? (text == null
                ? null
                : Text(
                    text!,
                    style: const TextStyle(color: AppPalette.iconGray, fontSize: 14, fontWeight: FontWeight.w700),
                  ))
          : Icon(icon, color: AppPalette.iconGray, size: 34),
    );
  }
}

class ReportPhotoBlock extends StatelessWidget {
  final bool isDarkMode;
  final String label;
  final String? source;
  final IconData? fallbackIcon;
  final String? fallbackText;
  final double height;
  final Color? labelColor;
  final double labelFontSize;
  final FontWeight labelFontWeight;
  final double labelSpacing;
  final double imageBorderRadius;
  final bool boxed;

  const ReportPhotoBlock({
    super.key,
    required this.isDarkMode,
    required this.label,
    required this.source,
    this.fallbackIcon,
    this.fallbackText,
    this.height = 180,
    this.labelColor,
    this.labelFontSize = 12,
    this.labelFontWeight = FontWeight.w700,
    this.labelSpacing = 6,
    this.imageBorderRadius = 14,
    this.boxed = false,
  });

  @override
  Widget build(BuildContext context) {
    final String? imageSource = source?.trim();
    final Widget image = ClipRRect(
      borderRadius: BorderRadius.circular(imageBorderRadius),
      child: imageSource != null && imageSource.isNotEmpty
          ? ExpandableImage(
              source: imageSource,
              isDarkMode: isDarkMode,
              title: label,
              child: buildLocalImageWidget(
                source: imageSource,
                fit: BoxFit.cover,
                fallback: ReportImageFallback(icon: fallbackIcon, text: fallbackText),
                errorBuilder: (_, _, _) => ReportImageFallback(icon: fallbackIcon, text: fallbackText),
              ),
            )
          : ReportImageFallback(icon: fallbackIcon, text: fallbackText),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor ?? AppPalette.textMutedDark,
            fontSize: labelFontSize,
            fontWeight: labelFontWeight,
          ),
        ),
        SizedBox(height: labelSpacing),
        Container(
          height: height,
          decoration: boxed
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppPalette.border(isDarkMode)),
                )
              : null,
          child: image,
        ),
      ],
    );
  }
}

class ReportDetailsActions extends StatelessWidget {
  final VoidCallback onViewComments;
  final String? debugDeleteLabel;
  final VoidCallback? onDebugDelete;

  const ReportDetailsActions({super.key, required this.onViewComments, this.debugDeleteLabel, this.onDebugDelete});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PanelActionButton(
          label: 'Ver comentarios',
          onPressed: onViewComments,
          backgroundColor: AppPalette.placeholderGray,
          foregroundColor: AppPalette.charcoal,
        ),
        if (onDebugDelete != null && debugDeleteLabel != null) ...[
          const SizedBox(height: 8),
          PanelActionButton(
            label: debugDeleteLabel!,
            onPressed: onDebugDelete,
            foregroundColor: AppPalette.dangerRed,
            borderColor: AppPalette.dangerRed,
          ),
        ],
      ],
    );
  }
}

class _ReportValueText extends StatelessWidget {
  final String value;
  final Color color;
  final int maxLines;

  const _ReportValueText({required this.value, required this.color, this.maxLines = 2});

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
    );
  }
}
