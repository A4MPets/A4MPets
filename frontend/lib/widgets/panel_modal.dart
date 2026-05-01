import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

enum PanelAnchor { topLeft, topRight, bottomLeft, bottomRight }

class AppModalPanel extends StatefulWidget {
  final bool isDarkMode;
  final String? title;
  final Widget child;
  final PanelAnchor anchor;
  final double? width;
  final double? height;
  final bool expandHorizontal;
  final bool expandVertical;
  final bool adaptHeightToContent;
  final double? maxHeight;
  final double? maxHeightFactor;
  final double? mobileMaxHeightFactor;
  final double? desktopMaxHeightFactor;
  final BorderRadius borderRadius;
  final VoidCallback onClosePressed;
  final bool showBackButton;
  final bool scrollContent;
  final double? contentTopPadding;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool showLoadingIndicator;
  final bool canMinimize;
  final bool isMinimized;
  final double minimizedHeight;
  final VoidCallback? onToggleMinimize;

  const AppModalPanel({
    super.key,
    required this.isDarkMode,
    required this.child,
    required this.onClosePressed,
    this.title,
    this.anchor = PanelAnchor.topLeft,
    this.width,
    this.height,
    this.expandHorizontal = false,
    this.expandVertical = false,
    this.adaptHeightToContent = false,
    this.maxHeight,
    this.maxHeightFactor,
    this.mobileMaxHeightFactor,
    this.desktopMaxHeightFactor,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.showBackButton = false,
    this.scrollContent = true,
    this.contentTopPadding,
    this.animationDuration = const Duration(milliseconds: 260),
    this.animationCurve = Curves.easeOutCubic,
    this.showLoadingIndicator = false,
    this.canMinimize = false,
    this.isMinimized = false,
    this.minimizedHeight = 74,
    this.onToggleMinimize,
  });

  static const double _margin = 16;
  static const double _floatingTopOffset = 10;

  @override
  State<AppModalPanel> createState() => _AppModalPanelState();
}

class _AppModalPanelState extends State<AppModalPanel> {
  bool _hasPlayedEntranceAnimation = false;

