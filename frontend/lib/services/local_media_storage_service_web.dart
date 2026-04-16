import 'dart:convert';

import 'package:file_picker/file_picker.dart';

class LocalMediaStorageService {
  Future<String?> pickAndStorePetPhoto() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final PlatformFile selectedFile = result.files.single;
    final List<int>? bytes = selectedFile.bytes;
    if (bytes == null || bytes.isEmpty) {
      return null;
    }

    final String extension = _safeFileExtension(selectedFile.extension);
    final String mimeType = _guessMimeType(extension);
    final String base64Value = base64Encode(bytes);
    return 'data:$mimeType;base64,$base64Value';
  }

  Future<String?> pickAndStoreHazardPhoto() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final PlatformFile selectedFile = result.files.single;
    final List<int>? bytes = selectedFile.bytes;
    if (bytes == null || bytes.isEmpty) {
      return null;
    }

    final String extension = _safeFileExtension(selectedFile.extension);
    final String mimeType = _guessMimeType(extension);
    final String base64Value = base64Encode(bytes);
    return 'data:$mimeType;base64,$base64Value';
  }

  Future<void> clearStoredMedia() async {}

  String _safeFileExtension(String? extension) {
    if (extension == null || extension.isEmpty) {
      return 'png';
    }
    return extension.toLowerCase();
  }

  String _guessMimeType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      default:
        return 'image/png';
    }
  }
}
