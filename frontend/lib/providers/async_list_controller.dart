import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared AsyncNotifier foundation for list-oriented controllers.
abstract class AsyncListController<T> extends AsyncNotifier<List<T>> {
  static const bool _disableBackgroundRefresh = bool.fromEnvironment(
    'A4M_DISABLE_BACKGROUND_REFRESH',
    defaultValue: false,
  );

  Timer? _refreshTimer;
  bool _isDisposed = false;

  @override
  Future<List<T>> build() async {
    _registerRefreshLifecycle();
    unawaited(runInitialSync());
    return loadItems();
  }

  /// Loads the current collection from its backing repository.
  Future<List<T>> loadItems();

  /// Runs a best-effort background sync during initialization.
  Future<void> runInitialSync() async {}

  /// Polling interval for controllers that need silent background refreshes.
  Duration? get refreshInterval => null;

  /// Reloads the collection while keeping previous data visible in the UI.
  Future<void> reload() async {
    state = AsyncLoading<List<T>>().copyWithPrevious(state);
    state = await AsyncValue.guard(loadItems);
  }

  Future<void> silentlyRefresh() async {
    try {
      final List<T> latest = await loadItems();
      if (!_isDisposed) {
        state = AsyncData<List<T>>(latest);
      }
    } catch (_) {
      // Preserve the last successful UI state on refresh failures.
    }
  }

  void _registerRefreshLifecycle() {
    if (_disableBackgroundRefresh) {
      ref.onDispose(() {
        _isDisposed = true;
      });
      return;
    }

    final Duration? interval = refreshInterval;
    if (interval != null) {
      _refreshTimer ??= Timer.periodic(interval, (_) async {
        if (_isDisposed) {
          return;
        }

        await silentlyRefresh();
      });
    }

    ref.onDispose(() {
      _isDisposed = true;
      _refreshTimer?.cancel();
      _refreshTimer = null;
    });
  }
}
