import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/lost_pet_report_record.dart';
import '../models/report_comment_record.dart';
import '../repositories/user_local_repository.dart';
import 'async_list_controller.dart';
import 'session_providers.dart';

final lostPetReportsControllerProvider =
    AsyncNotifierProvider<LostPetReportsController, List<LostPetReportRecord>>(
      LostPetReportsController.new,
    );

class LostPetReportsController
    extends AsyncListController<LostPetReportRecord> {
  UserLocalRepository get _repository => ref.read(userLocalRepositoryProvider);

  @override
  Duration get refreshInterval => const Duration(seconds: 60);

  @override
  Future<List<LostPetReportRecord>> loadItems() {
    return _repository.getLostPetReports();
  }

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
    await _repository.addLostPetReport(
      petId: petId,
      petLocalUuid: petLocalUuid,
      lastSeenLatitude: lastSeenLatitude,
      lastSeenLongitude: lastSeenLongitude,
      details: details,
      disappearanceDate: disappearanceDate,
      photoUrl: photoUrl,
      phone: phone,
    );
    await reload();
  }

  Future<void> syncWithBackend() => reload();

  Future<void> addCommentToLostPetReport({
    required int reportId,
    required ReportCommentRecord comment,
  }) async {
    await _repository.addCommentToLostPetReport(
      reportId: reportId,
      comment: comment,
    );
    await reload();
  }

  Future<void> deleteLostPetReport({
    required int reportId,
    String? remoteId,
  }) async {
    await _repository.deleteLostPetReport(
      reportId: reportId,
      remoteId: remoteId,
    );
    await reload();
  }
}
