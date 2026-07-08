import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'jpeg_exif_tools.dart';

class LocalMediaStorageService {
  Future<String?> pickAndStorePetPhoto() => _pickAndStorePhoto(directoryName: 'pet_photos', filePrefix: 'pet');

  Future<String?> pickAndStoreHazardPhoto() => _pickAndStorePhoto(directoryName: 'hazard_photos', filePrefix: 'hazard');

  Future<String?> pickAndStoreLostPetPhoto() =>
      _pickAndStorePhoto(directoryName: 'lost_pet_photos', filePrefix: 'lost_pet');

  Future<String?> pickAndStoreFoundPetPhoto() =>
      _pickAndStorePhoto(directoryName: 'found_pet_photos', filePrefix: 'found_pet');

  Future<String?> pickAndStoreGenericReportPhoto() =>
      _pickAndStorePhoto(directoryName: 'generic_report_photos', filePrefix: 'generic_report');

  Future<String?> pickAndStoreProfilePhoto() =>
      _pickAndStorePhoto(directoryName: 'profile_photos', filePrefix: 'profile');

  Future<String?> _pickAndStorePhoto({required String directoryName, required String filePrefix}) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
      withData: false,
    );

    if (result == null || result.files.isEmpty) return null;

    final PlatformFile selectedFile = result.files.single;
    if (selectedFile.path == null) return null;

    final Directory appDirectory = await getApplicationDocumentsDirectory();
    final Directory bucketDirectory = Directory(p.join(appDirectory.path, 'local_bucket', directoryName));

    if (!bucketDirectory.existsSync()) bucketDirectory.createSync(recursive: true);

    final File sourceFile = File(selectedFile.path!);
    final Uint8List sourceBytes = await sourceFile.readAsBytes();
    final int orientation = readJpegExifOrientation(sourceBytes);
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    if (orientation != 1) {
      final Uint8List? strippedBytes = stripJpegExif(sourceBytes);
      if (strippedBytes != null) {
        final String targetPath = p.join(bucketDirectory.path, '${filePrefix}_$timestamp.jpg');
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

  Future<void> clearStoredMedia() async {
    final Directory appDirectory = await getApplicationDocumentsDirectory();
    final Directory bucketDirectory = Directory(p.join(appDirectory.path, 'local_bucket'));

    if (bucketDirectory.existsSync()) await bucketDirectory.delete(recursive: true);
  }
}
