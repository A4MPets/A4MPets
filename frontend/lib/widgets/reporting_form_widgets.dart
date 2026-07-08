import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_palette.dart';
import 'shared/local_image_widget.dart';
import 'shared/panel_scroll_view.dart';

class ReportingSelectionOption {
  final String code, label;

  const ReportingSelectionOption(this.code, this.label);
}

final List<TextInputFormatter> reportingPhoneInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
];

String formatReportingDate(DateTime date) {
  final String day = date.day.toString().padLeft(2, '0');
  final String month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

Future<DateTime?> showReportingDatePicker({
  required BuildContext context,
  required bool isDarkMode,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  final ThemeData baseTheme = Theme.of(context);
  final Color dialogBackground = AppPalette.dialogBackground(isDarkMode);
  final Color foregroundColor = AppPalette.textPrimary(isDarkMode);
  const Color selectedForegroundColor = AppPalette.white;

  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    builder: (BuildContext context, Widget? child) {
      return Theme(
        data: baseTheme.copyWith(
          colorScheme: baseTheme.colorScheme.copyWith(
            primary: AppPalette.primaryBlue,
            onPrimary: selectedForegroundColor,
            surface: dialogBackground,
            onSurface: foregroundColor,
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: dialogBackground,
            headerBackgroundColor: AppPalette.primaryBlue,
            headerForegroundColor: selectedForegroundColor,
            dayForegroundColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) return selectedForegroundColor;
              return foregroundColor;
            }),
            yearForegroundColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) return selectedForegroundColor;
              return foregroundColor;
            }),
            todayForegroundColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) return selectedForegroundColor;
              return AppPalette.primaryBlue;
            }),
            todayBorder: const BorderSide(color: AppPalette.primaryBlue),
          ),
          dialogTheme: baseTheme.dialogTheme.copyWith(backgroundColor: dialogBackground),
          textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: AppPalette.primaryBlue)),
        ),
        child: child ?? const SizedBox.shrink(),
      );
    },
  );
}

class ReportingPanelScaffold extends StatelessWidget {
  final List<Widget> children;
  final String submitLabel;
  final bool isBusy;
  final VoidCallback onSubmit;
  final Color submitColor;
  final String? submitValidationErrorText;
  final bool usePanelScrollView;

  const ReportingPanelScaffold({
    super.key,
    required this.children,
    required this.submitLabel,
    required this.isBusy,
    required this.onSubmit,
    required this.submitColor,
    this.submitValidationErrorText,
    this.usePanelScrollView = true,
  });

  @override
  Widget build(BuildContext context) {
    final Widget content = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: usePanelScrollView ? PanelScrollView(child: content) : SingleChildScrollView(child: content),
        ),
        const SizedBox(height: 12),
        if (submitValidationErrorText != null) ...[
          ReportingFieldErrorText(message: submitValidationErrorText!),
          const SizedBox(height: 8),
        ],
        ReportingPrimaryButton(label: submitLabel, isBusy: isBusy, onPressed: onSubmit, backgroundColor: submitColor),
      ],
    );
  }
}

class ReportingFieldErrorText extends StatelessWidget {
  final String message;

  const ReportingFieldErrorText({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(color: AppPalette.dangerRed, fontSize: 12, fontWeight: FontWeight.w600),
    );
  }
}

class ReportingLabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const ReportingLabeledField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppPalette.textMutedDark, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class ReportingDropdownField extends StatelessWidget {
  final bool isDarkMode;
  final String value;
  final List<ReportingSelectionOption> items;
  final ValueChanged<String> onChanged;

  const ReportingDropdownField({
    super.key,
    required this.isDarkMode,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppPalette.fieldBackground(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.border(isDarkMode)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppPalette.fieldBackground(isDarkMode),
          style: TextStyle(color: AppPalette.textPrimary(isDarkMode), fontSize: 13, fontWeight: FontWeight.w600),
          items: items
              .map(
                (ReportingSelectionOption option) =>
                    DropdownMenuItem<String>(value: option.code, child: Text(option.label)),
              )
              .toList(growable: false),
          onChanged: (String? nextValue) {
            if (nextValue != null) onChanged(nextValue);
          },
        ),
      ),
    );
  }
}

