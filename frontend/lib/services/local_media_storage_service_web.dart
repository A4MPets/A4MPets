import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'jpeg_exif_tools.dart';

class LocalMediaStorageService {
  Future<String?> pickAndStorePetPhoto() => _pickAndStoreDataUriImage();

  Future<String?> pickAndStoreHazardPhoto() => _pickAndStoreDataUriImage();

  Future<String?> pickAndStoreLostPetPhoto() => _pickAndStoreDataUriImage();

  Future<String?> pickAndStoreFoundPetPhoto() => _pickAndStoreDataUriImage();

  Future<String?> pickAndStoreGenericReportPhoto() => _pickAndStoreDataUriImage();

  Future<String?> pickAndStoreProfilePhoto() => _pickAndStoreDataUriImage();

  Future<String?> _pickAndStoreDataUriImage() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final PlatformFile selectedFile = result.files.single;
    final List<int>? bytes = selectedFile.bytes;
    if (bytes == null || bytes.isEmpty) return null;

    final Uint8List sourceBytes = Uint8List.fromList(bytes);
    final int orientation = readJpegExifOrientation(sourceBytes);
    if (orientation != 1) {
      final Uint8List? strippedBytes = stripJpegExif(sourceBytes);
      if (strippedBytes != null) {
        return 'data:image/jpeg;base64,${base64Encode(strippedBytes)}';
      }
    }

    final String extension = _safeFileExtension(selectedFile.extension);
    final String mimeType = _guessMimeType(extension);
    final String base64Value = base64Encode(sourceBytes);
    return 'data:$mimeType;base64,$base64Value';
  }

  Future<void> clearStoredMedia() async {}

  String _safeFileExtension(String? extension) {
    if (extension == null || extension.isEmpty) return 'png';
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
