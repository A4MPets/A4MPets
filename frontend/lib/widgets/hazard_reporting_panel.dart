import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../providers/local_data_providers.dart';
import '../theme/app_palette.dart';
import 'shared/local_image_widget.dart';

class ReportHazardPanelContent extends ConsumerStatefulWidget {
  final bool isDarkMode;
  final LatLng? developerSelectedLocation;
  final bool isDeveloperSelectingOnMap;
  final VoidCallback onStartDeveloperMapSelection;
  final VoidCallback onClearDeveloperLocation;
  final VoidCallback onReported;

  const ReportHazardPanelContent({
    super.key,
    required this.isDarkMode,
    required this.developerSelectedLocation,
    required this.isDeveloperSelectingOnMap,
    required this.onStartDeveloperMapSelection,
    required this.onClearDeveloperLocation,
    required this.onReported,
  });

  @override
  ConsumerState<ReportHazardPanelContent> createState() =>
      _ReportHazardPanelContentState();
}

class _ReportHazardPanelContentState
    extends ConsumerState<ReportHazardPanelContent> {
  static const List<_SelectionOption> _categoryOptions = <_SelectionOption>[
    _SelectionOption('contagious_disease', 'Enfermedad contagiosa'),
    _SelectionOption('stagnant_water', 'Aguas estancadas'),
    _SelectionOption('waste_accumulation', 'Acumulación de residuos'),
    _SelectionOption('aggressive_animals', 'Animales agresivos'),
    _SelectionOption('undefined', 'No lo sé'),
  ];

  static const List<_SelectionOption> _durationOptions = <_SelectionOption>[
    _SelectionOption('undefined', 'No lo sé'),
    _SelectionOption('1_day', '1 Día'),
    _SelectionOption('3_days', '3 Días'),
    _SelectionOption('1_week', '1 semana'),
    _SelectionOption('2_weeks', '2 semanas'),
    _SelectionOption('1_month', '1 mes'),
    _SelectionOption('3_months', '3 meses'),
    _SelectionOption('6_months', '6 meses'),
    _SelectionOption('1_year', '1 año'),
  ];

  static const List<_SelectionOption> _riskOptions = <_SelectionOption>[
    _SelectionOption('low', 'Bajo'),
    _SelectionOption('medium', 'Medio'),
    _SelectionOption('high', 'Alto'),
    _SelectionOption('undefined', 'No lo sé'),
  ];

  late final TextEditingController _descriptionController;

  LatLng? _currentLocation;
  String _selectedCategoryCode = 'undefined';
  String _selectedDurationCode = 'undefined';
  String _selectedRiskLevelCode = 'undefined';
  int _selectedImpactRadiusMeters = 10;
  String? _storedEvidencePhotoUrl;

  late final DateTime _reportedAt;
  bool _isLoadingLocation = true;
  bool _isSaving = false;
  bool _isPickingPhoto = false;
  String? _locationErrorText;
  String? _descriptionErrorText;
  String? _saveErrorText;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _reportedAt = DateTime.now();
    _resolveCurrentLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _resolveCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) {
          return;
        }
        setState(() {
          _currentLocation = null;
          _isLoadingLocation = false;
          _locationErrorText =
              'Debes habilitar la ubicación para reportar un peligro.';
        });
        return;
      }

      final Position position = await Geolocator.getCurrentPosition();

      if (!mounted) {
        return;
      }

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
        _locationErrorText = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _currentLocation = null;
        _isLoadingLocation = false;
        _locationErrorText =
            'No se pudo obtener tu ubicación actual. Revisa permisos e inténtalo nuevamente.';
      });
    }
  }

  Future<void> _pickEvidencePhoto() async {
    setState(() {
      _isPickingPhoto = true;
    });

    try {
      final String? storedPath = await ref
          .read(localMediaStorageServiceProvider)
          .pickAndStoreHazardPhoto();

      if (!mounted) {
        return;
      }

      setState(() {
        _storedEvidencePhotoUrl = storedPath;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saveErrorText = 'No se pudo cargar la foto. Intenta nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPickingPhoto = false;
        });
      }
    }
  }

  Future<void> _saveHazardReport() async {
    final LatLng? resolvedLocation =
        widget.developerSelectedLocation ?? _currentLocation;

    setState(() {
      _locationErrorText = null;
      _descriptionErrorText = null;
      _saveErrorText = null;
    });

    if (resolvedLocation == null) {
      setState(() {
        _locationErrorText = 'Necesitamos tu ubicación actual para reportar.';
      });
      return;
    }

    final String narrativeDescription = _descriptionController.text.trim();
    if (narrativeDescription.isEmpty) {
      setState(() {
        _descriptionErrorText = 'La descripción del peligro es obligatoria.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final profile = await ref.read(localUserProfileProvider.future);
      final String reporterName = profile.isAuthenticated
          ? profile.username
          : 'Anónimo';

      await ref.read(hazardReportsControllerProvider.notifier).addHazardReport(
            incidentLatitude: resolvedLocation.latitude,
            incidentLongitude: resolvedLocation.longitude,
            impactRadiusMeters: _selectedImpactRadiusMeters,
            categoryCode: _selectedCategoryCode,
            narrativeDescription: narrativeDescription,
            reportedAt: _reportedAt,
            estimatedDurationCode: _selectedDurationCode,
            riskLevelCode: _selectedRiskLevelCode,
            evidencePhotoUrl: _storedEvidencePhotoUrl,
            reportedByUsername: reporterName,
          );

      if (!mounted) {
        return;
      }

      widget.onReported();
    } catch (error) {
      debugPrint('Error guardando hazard report: $error');
      if (!mounted) {
        return;
      }
      setState(() {
        _saveErrorText = 'No se pudo guardar el reporte. Intenta nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (kDebugMode)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _FixedLocationBanner(
                          isDarkMode: widget.isDarkMode,
                          isLoading: _isLoadingLocation,
                          location: _currentLocation,
                          onRetry: _resolveCurrentLocation,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DeveloperLocationBanner(
                          isDarkMode: widget.isDarkMode,
                          isSelectingOnMap: widget.isDeveloperSelectingOnMap,
                          selectedLocation: widget.developerSelectedLocation,
                          onStartSelection: widget.onStartDeveloperMapSelection,
                          onClearSelection: widget.onClearDeveloperLocation,
                        ),
                      ),
                    ],
                  )
                else
                  _FixedLocationBanner(
                    isDarkMode: widget.isDarkMode,
                    isLoading: _isLoadingLocation,
                    location: _currentLocation,
                    onRetry: _resolveCurrentLocation,
                  ),
                if (_locationErrorText != null) ...[
                  const SizedBox(height: 6),
                  _FieldErrorText(message: _locationErrorText!),
                ],
                const SizedBox(height: 12),
                _LabeledField(
                  label: 'Radio de afectación (metros)',
                  child: _buildImpactRadiusDropdown(),
                ),
                const SizedBox(height: 10),
                Text(
                  'Valor seleccionado: $_selectedImpactRadiusMeters m',
                  style: const TextStyle(
                    color: AppPalette.textMutedDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                _LabeledField(
                  label: 'Categoría',
                  child: _buildDropdown(
                    value: _selectedCategoryCode,
                    items: _categoryOptions,
                    onChanged: (String value) {
                      setState(() {
                        _selectedCategoryCode = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),
                _LabeledField(
                  label: 'Descripción del peligro',
                  child: _buildTextField(
                    controller: _descriptionController,
                    hintText: 'Describe lo que observas en el lugar',
                    maxLines: 4,
                    errorText: _descriptionErrorText,
                    onSubmitted: (_) {
                      if (!_isSaving) {
                        _saveHazardReport();
                      }
                    },
                    onChanged: (String value) {
                      if (_descriptionErrorText != null &&
                          value.trim().isNotEmpty) {
                        setState(() {
                          _descriptionErrorText = null;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 10),
                _LabeledField(
                  label: 'Duración aproximada',
                  child: _buildDropdown(
                    value: _selectedDurationCode,
                    items: _durationOptions,
                    onChanged: (String value) {
                      setState(() {
                        _selectedDurationCode = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),
                _LabeledField(
                  label: 'Nivel de riesgo',
                  child: _buildDropdown(
                    value: _selectedRiskLevelCode,
                    items: _riskOptions,
                    onChanged: (String value) {
                      setState(() {
                        _selectedRiskLevelCode = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),
                _LabeledField(
                  label: 'Foto (opcional)',
                  child: _EvidencePhotoField(
                    isDarkMode: widget.isDarkMode,
                    photoSource: _storedEvidencePhotoUrl,
                    isBusy: _isPickingPhoto,
                    onPickPressed: _pickEvidencePhoto,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_saveErrorText != null) ...[
          _FieldErrorText(message: _saveErrorText!),
          const SizedBox(height: 10),
        ],
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveHazardReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.primaryBlue,
              foregroundColor: AppPalette.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppPalette.white,
                    ),
                  )
                : const Text(
                    'Reportar',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? errorText,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    final Color textColor = AppPalette.textPrimary(widget.isDarkMode);
    final bool hasError = errorText != null;

    final TextField textField = TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      textInputAction:
          onSubmitted != null ? TextInputAction.done : TextInputAction.newline,
      onSubmitted: onSubmitted,
      style: TextStyle(
        color: textColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppPalette.textMutedDark,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: AppPalette.fieldBackground(widget.isDarkMode),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: hasError
              ? const BorderSide(color: AppPalette.dangerRed, width: 1)
              : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: hasError ? AppPalette.dangerRed : AppPalette.primaryBlue,
            width: 1,
          ),
        ),
        errorText: errorText,
        errorStyle: const TextStyle(
          color: AppPalette.dangerRed,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    if (onSubmitted == null) {
      return textField;
    }

    return Focus(
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter &&
            !HardwareKeyboard.instance.isShiftPressed) {
          onSubmitted(controller.text);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: textField,
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<_SelectionOption> items,
    required ValueChanged<String> onChanged,
  }) {
    final Color textColor = AppPalette.textPrimary(widget.isDarkMode);

    return DropdownButtonFormField<String>(
      initialValue: value,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      dropdownColor: AppPalette.fieldBackground(widget.isDarkMode),
      style: TextStyle(
        color: textColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppPalette.fieldBackground(widget.isDarkMode),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppPalette.primaryBlue, width: 1),
        ),
      ),
      items: items
          .map(
            (_SelectionOption option) => DropdownMenuItem<String>(
              value: option.code,
              child: Text(option.label),
            ),
          )
          .toList(growable: false),
      onChanged: (String? nextValue) {
        if (nextValue == null) {
          return;
        }
        onChanged(nextValue);
      },
    );
  }

  Widget _buildImpactRadiusDropdown() {
    return DropdownButtonFormField<int>(
      initialValue: _selectedImpactRadiusMeters,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      dropdownColor: AppPalette.fieldBackground(widget.isDarkMode),
      style: TextStyle(
        color: AppPalette.textPrimary(widget.isDarkMode),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppPalette.fieldBackground(widget.isDarkMode),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppPalette.primaryBlue, width: 1),
        ),
      ),
      items: const <int>[1, 10, 100, 300]
          .map(
            (int value) => DropdownMenuItem<int>(
              value: value,
              child: Text('$value m'),
            ),
          )
          .toList(growable: false),
      onChanged: (int? nextValue) {
        if (nextValue == null) {
          return;
        }
        setState(() {
          _selectedImpactRadiusMeters = nextValue;
        });
      },
    );
  }
}

class _FieldErrorText extends StatelessWidget {
  final String message;

  const _FieldErrorText({required this.message});

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(
        color: AppPalette.dangerRed,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppPalette.textMutedDark,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _FixedLocationBanner extends StatelessWidget {
  final bool isDarkMode;
  final bool isLoading;
  final LatLng? location;
  final VoidCallback onRetry;

  const _FixedLocationBanner({
    required this.isDarkMode,
    required this.isLoading,
    required this.location,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor = AppPalette.border(isDarkMode);
    final Color textColor = AppPalette.textPrimary(isDarkMode);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ubicación automática',
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          if (isLoading)
            const Text(
              'Obteniendo ubicación actual...',
              style: TextStyle(
                color: AppPalette.textMutedDark,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            )
          else if (location == null)
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'No se pudo obtener la ubicación. Activa permisos y reintenta.',
                    style: TextStyle(
                      color: AppPalette.textMutedDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onRetry,
                  child: const Text('Reintentar'),
                ),
              ],
            )
          else
            Text(
              'Debes estar físicamente en el lugar para reportar. '
              'Lat: ${location!.latitude.toStringAsFixed(6)}, '
              'Lng: ${location!.longitude.toStringAsFixed(6)}',
              style: const TextStyle(
                color: AppPalette.textMutedDark,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

class _EvidencePhotoField extends StatelessWidget {
  final bool isDarkMode;
  final String? photoSource;
  final bool isBusy;
  final VoidCallback onPickPressed;

  const _EvidencePhotoField({
    required this.isDarkMode,
    required this.photoSource,
    required this.isBusy,
    required this.onPickPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor = AppPalette.border(isDarkMode);

    return Container(
      height: 118,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: photoSource != null && photoSource!.isNotEmpty
                  ? buildLocalImageWidget(
                      source: photoSource,
                      fit: BoxFit.cover,
                      fallback: const _PhotoPlaceholder(),
                      errorBuilder: (_, __, ___) => const _PhotoPlaceholder(),
                    )
                  : const _PhotoPlaceholder(),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: SizedBox(
              width: 34,
              height: 34,
              child: Material(
                color: AppPalette.white,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: isBusy ? null : onPickPressed,
                  customBorder: const CircleBorder(),
                  child: isBusy
                      ? const Padding(
                          padding: EdgeInsets.all(9),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppPalette.charcoal,
                          ),
                        )
                      : const Icon(
                          Icons.edit,
                          size: 18,
                          color: AppPalette.charcoal,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeveloperLocationBanner extends StatelessWidget {
  final bool isDarkMode;
  final bool isSelectingOnMap;
  final LatLng? selectedLocation;
  final VoidCallback onStartSelection;
  final VoidCallback onClearSelection;

  const _DeveloperLocationBanner({
    required this.isDarkMode,
    required this.isSelectingOnMap,
    required this.selectedLocation,
    required this.onStartSelection,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor = AppPalette.border(isDarkMode);
    final Color textColor = AppPalette.textPrimary(isDarkMode);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ubicación dev (debug)',
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isSelectingOnMap
                ? 'Selecciona un punto tocando el mapa.'
                : selectedLocation == null
                    ? 'Sin ubicación manual seleccionada.'
                    : 'Lat: ${selectedLocation!.latitude.toStringAsFixed(6)}\nLng: ${selectedLocation!.longitude.toStringAsFixed(6)}',
            style: const TextStyle(
              color: AppPalette.textMutedDark,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onStartSelection,
                  child: const Text('Marcar en mapa'),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextButton(
                  onPressed: selectedLocation == null ? null : onClearSelection,
                  child: const Text('Limpiar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppPalette.placeholderGray,
      child: const Center(
        child: Icon(
          Icons.warning_amber_rounded,
          size: 38,
          color: AppPalette.iconGray,
        ),
      ),
    );
  }
}

class _SelectionOption {
  final String code;
  final String label;

  const _SelectionOption(this.code, this.label);
}
