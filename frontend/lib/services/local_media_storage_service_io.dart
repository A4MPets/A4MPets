import 'dart:io';

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

    final String extension = p.extension(selectedFile.path!).toLowerCase();
    final String fileName =
        '${filePrefix}_${DateTime.now().millisecondsSinceEpoch}$extension';
    final String targetPath = p.join(bucketDirectory.path, fileName);

    await File(selectedFile.path!).copy(targetPath);
    return targetPath;
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
