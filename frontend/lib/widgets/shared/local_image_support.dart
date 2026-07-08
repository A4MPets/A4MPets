import 'dart:convert';
import 'dart:typed_data';

import '../../services/backend_api_client.dart';

const int _memoryImageCacheLimit = 100;
final Map<String, Uint8List> _decodedDataUriCache = <String, Uint8List>{};

bool isDataImageSource(String source) => source.startsWith('data:image');

bool isNetworkImageSource(String source, {bool allowBlob = false}) {
  return source.startsWith('http://') || source.startsWith('https://') || (allowBlob && source.startsWith('blob:'));
}

Uint8List? decodedBytesForDataUri(String dataUri) {
  final Uint8List? cached = _decodedDataUriCache[dataUri];
  if (cached != null) return cached;

  final int comma = dataUri.indexOf(',');
  if (comma < 0 || comma + 1 >= dataUri.length) return null;

  final Uint8List decoded = base64Decode(dataUri.substring(comma + 1));
  if (_decodedDataUriCache.length >= _memoryImageCacheLimit)
    _decodedDataUriCache.remove(_decodedDataUriCache.keys.first);
  _decodedDataUriCache[dataUri] = decoded;
  return decoded;
}

String resolveBackendImageSource(String source) {
  final String? workingBaseUrl = BackendApiClient.workingBaseUrl;
  if (workingBaseUrl == null) return source;

  try {
    final Uri workingUri = Uri.parse(workingBaseUrl);
    final Uri sourceUri = Uri.parse(source);
    final bool shouldRewrite =
        sourceUri.path.contains('/api/media/') || sourceUri.host == 'localhost' || sourceUri.host == '127.0.0.1';
    if (!shouldRewrite) return source;
    if (!workingUri.hasAuthority) {
      return sourceUri.path +
          (sourceUri.hasQuery ? '?${sourceUri.query}' : '') +
          (sourceUri.hasFragment ? '#${sourceUri.fragment}' : '');
    }
    return sourceUri.replace(scheme: workingUri.scheme, host: workingUri.host, port: workingUri.port).toString();
  } catch (_) {
    return source;
  }
}
