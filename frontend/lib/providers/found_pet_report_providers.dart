import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/found_pet_report_record.dart';
import '../models/report_comment_record.dart';
import '../repositories/user_local_repository.dart';
import 'async_list_controller.dart';
import 'session_providers.dart';

final foundPetReportsControllerProvider = AsyncNotifierProvider<FoundPetReportsController, List<FoundPetReportRecord>>(
  FoundPetReportsController.new,
);

class FoundPetReportsController extends AsyncListController<FoundPetReportRecord> {
  UserLocalRepository get _repository => ref.read(userLocalRepositoryProvider);

  @override
  Duration get refreshInterval => const Duration(seconds: 60);

  @override
  Future<List<FoundPetReportRecord>> loadItems() => _repository.getFoundPetReports();

  Future<void> addFoundPetReport({
    int? petId,
    String? petLocalUuid,
    int? matchedLostPetReportId,
    required double latitude,
    required double longitude,
    required String details,
    required DateTime foundDate,
    String? photoUrl,
    String? phone,
  }) async {
    await mutateAndReload(
      () => _repository.addFoundPetReport(
        petId: petId,
        petLocalUuid: petLocalUuid,
        matchedLostPetReportId: matchedLostPetReportId,
        latitude: latitude,
        longitude: longitude,
        details: details,
        foundDate: foundDate,
        photoUrl: photoUrl,
        phone: phone,
      ),
    );
  }

  Future<void> addCommentToFoundPetReport({required int reportId, required ReportCommentRecord comment}) async {
    await mutateAndReload(() => _repository.addCommentToFoundPetReport(reportId: reportId, comment: comment));
  }

  Future<void> deleteFoundPetReport({required int reportId, String? remoteId}) async {
    await mutateAndReload(() => _repository.deleteFoundPetReport(reportId: reportId, remoteId: remoteId));
  }
}
