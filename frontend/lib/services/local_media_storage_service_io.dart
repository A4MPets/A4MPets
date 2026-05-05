import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LocalMediaStorageService {
  Future<String?> pickAndStorePetPhoto() async {
    return _pickAndStorePhoto(directoryName: 'pet_photos', filePrefix: 'pet');
  }

  Future<String?> pickAndStoreHazardPhoto() async {
    return _pickAndStorePhoto(
      directoryName: 'hazard_photos',
      filePrefix: 'hazard',
    );
  }

  Future<String?> pickAndStoreLostPetPhoto() async {
    return _pickAndStorePhoto(
      directoryName: 'lost_pet_photos',
      filePrefix: 'lost_pet',
    );
  }

  Future<String?> pickAndStoreFoundPetPhoto() async {
    return _pickAndStorePhoto(
      directoryName: 'found_pet_photos',
      filePrefix: 'found_pet',
    );
  }

  Future<String?> pickAndStoreGenericReportPhoto() async {
    return _pickAndStorePhoto(
      directoryName: 'generic_report_photos',
      filePrefix: 'generic_report',
    );
  }

  Future<String?> pickAndStoreProfilePhoto() async {
    return _pickAndStorePhoto(
      directoryName: 'profile_photos',
      filePrefix: 'profile',
    );
  }

  Future<String?> _pickAndStorePhoto({
    required String directoryName,
    required String filePrefix,
  }) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final PlatformFile selectedFile = result.files.single;
    if (selectedFile.path == null) {
      return null;
    }

    final Directory appDirectory = await getApplicationDocumentsDirectory();
    final Directory bucketDirectory = Directory(
      p.join(appDirectory.path, 'local_bucket', directoryName),
    );

    if (!bucketDirectory.existsSync()) {
      bucketDirectory.createSync(recursive: true);
    }

    final File sourceFile = File(selectedFile.path!);
    final Uint8List sourceBytes = await sourceFile.readAsBytes();
    final int orientation = _readJpegExifOrientation(sourceBytes);
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    if (orientation != 1) {
      final Uint8List? strippedBytes = _stripJpegExif(sourceBytes);
      if (strippedBytes != null) {
        final String targetPath = p.join(
          bucketDirectory.path,
          '${filePrefix}_$timestamp.jpg',
        );
        await File(targetPath).writeAsBytes(strippedBytes);
        return targetPath;
      }
    }

    final String extension = p.extension(selectedFile.path!).toLowerCase();
    final String fileName = '${filePrefix}_$timestamp$extension';
    final String targetPath = p.join(bucketDirectory.path, fileName);

    await sourceFile.copy(targetPath);
    return targetPath;
  }

  int _readJpegExifOrientation(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
      return 1;
    }

    int offset = 2;
    while (offset + 4 <= bytes.length) {
      if (bytes[offset] != 0xFF) {
        offset += 1;
        continue;
      }

      final int marker = bytes[offset + 1];
      offset += 2;
      if (marker == 0xDA || marker == 0xD9) {
        break;
      }
      if (offset + 2 > bytes.length) {
        break;
      }

      final int segmentLength = _readUint16(bytes, offset, littleEndian: false);
      if (segmentLength < 2) {
        break;
      }

      final int segmentStart = offset + 2;
      final int segmentEnd = offset + segmentLength;
      if (segmentEnd > bytes.length) {
        break;
      }

      if (marker == 0xE1 && _hasExifHeader(bytes, segmentStart, segmentEnd)) {
        return _readTiffOrientation(bytes, segmentStart + 6, segmentEnd);
      }

      offset = segmentEnd;
    }

    return 1;
  }

  bool _hasExifHeader(Uint8List bytes, int start, int end) {
    return end - start >= 6 &&
        bytes[start] == 0x45 &&
        bytes[start + 1] == 0x78 &&
        bytes[start + 2] == 0x69 &&
        bytes[start + 3] == 0x66 &&
        bytes[start + 4] == 0x00 &&
        bytes[start + 5] == 0x00;
  }

  int _readTiffOrientation(Uint8List bytes, int tiffStart, int segmentEnd) {
    if (tiffStart + 8 > segmentEnd) {
      return 1;
    }

    final bool littleEndian;
    if (bytes[tiffStart] == 0x49 && bytes[tiffStart + 1] == 0x49) {
      littleEndian = true;
    } else if (bytes[tiffStart] == 0x4D && bytes[tiffStart + 1] == 0x4D) {
      littleEndian = false;
    } else {
      return 1;
    }

    if (_readUint16(bytes, tiffStart + 2, littleEndian: littleEndian) != 42) {
      return 1;
    }

    final int ifdOffset = _readUint32(
      bytes,
      tiffStart + 4,
      littleEndian: littleEndian,
    );
    final int ifdStart = tiffStart + ifdOffset;
    if (ifdStart + 2 > segmentEnd) {
      return 1;
    }

    final int entryCount = _readUint16(
      bytes,
      ifdStart,
      littleEndian: littleEndian,
    );
    for (int index = 0; index < entryCount; index += 1) {
      final int entryOffset = ifdStart + 2 + index * 12;
      if (entryOffset + 12 > segmentEnd) {
        break;
      }

      final int tag = _readUint16(
        bytes,
        entryOffset,
        littleEndian: littleEndian,
      );
      final int type = _readUint16(
        bytes,
        entryOffset + 2,
        littleEndian: littleEndian,
      );
      final int count = _readUint32(
        bytes,
        entryOffset + 4,
        littleEndian: littleEndian,
      );

      if (tag == 0x0112 && type == 3 && count >= 1) {
        return _readUint16(bytes, entryOffset + 8, littleEndian: littleEndian);
      }
    }

    return 1;
  }

  int _readUint16(Uint8List bytes, int offset, {required bool littleEndian}) {
    if (littleEndian) {
      return bytes[offset] | (bytes[offset + 1] << 8);
    }
    return (bytes[offset] << 8) | bytes[offset + 1];
  }

  int _readUint32(Uint8List bytes, int offset, {required bool littleEndian}) {
    if (littleEndian) {
      return bytes[offset] |
          (bytes[offset + 1] << 8) |
          (bytes[offset + 2] << 16) |
          (bytes[offset + 3] << 24);
    }
    return (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
  }

  Uint8List? _stripJpegExif(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
      return null;
    }

    final BytesBuilder output = BytesBuilder(copy: false)
      ..add(bytes.sublist(0, 2));
    int offset = 2;
    while (offset < bytes.length) {
      if (offset + 4 > bytes.length || bytes[offset] != 0xFF) {
        output.add(bytes.sublist(offset));
        break;
      }

      final int marker = bytes[offset + 1];
      if (marker == 0xDA || marker == 0xD9) {
        output.add(bytes.sublist(offset));
        break;
      }

      final int segmentLength = _readUint16(
        bytes,
        offset + 2,
        littleEndian: false,
      );
      final int segmentEnd = offset + 2 + segmentLength;
      if (segmentLength < 2 || segmentEnd > bytes.length) {
        output.add(bytes.sublist(offset));
        break;
      }

      final int segmentStart = offset + 4;
      final bool isExifSegment =
          marker == 0xE1 && _hasExifHeader(bytes, segmentStart, segmentEnd);
      if (!isExifSegment) {
        output.add(bytes.sublist(offset, segmentEnd));
      }
      offset = segmentEnd;
    }

    return output.toBytes();
  }

  Future<void> clearStoredMedia() async {
    final Directory appDirectory = await getApplicationDocumentsDirectory();
    final Directory bucketDirectory = Directory(
      p.join(appDirectory.path, 'local_bucket'),
    );

    if (bucketDirectory.existsSync()) {
      await bucketDirectory.delete(recursive: true);
    }
  }
}
