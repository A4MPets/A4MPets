import 'dart:math' as math;

import 'package:flutter/material.dart';

enum PanelAnchor {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

class AppModalPanel extends StatelessWidget {
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
  final BorderRadius borderRadius;
  final VoidCallback onClosePressed;
  final bool showBackButton;
  final bool scrollContent;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool showLoadingIndicator;

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
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.showBackButton = false,
    this.scrollContent = true,
    this.animationDuration = const Duration(milliseconds: 260),
    this.animationCurve = Curves.easeOutCubic,
    this.showLoadingIndicator = false,
  });

  static const double _margin = 16;
  static const double _floatingTopOffset = 10;

  @override
  Widget build(BuildContext context) {
    final Color panelBackground = isDarkMode
        ? const Color(0xCC201E1E)
        : const Color(0xCCE6E6E6);

    final Color titleColor = isDarkMode
        ? const Color(0xFFAAAAAA)
        : const Color(0xFF404040);

    final bool hasTitle = title != null && title!.trim().isNotEmpty;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isMobile = constraints.maxWidth <= 900;
        final double availableWidth = constraints.maxWidth - (_margin * 2);
        final double availableHeight = constraints.maxHeight - (_margin * 2);

        final double resolvedWidth = isMobile || expandHorizontal
            ? availableWidth
            : math.min(width ?? 380, availableWidth);

        final double requestedMaxHeight = maxHeightFactor != null
            ? availableHeight * maxHeightFactor!
            : (maxHeight ?? height ?? availableHeight * 0.62);

        final double resolvedMaxHeight = expandVertical
            ? availableHeight
            : math.min(requestedMaxHeight, availableHeight);

        final double resolvedFixedHeight = expandVertical
            ? availableHeight
            : math.min(height ?? resolvedMaxHeight, resolvedMaxHeight);

        final Widget panelBody = Padding(
          padding: const EdgeInsets.all(_margin),
          child: Align(
            alignment: _toAlignment(anchor),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: math.min(300, resolvedWidth),
                maxWidth: resolvedWidth,
                minHeight: adaptHeightToContent ? 0 : resolvedFixedHeight,
                maxHeight: adaptHeightToContent
                    ? resolvedMaxHeight
                    : resolvedFixedHeight,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: panelBackground,
                  borderRadius: borderRadius,
                ),
                child: Stack(
                  children: [
                    if (scrollContent)
                      if (adaptHeightToContent)
                        _PanelScrollableBody(
                          topPadding: hasTitle ? 56 : 12,
                          adaptHeightToContent: true,
                          child: child,
                        )
                      else
                        Positioned.fill(
                          child: _PanelScrollableBody(
                            topPadding: hasTitle ? 56 : 12,
                            adaptHeightToContent: false,
                            child: child,
                          ),
                        )
                    else
                      Positioned.fill(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            hasTitle ? 56 : 12,
                            16,
                            18,
                          ),
                          child: child,
                        ),
                      ),
                    if (hasTitle)
                      Positioned(
                        top: 14,
                        left: 56,
                        right: 56,
                        child: Text(
                          title!,
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
                    if (showLoadingIndicator)
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: true,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? const Color(0x55201E1E)
                                  : const Color(0x55E6E6E6),
                              borderRadius: borderRadius,
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
                      top: _floatingTopOffset,
                      left: 12,
                      child: _PanelBackOrCloseButton(
                        showBackIcon: showBackButton,
                        onPressed: onClosePressed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: animationDuration,
          curve: animationCurve,
          builder: (BuildContext context, double value, Widget? child) {
            final double offsetY = (1 - value) * 18;
            final double scale = 0.985 + (0.015 * value);

            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, offsetY),
                child: Transform.scale(
                  scale: scale,
                  child: child,
                ),
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
      16,
      18,
    );

    if (widget.adaptHeightToContent) {
      return Scrollbar(
        controller: _scrollController,
        child: ListView(
          controller: _scrollController,
          padding: contentPadding,
          shrinkWrap: true,
          children: [widget.child],
        ),
      );
    }

    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: contentPadding,
        child: widget.child,
      ),
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
