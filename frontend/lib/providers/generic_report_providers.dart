import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/generic_report_record.dart';
import '../models/report_comment_record.dart';
import '../repositories/user_local_repository.dart';
import 'async_list_controller.dart';
import 'session_providers.dart';

final genericReportsControllerProvider =
    AsyncNotifierProvider<GenericReportsController, List<GenericReportRecord>>(
      GenericReportsController.new,
    );

class GenericReportsController
    extends AsyncListController<GenericReportRecord> {
  UserLocalRepository get _repository => ref.read(userLocalRepositoryProvider);

  @override
  Duration get refreshInterval => const Duration(seconds: 60);

  @override
  Future<List<GenericReportRecord>> loadItems() {
    return _repository.getGenericReports();
  }

  Future<void> addGenericReport({
    required double latitude,
    required double longitude,
    required String description,
    required DateTime reportedDate,
    required String riskLevelCode,
    required int impactRadiusMeters,
    String? photoUrl,
  }) async {
    await _repository.addGenericReport(
      latitude: latitude,
      longitude: longitude,
      description: description,
      reportedDate: reportedDate,
      riskLevelCode: riskLevelCode,
      impactRadiusMeters: impactRadiusMeters,
      photoUrl: photoUrl,
    );
    await reload();
  }

  Future<void> syncWithBackend() => reload();

  Future<void> addCommentToGenericReport({
    required int reportId,
    required ReportCommentRecord comment,
  }) async {
    await _repository.addCommentToGenericReport(
      reportId: reportId,
      comment: comment,
    );
    await reload();
  }

  Future<void> deleteGenericReport({
    required int reportId,
    String? remoteId,
  }) async {
    await _repository.deleteGenericReport(
      reportId: reportId,
      remoteId: remoteId,
    );
    await reload();
  }
}
