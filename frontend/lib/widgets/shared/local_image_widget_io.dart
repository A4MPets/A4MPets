import 'dart:io';

import 'package:flutter/material.dart';

import 'local_image_support.dart';

Widget buildLocalImageWidget({
  required String? source,
  required BoxFit fit,
  required Widget fallback,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  if (source == null || source.isEmpty) return fallback;

  if (isDataImageSource(source)) {
    final decodedBytes = decodedBytesForDataUri(source);
    if (decodedBytes == null) return fallback;

    return Image.memory(decodedBytes, fit: fit, gaplessPlayback: true, errorBuilder: errorBuilder);
  }

  if (isNetworkImageSource(source)) {
    return Image.network(
      resolveBackendImageSource(source),
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: errorBuilder,
    );
  }

  final File file = File(source);
  if (!file.existsSync()) return fallback;

  return Image.file(file, fit: fit, gaplessPlayback: true, errorBuilder: errorBuilder);
}
