import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../providers/session_providers.dart';
import '../services/local_media_storage_service.dart';
import 'reporting_form_widgets.dart';

mixin ReportingPanelState<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool isSaving = false;
  bool isPickingPhoto = false;
  String? storedPhotoUrl;
  String? locationErrorText;
  String? submitValidationErrorText;
  String? saveErrorText;

  LatLng? effectiveReportLocation(LatLng? selected, LatLng? current) {
    return selected ?? current;
  }

  void resetReportErrors([VoidCallback? extraReset]) {
    setState(() {
      locationErrorText = null;
      submitValidationErrorText = null;
      saveErrorText = null;
      extraReset?.call();
    });
  }

  void setSubmitValidationError() {
    setState(() {
      submitValidationErrorText = 'Completa los campos obligatorios para reportar.';
    });
  }

  void clearSubmitError() {
    setState(() => submitValidationErrorText = null);
  }

  void emitPreviewWhenLocationChanges(
    LatLng? oldCurrent,
    LatLng? current,
    LatLng? oldSelected,
    LatLng? selected,
    VoidCallback emitPreview, {
    bool extraChanged = false,
  }) {
    if (oldCurrent != current || oldSelected != selected || extraChanged)
      WidgetsBinding.instance.addPostFrameCallback((_) => emitPreview());
  }

  String? resolvedLocationError({required String? currentLocationErrorText, required bool hasManualLocation}) {
    return locationErrorText ?? (hasManualLocation ? null : currentLocationErrorText);
  }

  Future<void> pickReportPhoto(Future<String?> Function(LocalMediaStorageService service) picker) async {
    setState(() {
      isPickingPhoto = true;
      saveErrorText = null;
    });

    try {
      final String? storedPath = await picker(ref.read(localMediaStorageServiceProvider));
      if (mounted) setState(() => storedPhotoUrl = storedPath);
    } catch (_) {
      if (mounted) {
        setState(() {
          saveErrorText = 'No se pudo cargar la foto. Intenta nuevamente.';
        });
      }
    } finally {
      if (mounted) setState(() => isPickingPhoto = false);
    }
  }

  Future<void> pickReportDate({
    required bool isDarkMode,
    required DateTime initialDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showReportingDatePicker(
      context: context,
      isDarkMode: isDarkMode,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year, now.month, now.day),
    );

    if (picked != null && mounted) setState(() => onPicked(picked));
  }

  Future<void> runReportSave(Future<void> Function() action, {String Function(Object error)? errorMessage}) async {
    setState(() => isSaving = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        setState(() {
          saveErrorText = errorMessage?.call(error) ?? 'No se pudo guardar el reporte. Intenta nuevamente.';
        });
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }
}
