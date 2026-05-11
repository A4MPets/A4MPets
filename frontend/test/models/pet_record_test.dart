import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/pet_record.dart';

/// Tests unitarios para PetRecord (serialización/deserialización)
/// Casos F2: F2-001, F2-002
void main() {
  group('PetRecord - fromMap (F2-001)', () {
    test('fromMap construye PetRecord con todos los campos requeridos', () {
      final int now = DateTime.now().millisecondsSinceEpoch;

      final PetRecord pet = PetRecord.fromMap(<String, Object?>{
        'id': 1,
        'local_uuid': 'pt_test_uuid',
        'remote_id': 'remote_42',
        'name': 'Firulais QA',
        'photo_path': '/storage/pets/firulais.jpg',
        'total_walks': 10,
        'registered_at': now,
        'adoption_date': null,
        'birth_date': null,
        'status': 'normal',
        'is_ownerless': 0,
        'sync_status': 'synced',
        'last_modified_at': now,
        'created_at': now,
        'updated_at': now,
        'needs_sync': 0,
      });

      expect(pet.id, equals(1));
      expect(pet.localUuid, equals('pt_test_uuid'));
      expect(pet.remoteId, equals('remote_42'));
      expect(pet.name, equals('Firulais QA'));
      expect(pet.totalWalks, equals(10));
      expect(pet.status, equals('normal'));
      expect(pet.isOwnerless, isFalse);
      expect(pet.syncStatus, equals('synced'));
      expect(pet.needsSync, isFalse);
    });

    test(
      'fromMap normaliza status "lost" a "perdida" (F2-001 - normalización)',
      () {
        final int now = DateTime.now().millisecondsSinceEpoch;

        final PetRecord pet = PetRecord.fromMap(<String, Object?>{
          'id': 2,
          'status': 'lost',
          'created_at': now,
        });

        expect(pet.status, equals('perdida'));
      },
    );

    test('fromMap normaliza status "perdida" permanece "perdida"', () {
      final int now = DateTime.now().millisecondsSinceEpoch;

      final PetRecord pet = PetRecord.fromMap(<String, Object?>{
        'id': 3,
        'status': 'perdida',
        'created_at': now,
      });

      expect(pet.status, equals('perdida'));
    });

    test('fromMap usa valores por defecto cuando campos son nulos', () {
      final int now = DateTime.now().millisecondsSinceEpoch;

      final PetRecord pet = PetRecord.fromMap(<String, Object?>{
        'id': 4,
        'created_at': now,
      });

      expect(pet.totalWalks, equals(0));
      expect(pet.status, equals('normal'));
      expect(pet.isOwnerless, isFalse);
      expect(pet.syncStatus, equals('created'));
      expect(pet.needsSync, isFalse);
    });

    test('fromMap genera localUuid desde id cuando no se provee (F2-001)', () {
      final int now = DateTime.now().millisecondsSinceEpoch;

      final PetRecord pet = PetRecord.fromMap(<String, Object?>{
        'id': 99,
        'created_at': now,
      });

      expect(pet.localUuid, startsWith('pt_99_'));
    });
  });

  group('PetRecord - toMap (F2-002)', () {
    test('toMap serializa todos los campos en formato correcto', () {
      final DateTime now = DateTime.now();
      final PetRecord pet = PetRecord(
        id: 5,
        localUuid: 'pt_5_qa',
        remoteId: 'remote_5',
        name: 'Luna QA',
        photoPath: '/storage/luna.jpg',
        totalWalks: 3,
        registeredAt: now,
        adoptionDate: null,
        birthDate: null,
        status: 'normal',
        isOwnerless: false,
        syncStatus: 'created',
        lastModifiedAt: now,
        createdAt: now,
        updatedAt: now,
        needsSync: true,
      );

      final Map<String, Object?> map = pet.toMap();

      expect(map['id'], equals(5));
      expect(map['local_uuid'], equals('pt_5_qa'));
      expect(map['name'], equals('Luna QA'));
      expect(map['total_walks'], equals(3));
      expect(map['status'], equals('normal'));
      expect(map['is_ownerless'], equals(0));
      expect(map['needs_sync'], equals(1));
      expect(map['registered_at'], isA<int>());
    });

    test('toMap serializa is_ownerless=true correctamente como 1', () {
      final DateTime now = DateTime.now();
      final PetRecord pet = PetRecord(
        id: 6,
        localUuid: 'pt_6_qa',
        name: null,
        totalWalks: 0,
        registeredAt: now,
        status: 'normal',
        isOwnerless: true,
        syncStatus: 'created',
        lastModifiedAt: now,
        createdAt: now,
        updatedAt: now,
        needsSync: false,
      );

      final Map<String, Object?> map = pet.toMap();
      expect(map['is_ownerless'], equals(1));
    });
  });

  group('PetRecord - computed properties (F2-001 extra)', () {
    test('isLost retorna true cuando status es perdida', () {
      final DateTime now = DateTime.now();
      final PetRecord pet = PetRecord.fromMap(<String, Object?>{
        'id': 7,
        'status': 'perdida',
        'created_at': now.millisecondsSinceEpoch,
      });

      expect(pet.isLost, isTrue);
    });

    test('isLost retorna false cuando status es normal', () {
      final DateTime now = DateTime.now();
      final PetRecord pet = PetRecord.fromMap(<String, Object?>{
        'id': 8,
        'status': 'normal',
        'created_at': now.millisecondsSinceEpoch,
      });

      expect(pet.isLost, isFalse);
    });

    test('displayName retorna "Mascota sin nombre" cuando name es nulo', () {
      final DateTime now = DateTime.now();
      final PetRecord pet = PetRecord.fromMap(<String, Object?>{
        'id': 9,
        'name': null,
        'created_at': now.millisecondsSinceEpoch,
      });

      expect(pet.displayName, equals('Mascota sin nombre'));
    });

    test('displayName retorna el nombre cuando name no es nulo', () {
      final DateTime now = DateTime.now();
      final PetRecord pet = PetRecord.fromMap(<String, Object?>{
        'id': 10,
        'name': 'Rocky QA',
        'created_at': now.millisecondsSinceEpoch,
      });

      expect(pet.displayName, equals('Rocky QA'));
    });
  });

  group('PetRecord - copyWith (F2-002 extra)', () {
    test('copyWith preserva campos no modificados', () {
      final DateTime now = DateTime.now();
      final PetRecord original = PetRecord(
        id: 11,
        localUuid: 'pt_11_qa',
        name: 'Original',
        totalWalks: 5,
        registeredAt: now,
        status: 'normal',
        isOwnerless: false,
        syncStatus: 'synced',
        lastModifiedAt: now,
        createdAt: now,
        updatedAt: now,
        needsSync: false,
      );

      final PetRecord modified = original.copyWith(name: 'Modificado');

      expect(modified.name, equals('Modificado'));
      expect(modified.id, equals(original.id));
      expect(modified.totalWalks, equals(original.totalWalks));
      expect(modified.status, equals(original.status));
    });
  });
}
