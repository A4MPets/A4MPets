import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';

class PanelScrollView extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool shrinkWrap;
  final double scrollbarSpacing;

  const PanelScrollView({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.shrinkWrap = false,
    this.scrollbarSpacing = 0,
  });

  @override
  State<PanelScrollView> createState() => _PanelScrollViewState();
}

class _PanelScrollViewState extends State<PanelScrollView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color thumbColor = isDarkMode
        ? AppPalette.primaryBlue.withValues(alpha: 0.95)
        : AppPalette.charcoal.withValues(alpha: 0.78);
    final Color trackColor = isDarkMode
        ? AppPalette.borderLight.withValues(alpha: 0.28)
        : AppPalette.borderLight.withValues(alpha: 0.9);
    final Widget spacedChild = widget.scrollbarSpacing == 0
        ? widget.child
        : Padding(
            padding: EdgeInsets.only(right: widget.scrollbarSpacing),
            child: widget.child,
          );

    if (widget.shrinkWrap) {
      return ScrollbarTheme(
        data: ScrollbarThemeData(
          thumbColor: WidgetStatePropertyAll<Color>(thumbColor),
          trackColor: WidgetStatePropertyAll<Color>(trackColor),
          trackBorderColor: const WidgetStatePropertyAll<Color>(
            Colors.transparent,
          ),
          thickness: const WidgetStatePropertyAll<double>(8),
          radius: const Radius.circular(999),
        ),
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          trackVisibility: true,
          child: ListView(
            controller: _scrollController,
            padding: widget.padding,
            shrinkWrap: true,
            children: <Widget>[spacedChild],
          ),
        ),
      );
    }

    return ScrollbarTheme(
      data: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll<Color>(thumbColor),
        trackColor: WidgetStatePropertyAll<Color>(trackColor),
        trackBorderColor: const WidgetStatePropertyAll<Color>(
          Colors.transparent,
        ),
        thickness: const WidgetStatePropertyAll<double>(8),
        radius: const Radius.circular(999),
      ),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: widget.padding,
          child: spacedChild,
        ),
      ),
    );
  }
}
