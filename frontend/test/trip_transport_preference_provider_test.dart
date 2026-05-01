import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/providers/trip_transport_preference_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('trip transport preference persists the last selected value', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(tripTransportPreferenceProvider), 'walking');

    await container
        .read(tripTransportPreferenceProvider.notifier)
        .setTransportName('vehicle');

    expect(container.read(tripTransportPreferenceProvider), 'vehicle');

    SharedPreferences.setMockInitialValues(<String, Object>{
      'trip_transport_method': 'vehicle',
    });
    final ProviderContainer restoredContainer = ProviderContainer();
    addTearDown(restoredContainer.dispose);

    restoredContainer.read(tripTransportPreferenceProvider);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(restoredContainer.read(tripTransportPreferenceProvider), 'vehicle');
  });
}
