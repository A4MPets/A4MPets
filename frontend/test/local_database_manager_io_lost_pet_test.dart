import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/services/local_database_manager_io.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel pathProviderChannel = MethodChannel(
    'plugins.flutter.io/path_provider',
  );
  late Directory tempDirectory;
  final List<LocalDatabaseManager> managers = <LocalDatabaseManager>[];

  setUp(() async {
    managers.clear();
    tempDirectory = await Directory.systemTemp.createTemp('a4mpets_db_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (MethodCall call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            return tempDirectory.path;
          }
          return null;
        });
  });

  tearDown(() async {
    for (final LocalDatabaseManager manager in managers) {
      await manager.close();
    }
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('creates lost pet report and marks pet as lost', () async {
    final LocalDatabaseManager manager = LocalDatabaseManager();
    managers.add(manager);
    final int petId = await manager.addPet(
      name: 'Milo',
      photoPath: 'data:image/png;base64,aaaa',
    );
    final pet = (await manager.getPets()).single;

    await manager.addLostPetReport(
      petId: petId,
      petLocalUuid: pet.localUuid,
      lastSeenLatitude: 3.4516,
      lastSeenLongitude: -76.5320,
      details: 'Collar azul',
      disappearanceDate: DateTime(2026, 5),
      photoUrl: pet.photoPath,
      phone: '5551234',
    );

    final reports = await manager.getLostPetReports();
    final pets = await manager.getPets();

    expect(reports, hasLength(1));
    expect(reports.single.photoUrl, isNull);
    expect(reports.single.needsSync, isTrue);
    expect(pets.single.status, 'perdida');
  });

  test('duplicate active report returns explicit error', () async {
    final LocalDatabaseManager manager = LocalDatabaseManager();
    managers.add(manager);
    final int petId = await manager.addPet(name: 'Luna');
    final pet = (await manager.getPets()).single;

    Future<void> addReport() {
      return manager.addLostPetReport(
        petId: petId,
        petLocalUuid: pet.localUuid,
        lastSeenLatitude: 3.4516,
        lastSeenLongitude: -76.5320,
        details: 'Collar rojo',
        disappearanceDate: DateTime(2026, 5),
        phone: '5551234',
      );
    }

    await addReport();

    expect(
      addReport,
      throwsA(
        isA<StateError>().having(
          (StateError error) => error.message,
          'message',
          contains('reporte activo'),
        ),
      ),
    );
  });
}
