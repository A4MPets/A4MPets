import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../providers/local_data_providers.dart';
import '../theme/app_palette.dart';
import 'shared/local_image_widget.dart';

class HazardDraftPreview {
  final LatLng? location;
  final int impactRadiusMeters;
  final String riskLevelCode;
  final bool isSelectingOnMap;

  const HazardDraftPreview({
    required this.location,
    required this.impactRadiusMeters,
    required this.riskLevelCode,
    required this.isSelectingOnMap,
  });
}

class ReportHazardPanelContent extends ConsumerStatefulWidget {
  final bool isDarkMode;
  final LatLng? currentDeviceLocation;
  final bool isLoadingCurrentLocation;
  final String? currentLocationErrorText;
  final LatLng? selectedHazardLocation;
  final bool isSelectingHazardLocationOnMap;
  final VoidCallback onStartMapSelection;
  final VoidCallback onUseCurrentLocation;
  final ValueChanged<HazardDraftPreview> onPreviewChanged;
  final VoidCallback onReported;

  const ReportHazardPanelContent({
    super.key,
    required this.isDarkMode,
    required this.currentDeviceLocation,
    required this.isLoadingCurrentLocation,
    required this.currentLocationErrorText,
    required this.selectedHazardLocation,
    required this.isSelectingHazardLocationOnMap,
    required this.onStartMapSelection,
    required this.onUseCurrentLocation,
    required this.onPreviewChanged,
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
    _SelectionOption('waste_accumulation', 'Acumulacion de residuos'),
    _SelectionOption('aggressive_animals', 'Animales agresivos'),
    _SelectionOption('undefined', 'No lo se'),
  ];

  static const List<_SelectionOption> _durationOptions = <_SelectionOption>[
    _SelectionOption('undefined', 'No lo se'),
    _SelectionOption('1_day', '1 Dia'),
    _SelectionOption('3_days', '3 Dias'),
    _SelectionOption('1_week', '1 semana'),
    _SelectionOption('2_weeks', '2 semanas'),
    _SelectionOption('1_month', '1 mes'),
    _SelectionOption('3_months', '3 meses'),
    _SelectionOption('6_months', '6 meses'),
    _SelectionOption('1_year', '1 ano'),
  ];

  static const List<_SelectionOption> _riskOptions = <_SelectionOption>[
    _SelectionOption('low', 'Bajo'),
    _SelectionOption('medium', 'Medio'),
    _SelectionOption('high', 'Alto'),
    _SelectionOption('undefined', 'No lo se'),
  ];

  late final TextEditingController _descriptionController;

  String _selectedCategoryCode = 'undefined';
  String _selectedDurationCode = 'undefined';
  String _selectedRiskLevelCode = 'undefined';
  int _selectedImpactRadiusMeters = 10;
  String? _storedEvidencePhotoUrl;

  late final DateTime _reportedAt;
  bool _isSaving = false;
  bool _isPickingPhoto = false;
  String? _locationErrorText;
  String? _descriptionErrorText;
  String? _submitValidationErrorText;
  String? _saveErrorText;

  LatLng? get _effectiveHazardLocation {
    return widget.selectedHazardLocation ?? widget.currentDeviceLocation;
  }

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _reportedAt = DateTime.now();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _emitDraftPreview() {
    widget.onPreviewChanged(
      HazardDraftPreview(
        location: _effectiveHazardLocation,
        impactRadiusMeters: _selectedImpactRadiusMeters,
        riskLevelCode: _selectedRiskLevelCode,
        isSelectingOnMap: widget.isSelectingHazardLocationOnMap,
      ),
    );
  }

  Future<void> _pickEvidencePhoto() async {
    setState(() {
      _isPickingPhoto = true;
      _saveErrorText = null;
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
    } catch (_) {
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
    final LatLng? resolvedLocation = _effectiveHazardLocation;

    setState(() {
      _locationErrorText = null;
      _descriptionErrorText = null;
      _submitValidationErrorText = null;
      _saveErrorText = null;
    });

    if (resolvedLocation == null) {
      setState(() {
        _locationErrorText =
            'Necesitamos una ubicacion valida para reportar este peligro.';
        _submitValidationErrorText =
            'Completa los campos obligatorios para reportar.';
      });
      return;
    }

    final String narrativeDescription = _descriptionController.text.trim();
    if (narrativeDescription.isEmpty) {
      setState(() {
        _descriptionErrorText = 'La descripcion del peligro es obligatoria.';
        _submitValidationErrorText =
            'Completa los campos obligatorios para reportar.';
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
          : 'Anonimo';

      await ref
          .read(hazardReportsControllerProvider.notifier)
          .addHazardReport(
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
    final String? resolvedLocationErrorText =
        _locationErrorText ??
        (widget.selectedHazardLocation == null &&
                !widget.isSelectingHazardLocationOnMap
            ? widget.currentLocationErrorText
            : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HazardLocationCard(
                  isDarkMode: widget.isDarkMode,
                  onStartSelection: widget.onStartMapSelection,
                  onUseCurrentLocation: widget.onUseCurrentLocation,
                ),
                if (resolvedLocationErrorText != null) ...[
                  const SizedBox(height: 6),
                  _FieldErrorText(message: resolvedLocationErrorText),
                ],
                const SizedBox(height: 10),
                _LabeledField(
                  label: 'Radio de afectacion ($_selectedImpactRadiusMeters m)',
                  child: _buildImpactRadiusDropdown(),
                ),
                const SizedBox(height: 8),
                _LabeledField(
                  label: 'Categoria',
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
                const SizedBox(height: 8),
                _LabeledField(
                  label: 'Descripcion del peligro',
                  child: _buildTextField(
                    controller: _descriptionController,
                    hintText: 'Describe lo que observas en el lugar',
                    maxLines: 3,
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
                          _submitValidationErrorText = null;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                _LabeledField(
                  label: 'Duracion aproximada',
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
                const SizedBox(height: 8),
                _LabeledField(
                  label: 'Nivel de riesgo',
                  child: _buildDropdown(
                    value: _selectedRiskLevelCode,
                    items: _riskOptions,
                    onChanged: (String value) {
                      setState(() {
                        _selectedRiskLevelCode = value;
                      });
                      _emitDraftPreview();
                    },
                  ),
                ),
                const SizedBox(height: 8),
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
        const SizedBox(height: 12),
        if (_saveErrorText != null) ...[
          _FieldErrorText(message: _saveErrorText!),
          const SizedBox(height: 8),
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
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
        if (_submitValidationErrorText != null) ...[
          const SizedBox(height: 8),
          _FieldErrorText(message: _submitValidationErrorText!),
        ],
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
      textInputAction: onSubmitted != null
          ? TextInputAction.done
          : TextInputAction.newline,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            (int value) =>
                DropdownMenuItem<int>(value: value, child: Text('$value m')),
          )
          .toList(growable: false),
      onChanged: (int? nextValue) {
        if (nextValue == null) {
          return;
        }
        setState(() {
          _selectedImpactRadiusMeters = nextValue;
        });
        _emitDraftPreview();
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

  const _LabeledField({required this.label, required this.child});

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

class _HazardLocationCard extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onStartSelection;
  final VoidCallback onUseCurrentLocation;

  const _HazardLocationCard({
    required this.isDarkMode,
    required this.onStartSelection,
    required this.onUseCurrentLocation,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor = AppPalette.border(isDarkMode);
    final Color textColor = AppPalette.textPrimary(isDarkMode);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppPalette.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.place_rounded,
                  color: AppPalette.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ubicacion del peligro',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Selecciona el lugar del peligro.',
                      style: TextStyle(
                        color: AppPalette.textMutedDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: onStartSelection,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppPalette.primaryBlue,
                      side: const BorderSide(
                        color: AppPalette.primaryBlue,
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.place_rounded, size: 16),
                    label: const Text(
                      'Marcar en el mapa',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextButton.icon(
                    onPressed: onUseCurrentLocation,
                    style: TextButton.styleFrom(
                      foregroundColor: textColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.my_location_rounded, size: 16),
                    label: const Text(
                      'Usar ubicacion actual',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
      height: 104,
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
                      errorBuilder: (_, _, _) => const _PhotoPlaceholder(),
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
