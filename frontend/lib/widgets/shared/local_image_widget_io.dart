import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

Widget buildLocalImageWidget({
  required String? source,
  required BoxFit fit,
  required Widget fallback,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  if (source == null || source.isEmpty) {
    return fallback;
  }

  if (source.startsWith('data:image')) {
    final String? raw = _extractBase64(source);
    if (raw == null) {
      return fallback;
    }

    return Image.memory(
      base64Decode(raw),
      fit: fit,
      errorBuilder: errorBuilder,
    );
  }

  final File file = File(source);
  if (!file.existsSync()) {
    return fallback;
  }

  return Image.file(
    file,
    fit: fit,
    errorBuilder: errorBuilder,
  );
}

String? _extractBase64(String dataUri) {
  final int comma = dataUri.indexOf(',');
  if (comma < 0 || comma + 1 >= dataUri.length) {
    return null;
  }
  return dataUri.substring(comma + 1);
}
