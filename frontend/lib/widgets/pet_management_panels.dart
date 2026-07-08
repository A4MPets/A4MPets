import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/local_user_profile.dart';
import '../models/pet_record.dart';
import '../providers/local_data_providers.dart';
import '../theme/app_palette.dart';
import 'reporting_form_widgets.dart';
import 'shared/confirmation_dialog.dart';
import 'shared/local_image_widget.dart';
import 'shared/panel_action_button.dart';
import 'shared/user_identity_header.dart';

class ManagePetsPanelContent extends ConsumerWidget {
  final bool isDarkMode;
  final VoidCallback onAddPetPressed;
  final Function(PetRecord pet) onViewPetPressed;
  final Function(PetRecord pet) onEditPetPressed;
  final bool selectionMode;
  final int? selectedPetId;

  const ManagePetsPanelContent({
    super.key,
    required this.isDarkMode,
    required this.onAddPetPressed,
    required this.onViewPetPressed,
    required this.onEditPetPressed,
    this.selectionMode = false,
    this.selectedPetId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<LocalUserProfile> userProfile = ref.watch(localUserProfileProvider);
    final AsyncValue<List<PetRecord>> petsValue = ref.watch(myPetsControllerProvider);

    final Color cardBorder = AppPalette.border(isDarkMode);
    final Color textColor = AppPalette.textPrimary(isDarkMode);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double gridSquareSize = math.min(constraints.maxWidth, constraints.maxHeight * 0.52);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            userProfile.when(
              data: (LocalUserProfile profile) {
                return UserIdentityHeader(
                  isDarkMode: isDarkMode,
                  username: profile.username,
                  avatarPath: profile.avatarPath,
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (Object error, StackTrace stackTrace) {
                return UserIdentityHeader(isDarkMode: isDarkMode, username: 'Usuario');
              },
            ),
            const SizedBox(height: 18),
            Center(
              child: Container(
                width: gridSquareSize,
                height: gridSquareSize,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cardBorder),
                ),
                child: petsValue.when(
                  data: (List<PetRecord> pets) {
                    final List<PetRecord> visiblePets = pets
                        .where((PetRecord pet) => !pet.isOwnerless)
                        .where((PetRecord pet) => !selectionMode || !pet.isLost)
                        .toList(growable: false);

                    if (visiblePets.isEmpty) {
                      return Center(
                        child: Text(
                          'Aún no has agregado mascotas',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      );
                    }

                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: visiblePets.length,
                      itemBuilder: (BuildContext context, int index) {
                        final PetRecord pet = visiblePets[index];
                        return _PetCard(
                          pet: pet,
                          isDarkMode: isDarkMode,
                          isSelected: selectedPetId == pet.id,
                          onPressed: () => onViewPetPressed(pet),
                          onEditPressed: () => onEditPetPressed(pet),
                        );
                      },
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (Object error, StackTrace stackTrace) {
                    return Center(
                      child: Text(
                        'No se pudieron cargar las mascotas',
                        style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    );
                  },
                ),
              ),
            ),
            const Spacer(),
            PanelActionButton(label: 'Agregar mascota', onPressed: onAddPetPressed, height: 48, fontSize: 15),
          ],
        );
      },
    );
  }
}

class AddPetPanelContent extends ConsumerStatefulWidget {
  final bool isDarkMode;
  final Future<void> Function(int petId) onSaved;

  const AddPetPanelContent({super.key, required this.isDarkMode, required this.onSaved});

  @override
  ConsumerState<AddPetPanelContent> createState() => _AddPetPanelContentState();
}

