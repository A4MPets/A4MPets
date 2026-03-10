import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LocalMediaStorageService {
  Future<String?> pickAndStorePetPhoto() async {
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
      p.join(appDirectory.path, 'local_bucket', 'pet_photos'),
    );

    if (!bucketDirectory.existsSync()) {
      bucketDirectory.createSync(recursive: true);
    }

    final String extension = p.extension(selectedFile.path!).toLowerCase();
    final String fileName = 'pet_${DateTime.now().millisecondsSinceEpoch}$extension';
    final String targetPath = p.join(bucketDirectory.path, fileName);

    await File(selectedFile.path!).copy(targetPath);
    return targetPath;
  }
}
