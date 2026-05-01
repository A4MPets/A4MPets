import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/services/local_database_manager_web.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('lost pet report persists and does not duplicate pet photo', () async {
    final LocalDatabaseManager manager = LocalDatabaseManager();
    final String largePhoto = 'data:image/png;base64,${'a' * 12000}';

    final int petId = await manager.addPet(name: 'Milo', photoPath: largePhoto);
    final pet = (await manager.getPets()).single;

    await manager.addLostPetReport(
      petId: petId,
      petLocalUuid: pet.localUuid,
      lastSeenLatitude: 3.4516,
      lastSeenLongitude: -76.5320,
      details: 'Collar azul',
      disappearanceDate: DateTime(2026, 5),
      photoUrl: largePhoto,
      phone: '5551234',
    );

    final LocalDatabaseManager reloadedManager = LocalDatabaseManager();
    final reports = await reloadedManager.getLostPetReports();
    final pets = await reloadedManager.getPets();

    expect(reports, hasLength(1));
    expect(reports.single.photoUrl, isNull);
    expect(reports.single.needsSync, isTrue);
    expect(pets.single.status, 'perdida');
  });

  test(
    'marking one lost pet report synced preserves deleted reports',
    () async {
      final LocalDatabaseManager manager = LocalDatabaseManager();
      final int firstPetId = await manager.addPet(name: 'Milo');
      final firstPet = (await manager.getPets()).single;

      await manager.addLostPetReport(
        petId: firstPetId,
        petLocalUuid: firstPet.localUuid,
        lastSeenLatitude: 3.4516,
        lastSeenLongitude: -76.5320,
        details: 'Primer reporte',
        disappearanceDate: DateTime(2026, 5),
        phone: '5551234',
      );
      final firstReport = (await manager.getLostPetReports()).single;

      final int secondPetId = await manager.addPet(name: 'Luna');
      final secondPet = (await manager.getPets()).firstWhere(
        (pet) => pet.id == secondPetId,
      );
      await manager.addLostPetReport(
        petId: secondPetId,
        petLocalUuid: secondPet.localUuid,
        lastSeenLatitude: 3.4517,
        lastSeenLongitude: -76.5321,
        details: 'Segundo reporte',
        disappearanceDate: DateTime(2026, 5),
        phone: '5554321',
      );
      final secondReport = (await manager.getLostPetReports()).firstWhere(
        (report) => report.petLocalUuid == secondPet.localUuid,
      );

      await manager.deleteLostPetReport(reportId: firstReport.id);
      await manager.markLostPetReportAsSynced(
        localUuid: secondReport.localUuid,
        remoteId: '99',
      );

      final pending = await manager.getLostPetReportsNeedingSync();
      expect(
        pending.map((report) => report.localUuid),
        contains(firstReport.localUuid),
      );
      expect(
        pending.map((report) => report.localUuid),
        isNot(contains(secondReport.localUuid)),
      );
    },
  );
}
