import 'package:flutter/material.dart';

import '../../theme/app_palette.dart';
import 'local_image_widget.dart';

Future<void> showImagePreviewDialog(
  BuildContext context, {
  required String source,
  required bool isDarkMode,
  String? title,
}) {
  final String imageSource = source.trim();
  if (imageSource.isEmpty) return Future<void>.value();

  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    builder: (_) {
      return _ImagePreviewDialogBody(source: imageSource);
    },
  );
}

class ExpandableImage extends StatelessWidget {
  final String source;
  final bool isDarkMode;
  final String? title;
  final Widget child;

  const ExpandableImage({super.key, required this.source, required this.isDarkMode, required this.child, this.title});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showImagePreviewDialog(context, source: source, isDarkMode: isDarkMode, title: title),
        child: child,
      ),
    );
  }
}

class _ImagePreviewDialogBody extends StatelessWidget {
  final String source;

  const _ImagePreviewDialogBody({required this.source});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Center(
                    child: buildLocalImageWidget(
                      source: source,
                      fit: BoxFit.contain,
                      fallback: const _PreviewFallback(),
                      errorBuilder: (_, _, _) => const _PreviewFallback(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 18,
            right: 18,
            child: SafeArea(
              child: SizedBox(
                width: 54,
                height: 54,
                child: Material(
                  color: AppPalette.white.withValues(alpha: 0.92),
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppPalette.charcoal, size: 30),
                    tooltip: 'Cerrar',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewFallback extends StatelessWidget {
  const _PreviewFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Icon(Icons.broken_image_outlined, color: AppPalette.iconGray, size: 48));
  }
}
