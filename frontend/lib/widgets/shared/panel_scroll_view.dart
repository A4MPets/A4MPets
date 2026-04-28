import 'package:flutter/material.dart';

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
    this.scrollbarSpacing = 12,
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
    final Widget spacedChild = Padding(
      padding: EdgeInsets.only(right: widget.scrollbarSpacing),
      child: widget.child,
    );

    if (widget.shrinkWrap) {
      return Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        thickness: 8,
        radius: const Radius.circular(999),
        child: ListView(
          controller: _scrollController,
          padding: widget.padding,
          shrinkWrap: true,
          children: <Widget>[spacedChild],
        ),
      );
    }

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      trackVisibility: true,
      thickness: 8,
      radius: const Radius.circular(999),
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: widget.padding,
        child: spacedChild,
      ),
    );
  }
}
