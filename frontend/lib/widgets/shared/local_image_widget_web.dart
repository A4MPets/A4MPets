import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../services/backend_api_client.dart';

const int _memoryImageCacheLimit = 100;
final Map<String, Uint8List> _decodedDataUriCache = <String, Uint8List>{};

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
    final Uint8List? decodedBytes = _decodedBytesForDataUri(source);
    if (decodedBytes == null) {
      return fallback;
    }

    return Image.memory(
      decodedBytes,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: errorBuilder,
    );
  }

  if (source.startsWith('http://') ||
      source.startsWith('https://') ||
      source.startsWith('blob:')) {
    String resolvedSource = source;
    if (!source.startsWith('blob:') &&
        BackendApiClient.workingBaseUrl != null) {
      try {
        final Uri workingUri = Uri.parse(BackendApiClient.workingBaseUrl!);
        final Uri sourceUri = Uri.parse(source);
        if (sourceUri.path.contains('/api/media/') ||
            sourceUri.host == 'localhost' ||
            sourceUri.host == '127.0.0.1') {
          resolvedSource = sourceUri
              .replace(
                scheme: workingUri.scheme,
                host: workingUri.host,
                port: workingUri.port,
              )
              .toString();
        }
      } catch (_) {
        // Fallback to original source
      }
    }

    return Image.network(
      resolvedSource,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: errorBuilder,
    );
  }

  return fallback;
}

Uint8List? _decodedBytesForDataUri(String dataUri) {
  final Uint8List? cached = _decodedDataUriCache[dataUri];
  if (cached != null) {
    return cached;
  }

  final String? raw = _extractBase64(dataUri);
  if (raw == null) {
    return null;
  }

  final Uint8List decoded = base64Decode(raw);
  if (_decodedDataUriCache.length >= _memoryImageCacheLimit) {
    _decodedDataUriCache.remove(_decodedDataUriCache.keys.first);
  }
  _decodedDataUriCache[dataUri] = decoded;
  return decoded;
}

String? _extractBase64(String dataUri) {
  final int comma = dataUri.indexOf(',');
  if (comma < 0 || comma + 1 >= dataUri.length) {
    return null;
  }
  return dataUri.substring(comma + 1);
}
