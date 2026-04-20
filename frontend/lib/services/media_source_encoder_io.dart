import 'dart:convert';
import 'dart:io';

Future<String?> encodeImageSourceToDataUri(String source) async {
  if (source.startsWith('data:image')) {
    return source;
  }

  if (source.startsWith('http://') || source.startsWith('https://')) {
    return null;
  }

  final File file = File(source);
  if (!await file.exists()) {
    return null;
  }

  final List<int> bytes = await file.readAsBytes();
  if (bytes.isEmpty) {
    return null;
  }

  final String mime = _mimeFromPath(source);
  return 'data:$mime;base64,${base64Encode(bytes)}';
}

String _mimeFromPath(String path) {
  final String lower = path.toLowerCase();
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
    return 'image/jpeg';
  }
  if (lower.endsWith('.gif')) {
    return 'image/gif';
  }
  if (lower.endsWith('.webp')) {
    return 'image/webp';
  }
  if (lower.endsWith('.bmp')) {
    return 'image/bmp';
  }
  return 'image/png';
}
