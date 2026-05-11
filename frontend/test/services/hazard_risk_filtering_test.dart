import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/hazard_risk_filtering.dart';

/// Tests unitarios para HazardRiskFiltering (lógica pura sin dependencias)
/// Casos F2: F2-007, F2-008
void main() {
  group('HazardRiskFiltering.normalizeSelectedFilters (F2-007)', () {
    test('retorna todos los filtros cuando filters es null', () {
      final Set<String> result = HazardRiskFiltering.normalizeSelectedFilters(
        null,
      );
      expect(result, containsAll(<String>['low', 'medium', 'high', 'other']));
    });

    test('retorna set vacío cuando lista no contiene valores válidos', () {
      final Set<String> result = HazardRiskFiltering.normalizeSelectedFilters(
        <String>['invalid', 'unknown'],
      );
      expect(result, isEmpty);
    });

    test('normaliza a minúsculas y recorta espacios', () {
      final Set<String> result = HazardRiskFiltering.normalizeSelectedFilters(
        <String>['  LOW  ', 'MEDIUM', 'High'],
      );
      expect(result, containsAll(<String>['low', 'medium', 'high']));
    });

    test('filtra valores duplicados (resultado es Set)', () {
      final Set<String> result = HazardRiskFiltering.normalizeSelectedFilters(
        <String>['low', 'low', 'medium'],
      );
      expect(result.length, equals(2));
      expect(result, containsAll(<String>['low', 'medium']));
    });

    test('acepta filtros válidos parciales', () {
      final Set<String> result = HazardRiskFiltering.normalizeSelectedFilters(
        <String>['high', 'other'],
      );
      expect(result, equals(<String>{'high', 'other'}));
    });
  });

  group('HazardRiskFiltering.routingBucketForRiskCode (F2-007)', () {
    test('retorna "low" para código de riesgo bajo', () {
      expect(
        HazardRiskFiltering.routingBucketForRiskCode('low'),
        equals('low'),
      );
    });

    test('retorna "medium" para código de riesgo medio', () {
      expect(
        HazardRiskFiltering.routingBucketForRiskCode('medium'),
        equals('medium'),
      );
    });

    test('retorna "high" para código de riesgo alto', () {
      expect(
        HazardRiskFiltering.routingBucketForRiskCode('high'),
        equals('high'),
      );
    });

    test(
      'retorna "high" para código "undefined" (F2-007 - valor por defecto)',
      () {
        expect(
          HazardRiskFiltering.routingBucketForRiskCode('undefined'),
          equals('high'),
        );
      },
    );

    test('retorna "high" para código nulo (F2-007 - valor por defecto)', () {
      expect(
        HazardRiskFiltering.routingBucketForRiskCode(null),
        equals('high'),
      );
    });
  });

  group('HazardRiskFiltering.shouldConsiderRisk (F2-008)', () {
    test('retorna true cuando el riesgo está en los filtros seleccionados', () {
      final bool result = HazardRiskFiltering.shouldConsiderRisk(
        riskLevelCode: 'high',
        selectedFilters: <String>['high', 'medium'],
      );
      expect(result, isTrue);
    });

    test(
      'retorna false cuando el riesgo NO está en los filtros seleccionados',
      () {
        final bool result = HazardRiskFiltering.shouldConsiderRisk(
          riskLevelCode: 'low',
          selectedFilters: <String>['high', 'medium'],
        );
        expect(result, isFalse);
      },
    );

    test(
      'retorna true para código "undefined" si high está en filtros (F2-008)',
      () {
        final bool result = HazardRiskFiltering.shouldConsiderRisk(
          riskLevelCode: 'undefined',
          selectedFilters: <String>['high'],
        );
        expect(result, isTrue);
      },
    );

    test('retorna false cuando selectedFilters está vacío', () {
      final bool result = HazardRiskFiltering.shouldConsiderRisk(
        riskLevelCode: 'high',
        selectedFilters: <String>[],
      );
      expect(result, isFalse);
    });
  });

  group('HazardRiskFiltering.shouldConsiderOtherReports (F2-008)', () {
    test('retorna true cuando "other" está en selectedFilters', () {
      final bool result = HazardRiskFiltering.shouldConsiderOtherReports(
        selectedFilters: <String>['other', 'low'],
      );
      expect(result, isTrue);
    });

    test('retorna false cuando "other" NO está en selectedFilters', () {
      final bool result = HazardRiskFiltering.shouldConsiderOtherReports(
        selectedFilters: <String>['high', 'medium'],
      );
      expect(result, isFalse);
    });

    test('retorna false cuando selectedFilters está vacío', () {
      final bool result = HazardRiskFiltering.shouldConsiderOtherReports(
        selectedFilters: <String>[],
      );
      expect(result, isFalse);
    });
  });
}