  @override
  Widget build(BuildContext context) {
    final Color panelBackground = widget.isDarkMode
        ? const Color(0xCC201E1E)
        : const Color(0xCCE6E6E6);

    final Color titleColor = widget.isDarkMode
        ? const Color(0xFFAAAAAA)
        : const Color(0xFF404040);

    final bool hasTitle =
        widget.title != null && widget.title!.trim().isNotEmpty;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final EdgeInsets viewPadding = MediaQuery.of(context).padding;
        final bool isMobile = constraints.maxWidth <= 900;
        final double safeTopInset =
            widget.anchor == PanelAnchor.topLeft ||
                widget.anchor == PanelAnchor.topRight
            ? viewPadding.top
            : 0;
        final double safeBottomInset =
            widget.anchor == PanelAnchor.bottomLeft ||
                widget.anchor == PanelAnchor.bottomRight
            ? viewPadding.bottom
            : 0;
        final double availableWidth =
            constraints.maxWidth - (AppModalPanel._margin * 2);
        final double availableHeight =
            constraints.maxHeight -
            (AppModalPanel._margin * 2) -
            safeTopInset -
            safeBottomInset;

        final double resolvedWidth = isMobile || widget.expandHorizontal
            ? availableWidth
            : math.min(widget.width ?? 380, availableWidth);

        final double? responsiveMaxHeightFactor = isMobile
            ? widget.mobileMaxHeightFactor ?? widget.maxHeightFactor
            : widget.desktopMaxHeightFactor ?? widget.maxHeightFactor;

        final double requestedMaxHeight = responsiveMaxHeightFactor != null
            ? availableHeight * responsiveMaxHeightFactor
            : (widget.maxHeight ?? widget.height ?? availableHeight * 0.62);

        final double resolvedMaxHeight = widget.expandVertical
            ? availableHeight
            : math.min(requestedMaxHeight, availableHeight);

        final double resolvedFixedHeight = widget.expandVertical
            ? availableHeight
            : math.min(widget.height ?? resolvedMaxHeight, resolvedMaxHeight);
        final double resolvedMinimizedHeight = math.min(
          widget.minimizedHeight,
          resolvedFixedHeight,
        );
        final double targetPanelHeight = widget.isMinimized
            ? resolvedMinimizedHeight
            : resolvedFixedHeight;

        final double resolvedTopPadding =
            widget.contentTopPadding ?? (hasTitle ? 56 : 12);

        final Widget panelBody = Padding(
          padding: EdgeInsets.fromLTRB(
            AppModalPanel._margin,
            AppModalPanel._margin + safeTopInset,
            AppModalPanel._margin,
            AppModalPanel._margin + safeBottomInset,
          ),
          child: Align(
            alignment: _toAlignment(widget.anchor),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: _toAlignment(widget.anchor),
              child: SizedBox(
                width: resolvedWidth,
                height: widget.adaptHeightToContent && !widget.isMinimized
                    ? null
                    : targetPanelHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: panelBackground,
                    borderRadius: widget.borderRadius,
                  ),
                  child: Stack(
                    children: [
                      if (!widget.isMinimized && widget.scrollContent)
                        if (widget.adaptHeightToContent)
                          _PanelScrollableBody(
                            topPadding: resolvedTopPadding,
                            adaptHeightToContent: true,
                            child: widget.child,
                          )
                        else
                          Positioned.fill(
                            child: _PanelScrollableBody(
                              topPadding: resolvedTopPadding,
                              adaptHeightToContent: false,
                              child: widget.child,
                            ),
                          )
                      else if (!widget.isMinimized)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            resolvedTopPadding,
                            16,
                            18,
                          ),
                          child: widget.child,
                        ),
                      if (hasTitle)
                        Positioned(
                          top: 14,
                          left: 56,
                          right: 56,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: widget.canMinimize
                                ? widget.onToggleMinimize
                                : null,
                            child: Text(
                              widget.title!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: titleColor,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (widget.canMinimize)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: widget.onToggleMinimize,
                              child: Container(
                                width: 42,
                                height: 14,
                                alignment: Alignment.topCenter,
                                child: Container(
                                  width: 42,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: widget.isDarkMode
                                        ? const Color(0x66FFFFFF)
                                        : const Color(0x66404040),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (widget.showLoadingIndicator)
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: true,
                            child: Container(
                              decoration: BoxDecoration(
                                color: widget.isDarkMode
                                    ? const Color(0x55201E1E)
                                    : const Color(0x55E6E6E6),
                                borderRadius: widget.borderRadius,
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Color(0xFF5984BC),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: AppModalPanel._floatingTopOffset,
                        left: 12,
                        child: _PanelBackOrCloseButton(
                          showBackIcon: widget.showBackButton,
                          onPressed: widget.onClosePressed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        if (_hasPlayedEntranceAnimation) {
          return panelBody;
        }

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: widget.animationDuration,
          curve: widget.animationCurve,
          onEnd: () {
            if (mounted && !_hasPlayedEntranceAnimation) {
              setState(() {
                _hasPlayedEntranceAnimation = true;
              });
            }
          },
          builder: (BuildContext context, double value, Widget? child) {
            final double offsetY = (1 - value) * 18;
            final double scale = 0.985 + (0.015 * value);

            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, offsetY),
                child: Transform.scale(scale: scale, child: child),
              ),
            );
          },
          child: panelBody,
        );
      },
    );
  }

  Alignment _toAlignment(PanelAnchor anchor) {
    switch (anchor) {
      case PanelAnchor.topLeft:
        return Alignment.topLeft;
      case PanelAnchor.topRight:
        return Alignment.topRight;
      case PanelAnchor.bottomLeft:
        return Alignment.bottomLeft;
      case PanelAnchor.bottomRight:
        return Alignment.bottomRight;
    }
  }
}

class _PanelScrollableBody extends StatefulWidget {
  final Widget child;
  final double topPadding;
  final bool adaptHeightToContent;

  const _PanelScrollableBody({
    required this.child,
    required this.topPadding,
    required this.adaptHeightToContent,
  });

  @override
  State<_PanelScrollableBody> createState() => _PanelScrollableBodyState();
}

class _PanelScrollableBodyState extends State<_PanelScrollableBody> {
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
    final EdgeInsets contentPadding = EdgeInsets.fromLTRB(
      16,
      widget.topPadding,
      0,
      18,
    );
    final Widget spacedChild = widget.child;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color thumbColor = isDarkMode
        ? AppPalette.borderLight.withValues(alpha: 0.94)
        : AppPalette.white.withValues(alpha: 0.98);
    final Color trackColor = isDarkMode
        ? AppPalette.iconGray.withValues(alpha: 0.8)
        : AppPalette.charcoal.withValues(alpha: 0.42);

    if (widget.adaptHeightToContent) {
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
          thickness: 8,
          radius: const Radius.circular(999),
          child: ListView(
            controller: _scrollController,
            padding: contentPadding,
            shrinkWrap: true,
            children: [spacedChild],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
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
            thickness: 8,
            radius: const Radius.circular(999),
            child: SizedBox(
              height: constraints.maxHeight,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: contentPadding,
                child: spacedChild,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PanelBackOrCloseButton extends StatelessWidget {
  final bool showBackIcon;
  final VoidCallback onPressed;

  const _PanelBackOrCloseButton({
    required this.showBackIcon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Material(
        color: const Color(0xFFFFFFFF),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Center(
            child: Icon(
              showBackIcon ? Icons.arrow_back_ios_new : Icons.close,
              size: showBackIcon ? 12 : 16,
              color: const Color(0xFF404040),
            ),
          ),
        ),
      ),
    );
  }
}
