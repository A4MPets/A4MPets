import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/lost_pet_report_record.dart';
import '../models/report_comment_record.dart';
import '../repositories/user_local_repository.dart';
import 'async_list_controller.dart';
import 'session_providers.dart';

final lostPetReportsControllerProvider = AsyncNotifierProvider<LostPetReportsController, List<LostPetReportRecord>>(
  LostPetReportsController.new,
);

class LostPetReportsController extends AsyncListController<LostPetReportRecord> {
  UserLocalRepository get _repository => ref.read(userLocalRepositoryProvider);

  @override
  Duration get refreshInterval => const Duration(seconds: 60);

  @override
  Future<List<LostPetReportRecord>> loadItems() => _repository.getLostPetReports();

  Future<void> addLostPetReport({
    required int petId,
    required String petLocalUuid,
    required double lastSeenLatitude,
    required double lastSeenLongitude,
    required String details,
    required DateTime disappearanceDate,
    String? photoUrl,
    required String phone,
  }) async {
    await mutateAndReload(
      () => _repository.addLostPetReport(
        petId: petId,
        petLocalUuid: petLocalUuid,
        lastSeenLatitude: lastSeenLatitude,
        lastSeenLongitude: lastSeenLongitude,
        details: details,
        disappearanceDate: disappearanceDate,
        photoUrl: photoUrl,
        phone: phone,
      ),
    );
  }

  Future<void> addCommentToLostPetReport({required int reportId, required ReportCommentRecord comment}) async {
    await mutateAndReload(() => _repository.addCommentToLostPetReport(reportId: reportId, comment: comment));
  }

  Future<void> deleteLostPetReport({required int reportId, String? remoteId}) async {
    await mutateAndReload(() => _repository.deleteLostPetReport(reportId: reportId, remoteId: remoteId));
  }
}