mixin _PetFormState<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  late final TextEditingController _nameController;
  String? _storedPhotoPath;
  DateTime? _adoptionDate;
  DateTime? _birthDate;
  bool _isSaving = false;
  bool _isPickingPhoto = false;
  String? _errorText;

  void _initPetForm({
    String initialName = '',
    String? initialPhotoPath,
    DateTime? initialAdoptionDate,
    DateTime? initialBirthDate,
  }) {
    _nameController = TextEditingController(text: initialName);
    _storedPhotoPath = initialPhotoPath;
    _adoptionDate = initialAdoptionDate;
    _birthDate = initialBirthDate;
  }

  void _disposePetForm() {
    _nameController.dispose();
  }

  Future<void> _pickPhoto() async {
    setState(() {
      _errorText = null;
      _isPickingPhoto = true;
    });

    try {
      final String? storedPath = await ref.read(localMediaStorageServiceProvider).pickAndStorePetPhoto();

      if (!mounted) return;

      setState(() {
        _storedPhotoPath = storedPath;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorText = 'No se pudo cargar la imagen. Intenta nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPickingPhoto = false;
        });
      }
    }
  }

  Future<void> _runPetSave({
    required Future<void> Function() action,
    String message = 'No se pudo guardar la mascota. Intenta nuevamente.',
  }) async {
    setState(() {
      _errorText = null;
      _isSaving = true;
    });

    try {
      await action();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorText = message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _resolvedPetName(String fallback) {
    final String name = _nameController.text.trim();
    return name.isEmpty ? fallback : name;
  }

  Future<void> _pickOptionalDate({
    required bool isDarkMode,
    required DateTime? current,
    required ValueChanged<DateTime?> onPicked,
  }) async {
    final DateTime? picked = await _showPetDatePicker(
      context,
      isDarkMode: isDarkMode,
      initialDate: current ?? DateTime.now(),
    );
    if (!mounted) return;
    onPicked(picked);
  }

  Widget _buildPetForm({
    required bool isDarkMode,
    required String fallbackName,
    required FontWeight previewFontWeight,
    required VoidCallback onSubmit,
    required bool canSubmit,
    required EdgeInsets padding,
    required Widget actions,
    MainAxisSize mainAxisSize = MainAxisSize.max,
  }) {
    return _PetFormBody(
      isDarkMode: isDarkMode,
      photoPath: _storedPhotoPath,
      borderColor: AppPalette.border(isDarkMode),
      isPickingPhoto: _isPickingPhoto,
      onPickPhoto: _pickPhoto,
      nameController: _nameController,
      fallbackName: fallbackName,
      previewTextColor: AppPalette.textPrimary(isDarkMode),
      previewFontWeight: previewFontWeight,
      onNameSubmitted: (_) {
        if (canSubmit) onSubmit();
      },
      adoptionDate: _adoptionDate,
      birthDate: _birthDate,
      onPickAdoptionDate: () => _pickOptionalDate(
        isDarkMode: isDarkMode,
        current: _adoptionDate,
        onPicked: (DateTime? date) => setState(() => _adoptionDate = date),
      ),
      onClearAdoptionDate: _adoptionDate == null ? null : () => setState(() => _adoptionDate = null),
      onPickBirthDate: () => _pickOptionalDate(
        isDarkMode: isDarkMode,
        current: _birthDate,
        onPicked: (DateTime? date) => setState(() => _birthDate = date),
      ),
      onClearBirthDate: _birthDate == null ? null : () => setState(() => _birthDate = null),
      errorText: _errorText,
      padding: padding,
      mainAxisSize: mainAxisSize,
      actions: actions,
    );
  }
}

class _AddPetPanelContentState extends ConsumerState<AddPetPanelContent> with _PetFormState<AddPetPanelContent> {
  String _defaultPetName = 'Mascota';

  @override
  void initState() {
    super.initState();
    _initPetForm();
    _loadDefaultPetName();
  }

  @override
  void dispose() {
    _disposePetForm();
    super.dispose();
  }

  Future<void> _loadDefaultPetName() async {
    try {
      final int nextNumber = await ref.read(myPetsControllerProvider.notifier).getNextDefaultPetNumber();
      if (mounted) setState(() => _defaultPetName = 'Mascota $nextNumber');
    } catch (_) {
      if (mounted) setState(() => _defaultPetName = 'Mascota 1');
    }
  }

  Future<void> _savePet() async {
    await _runPetSave(
      action: () async {
        final int petId = await ref
            .read(myPetsControllerProvider.notifier)
            .addPet(
              name: _resolvedPetName(_defaultPetName),
              photoPath: _storedPhotoPath,
              adoptionDate: _adoptionDate,
              birthDate: _birthDate,
            );
        if (mounted) await widget.onSaved(petId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return _buildPetForm(
      isDarkMode: widget.isDarkMode,
      fallbackName: _defaultPetName,
      previewFontWeight: FontWeight.w100,
      onSubmit: _savePet,
      canSubmit: !_isSaving,
      padding: EdgeInsets.fromLTRB(0, 8, 0, 12 + keyboardInset),
      actions: PanelActionButton(
        label: 'Guardar Mascota',
        isBusy: _isSaving,
        onPressed: _savePet,
        height: 48,
        fontSize: 15,
      ),
    );
  }
}

class _PetFormBody extends StatelessWidget {
  final bool isDarkMode;
  final String? photoPath;
  final Color borderColor, previewTextColor;
  final bool isPickingPhoto;
  final VoidCallback onPickPhoto;
  final TextEditingController nameController;
  final String fallbackName;
  final FontWeight previewFontWeight;
  final ValueChanged<String> onNameSubmitted;
  final DateTime? adoptionDate, birthDate;
  final VoidCallback onPickAdoptionDate;
  final VoidCallback? onClearAdoptionDate;
  final VoidCallback onPickBirthDate;
  final VoidCallback? onClearBirthDate;
  final String? errorText;
  final EdgeInsets padding;
  final Widget actions;
  final MainAxisSize mainAxisSize;

  const _PetFormBody({
    required this.isDarkMode,
    required this.photoPath,
    required this.borderColor,
    required this.isPickingPhoto,
    required this.onPickPhoto,
    required this.nameController,
    required this.fallbackName,
    required this.previewTextColor,
    required this.previewFontWeight,
    required this.onNameSubmitted,
    required this.adoptionDate,
    required this.birthDate,
    required this.onPickAdoptionDate,
    required this.onClearAdoptionDate,
    required this.onPickBirthDate,
    required this.onClearBirthDate,
    required this.errorText,
    required this.padding,
    required this.actions,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: mainAxisSize,
          children: [
            _PetPhotoEditor(
              photoPath: photoPath,
              borderColor: borderColor,
              isBusy: isPickingPhoto,
              onEditPressed: onPickPhoto,
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: nameController,
              builder: (context, value, child) {
                final String previewName = value.text.trim().isEmpty ? fallbackName : value.text.trim();
                return Text(
                  previewName,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: previewTextColor, fontSize: 20, fontWeight: previewFontWeight),
                );
              },
            ),
            const SizedBox(height: 24),
            _PetNameField(isDarkMode: isDarkMode, controller: nameController, onSubmitted: onNameSubmitted),
            const SizedBox(height: 8),
            _OptionalDateButton(
              isDarkMode: isDarkMode,
              title: 'Fecha de adopción',
              valueText: _formatOptionalPetDate(adoptionDate, 'Seleccionar fecha'),
              onPressed: onPickAdoptionDate,
              onClear: onClearAdoptionDate,
            ),
            const SizedBox(height: 8),
            _OptionalDateButton(
              isDarkMode: isDarkMode,
              title: 'Fecha de nacimiento',
              valueText: _formatOptionalPetDate(birthDate, 'Seleccionar fecha'),
              onPressed: onPickBirthDate,
              onClear: onClearBirthDate,
            ),
            if (errorText != null) ...[const SizedBox(height: 8), ReportingFieldErrorText(message: errorText!)],
            const SizedBox(height: 12),
            actions,
          ],
        ),
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final PetRecord pet;
  final bool isDarkMode;
  final bool isSelected;
  final VoidCallback onPressed;
  final VoidCallback onEditPressed;

  const _PetCard({
    required this.pet,
    required this.isDarkMode,
    required this.isSelected,
    required this.onPressed,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Color itemBackground = AppPalette.cardBackground(isDarkMode);
    final Color textColor = AppPalette.textPrimary(isDarkMode);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: itemBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppPalette.primaryBlue : (pet.isLost ? AppPalette.reportYellow : Colors.transparent),
          width: isSelected || pet.isLost ? 2 : 0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Material(
                    color: Colors.transparent,
                    child: Semantics(
                      label: 'Seleccionar mascota ${pet.displayName}',
                      button: true,
                      selected: isSelected,
                      onTap: onPressed,
                      child: ExcludeSemantics(
                        child: InkWell(
                          onTap: onPressed,
                          child: SizedBox.expand(
                            child: _petImage(pet.photoPath, fit: BoxFit.cover, fallback: const _PetPlaceholder()),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: const CircleBorder(),
                      child: Tooltip(
                        message: 'Editar mascota ${pet.displayName}',
                        child: Semantics(
                          label: 'Editar mascota ${pet.displayName}',
                          button: true,
                          child: ExcludeSemantics(
                            child: InkWell(
                              onTap: onEditPressed,
                              customBorder: const CircleBorder(),
                              child: const Icon(Icons.settings, size: 14, color: AppPalette.charcoal),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pet.displayName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PetPhotoEditor extends StatelessWidget {
  final String? photoPath;
  final Color borderColor;
  final bool isBusy;
  final VoidCallback onEditPressed;

  const _PetPhotoEditor({
    required this.photoPath,
    required this.borderColor,
    required this.isBusy,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.12,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox.expand(
                child: _petImage(
                  photoPath,
                  fit: BoxFit.cover,
                  fallback: const _PetPlaceholder(iconSize: 54, backgroundColor: Colors.transparent),
                ),
              ),
            ),
          ),
          Positioned(
            top: -8,
            right: -8,
            child: SizedBox(
              width: 34,
              height: 34,
              child: Material(
                color: AppPalette.white,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: isBusy ? null : onEditPressed,
                  customBorder: const CircleBorder(),
                  child: isBusy
                      ? const Padding(
                          padding: EdgeInsets.all(9),
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppPalette.charcoal),
                        )
                      : const Icon(Icons.edit, size: 18, color: AppPalette.charcoal),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PetNameField extends StatelessWidget {
  final bool isDarkMode;
  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;

  const _PetNameField({required this.isDarkMode, required this.controller, this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    final Color fieldBackground = AppPalette.fieldBackground(isDarkMode);
    final Color textColor = AppPalette.textPrimary(isDarkMode);

    return Semantics(
      label: 'Nombre de mascota',
      textField: true,
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.done,
        onSubmitted: onSubmitted,
        style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Nombre de mascota',
          hintStyle: const TextStyle(color: AppPalette.textMutedDark, fontSize: 14, fontWeight: FontWeight.w500),
          filled: true,
          fillColor: fieldBackground,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppPalette.primaryBlue, width: 1),
          ),
        ),
      ),
    );
  }
}

class _OptionalDateButton extends StatelessWidget {
  final bool isDarkMode;
  final String title;
  final String valueText;
  final VoidCallback onPressed;
  final VoidCallback? onClear;

  const _OptionalDateButton({
    required this.isDarkMode,
    required this.title,
    required this.valueText,
    required this.onPressed,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(color: AppPalette.textMutedDark, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: onPressed,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppPalette.textMutedDark,
                    backgroundColor: AppPalette.fieldBackground(isDarkMode),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      valueText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppPalette.textMutedDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w100,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 42,
                height: 42,
                child: IconButton(
                  onPressed: onClear,
                  icon: Icon(Icons.close, size: 18, color: AppPalette.textPrimary(isDarkMode)),
                  tooltip: 'Quitar fecha',
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

Future<DateTime?> _showPetDatePicker(BuildContext context, {required bool isDarkMode, required DateTime initialDate}) {
  final DateTime now = DateTime.now();
  return showReportingDatePicker(
    context: context,
    isDarkMode: isDarkMode,
    initialDate: initialDate,
    firstDate: DateTime(now.year - 30),
    lastDate: DateTime(now.year, now.month, now.day),
  );
}

String _formatOptionalPetDate(DateTime? date, String fallback) {
  if (date == null) return fallback;
  final String day = date.day.toString().padLeft(2, '0');
  final String month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

class _PetPlaceholder extends StatelessWidget {
  final double iconSize;
  final Color backgroundColor;

  const _PetPlaceholder({this.iconSize = 36, this.backgroundColor = AppPalette.placeholderGray});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Center(
        child: Icon(Icons.pets, size: iconSize, color: AppPalette.iconGray),
      ),
    );
  }
}

Widget _petImage(String? source, {required BoxFit fit, required Widget fallback}) {
  if (source == null || source.isEmpty) return fallback;
  return buildLocalImageWidget(
    source: source,
    fit: fit,
    fallback: fallback,
    errorBuilder: (context, error, stackTrace) => fallback,
  );
}

class EditPetPanelContent extends ConsumerStatefulWidget {
  final PetRecord pet;
  final bool isDarkMode;
  final VoidCallback onSaved;

  const EditPetPanelContent({super.key, required this.pet, required this.isDarkMode, required this.onSaved});

  @override
  ConsumerState<EditPetPanelContent> createState() => _EditPetPanelContentState();
}

class _EditPetPanelContentState extends ConsumerState<EditPetPanelContent> with _PetFormState<EditPetPanelContent> {
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _initPetForm(
      initialName: widget.pet.name ?? '',
      initialPhotoPath: widget.pet.photoPath,
      initialAdoptionDate: widget.pet.adoptionDate,
      initialBirthDate: widget.pet.birthDate,
    );
  }

  @override
  void dispose() {
    _disposePetForm();
    super.dispose();
  }

  Future<void> _updatePet() async {
    await _runPetSave(
      action: () async {
        await ref
            .read(myPetsControllerProvider.notifier)
            .updatePet(
              petId: widget.pet.id,
              name: _resolvedPetName(widget.pet.displayName),
              photoPath: _storedPhotoPath,
              adoptionDate: _adoptionDate,
              birthDate: _birthDate,
            );
        if (mounted) widget.onSaved();
      },
    );
  }

  Future<void> _deletePet() async {
    setState(() {
      _errorText = null;
      _isDeleting = true;
    });

    try {
      await ref.read(myPetsControllerProvider.notifier).deletePet(petId: widget.pet.id);

      if (!mounted) return;

      widget.onSaved();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorText = 'No se pudo eliminar la mascota. Intenta nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final bool confirmed = await showAppConfirmationDialog(
      context: context,
      isDarkMode: widget.isDarkMode,
      title: 'Eliminar mascota',
      message: '¿Estás seguro de que deseas eliminar a ${widget.pet.displayName}?',
      confirmLabel: 'Eliminar',
    );
    if (confirmed) await _deletePet();
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return _buildPetForm(
      isDarkMode: widget.isDarkMode,
      fallbackName: widget.pet.displayName,
      previewFontWeight: FontWeight.w700,
      onSubmit: _updatePet,
      canSubmit: !_isSaving && !_isDeleting,
      padding: EdgeInsets.only(bottom: bottomInset),
      mainAxisSize: MainAxisSize.min,
      actions: Row(
        children: [
          Expanded(
            child: PanelActionButton(
              label: 'Eliminar',
              isBusy: _isDeleting,
              onPressed: _isSaving ? null : _showDeleteConfirmation,
              height: 48,
              fontSize: 15,
              backgroundColor: AppPalette.dangerRed,
              disabledBackgroundColor: AppPalette.dangerRed.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PanelActionButton(
              label: 'Guardar',
              isBusy: _isSaving,
              onPressed: _isDeleting ? null : _updatePet,
              height: 48,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
