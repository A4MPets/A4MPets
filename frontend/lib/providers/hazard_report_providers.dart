import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/hazard_report_record.dart';
import '../models/report_comment_record.dart';
import '../repositories/user_local_repository.dart';
import 'async_list_controller.dart';
import 'session_providers.dart';

final hazardReportsControllerProvider =
    AsyncNotifierProvider<HazardReportsController, List<HazardReportRecord>>(
      HazardReportsController.new,
    );

class HazardReportsController extends AsyncListController<HazardReportRecord> {
  UserLocalRepository get _repository => ref.read(userLocalRepositoryProvider);

  @override
  Duration get refreshInterval => const Duration(seconds: 60);

  @override
  Future<List<HazardReportRecord>> loadItems() {
    return _repository.getHazardReports();
  }

  Future<void> addHazardReport({
    required double incidentLatitude,
    required double incidentLongitude,
    required int impactRadiusMeters,
    required String categoryCode,
    required String narrativeDescription,
    required DateTime reportedAt,
    required String estimatedDurationCode,
    required String riskLevelCode,
    String? evidencePhotoUrl,
    required String reportedByUsername,
  }) async {
    await _repository.addHazardReport(
      incidentLatitude: incidentLatitude,
      incidentLongitude: incidentLongitude,
      impactRadiusMeters: impactRadiusMeters,
      categoryCode: categoryCode,
      narrativeDescription: narrativeDescription,
      reportedAt: reportedAt,
      estimatedDurationCode: estimatedDurationCode,
      riskLevelCode: riskLevelCode,
      evidencePhotoUrl: evidencePhotoUrl,
      reportedByUsername: reportedByUsername,
    );
    await reload();
  }

  Future<void> addCommentToHazard({
    required int hazardId,
    required ReportCommentRecord comment,
  }) async {
    await _repository.addCommentToHazard(hazardId: hazardId, comment: comment);
    await reload();
  }

  Future<void> deleteHazardReport({
    required int hazardId,
    String? remoteId,
  }) async {
    await _repository.deleteHazardReport(
      hazardId: hazardId,
      remoteId: remoteId,
    );
    await reload();
  }

  Future<void> syncWithBackend() => reload();
}