class ReportingTextField extends StatelessWidget {
  final bool isDarkMode;
  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final String? errorText;
  final ValueChanged<String>? onSubmitted, onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const ReportingTextField({
    super.key,
    required this.isDarkMode,
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.errorText,
    this.onSubmitted,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: TextStyle(color: AppPalette.textPrimary(isDarkMode), fontSize: 13, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: AppPalette.textMutedDark, fontSize: 13, fontWeight: FontWeight.w500),
            filled: true,
            fillColor: AppPalette.fieldBackground(isDarkMode),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppPalette.border(isDarkMode)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppPalette.border(isDarkMode)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppPalette.primaryBlue, width: 1.2),
            ),
          ),
          onSubmitted: onSubmitted,
          onChanged: onChanged,
        ),
        if (errorText != null) ...[const SizedBox(height: 6), ReportingFieldErrorText(message: errorText!)],
      ],
    );
  }
}

class ReportingPhotoField extends StatelessWidget {
  final bool isDarkMode;
  final String? photoSource;
  final bool isBusy;
  final VoidCallback onPickPressed;
  final String? errorText;

  const ReportingPhotoField({
    super.key,
    required this.isDarkMode,
    required this.photoSource,
    required this.isBusy,
    required this.onPickPressed,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor = AppPalette.border(isDarkMode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 104,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: photoSource != null && photoSource!.isNotEmpty
                      ? buildLocalImageWidget(
                          source: photoSource,
                          fit: BoxFit.contain,
                          fallback: const _PhotoPlaceholder(),
                          errorBuilder: (_, _, _) => const _PhotoPlaceholder(),
                        )
                      : const _PhotoPlaceholder(),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: Material(
                    color: AppPalette.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: isBusy ? null : onPickPressed,
                      customBorder: const CircleBorder(),
                      child: isBusy
                          ? const Padding(
                              padding: EdgeInsets.all(9),
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppPalette.charcoal),
                            )
                          : const Icon(Icons.edit, size: 18, color: AppPalette.charcoal),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (errorText != null) ...[const SizedBox(height: 6), ReportingFieldErrorText(message: errorText!)],
      ],
    );
  }
}

class ReportingCheckboxField extends StatelessWidget {
  final bool isDarkMode;
  final bool value;
  final String title, subtitle;
  final ValueChanged<bool> onChanged;

  const ReportingCheckboxField({
    super.key,
    required this.isDarkMode,
    required this.value,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.fieldBackground(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.border(isDarkMode)),
      ),
      child: CheckboxListTile(
        value: value,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppPalette.primaryBlue,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        title: Text(
          title,
          style: TextStyle(color: AppPalette.textPrimary(isDarkMode), fontSize: 13, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppPalette.textMutedDark, fontSize: 12, fontWeight: FontWeight.w500),
        ),
        onChanged: (bool? nextValue) => onChanged(nextValue ?? false),
      ),
    );
  }
}

class ReportingDateField extends StatelessWidget {
  final bool isDarkMode;
  final String valueText;
  final VoidCallback onTap;

  const ReportingDateField({super.key, required this.isDarkMode, required this.valueText, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.textMutedDark,
          side: const BorderSide(color: AppPalette.textMutedDark),
          backgroundColor: AppPalette.fieldBackground(isDarkMode),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.calendar_today_rounded, size: 16),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            valueText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class ReportingSecondaryButton extends StatelessWidget {
  final bool isDarkMode;
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool showBorder;

  const ReportingSecondaryButton({
    super.key,
    required this.isDarkMode,
    required this.label,
    required this.onPressed,
    this.icon,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final Widget child = icon == null
        ? Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );

    return SizedBox(
      height: 46,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.textPrimary(isDarkMode),
          side: showBorder ? BorderSide(color: AppPalette.border(isDarkMode)) : BorderSide.none,
          backgroundColor: AppPalette.fieldBackground(isDarkMode),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: child,
      ),
    );
  }
}

class ReportingSelectionButton extends StatelessWidget {
  final bool isDarkMode;
  final String label;
  final VoidCallback? onPressed;

  const ReportingSelectionButton({super.key, required this.isDarkMode, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ReportingSecondaryButton(isDarkMode: isDarkMode, label: label, onPressed: onPressed, showBorder: false);
  }
}

class ReportingPrimaryButton extends StatelessWidget {
  final String label;
  final bool isBusy;
  final VoidCallback? onPressed;
  final Color backgroundColor;

  const ReportingPrimaryButton({
    super.key,
    required this.label,
    required this.isBusy,
    required this.onPressed,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: isBusy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isBusy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppPalette.placeholderGray,
      child: const Center(child: Icon(Icons.warning_amber_rounded, size: 38, color: AppPalette.iconGray)),
    );
  }
}
