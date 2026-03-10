import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/local_user_profile.dart';
import '../models/pet_record.dart';
import '../providers/local_data_providers.dart';
import '../theme/app_palette.dart';
import 'shared/local_image_widget.dart';
import 'shared/user_identity_header.dart';

class ManagePetsPanelContent extends ConsumerWidget {
  final bool isDarkMode;
  final VoidCallback onAddPetPressed;
  final Function(PetRecord pet) onEditPetPressed;

  const ManagePetsPanelContent({
    super.key,
    required this.isDarkMode,
    required this.onAddPetPressed,
    required this.onEditPetPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<LocalUserProfile> userProfile = ref.watch(localUserProfileProvider);
    final AsyncValue<List<PetRecord>> petsValue = ref.watch(petsControllerProvider);

    final Color cardBorder = AppPalette.border(isDarkMode);
    final Color textColor = AppPalette.textPrimary(isDarkMode);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double gridSquareSize = math.min(
          constraints.maxWidth,
          constraints.maxHeight * 0.52,
        );

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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object error, StackTrace stackTrace) {
                return UserIdentityHeader(
                  isDarkMode: isDarkMode,
                  username: 'Usuario',
                );
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
                    if (pets.isEmpty) {
                      return Center(
                        child: Text(
                          'Aún no has agregado mascotas',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
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
                      itemCount: pets.length,
                      itemBuilder: (BuildContext context, int index) {
                        final PetRecord pet = pets[index];
                        return _PetCard(
                          pet: pet,
                          isDarkMode: isDarkMode,
                          onEditPressed: () => onEditPetPressed(pet),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (Object error, StackTrace stackTrace) {
                    return Center(
                      child: Text(
                        'No se pudieron cargar las mascotas',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: onAddPetPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.primaryBlue,
                  foregroundColor: AppPalette.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Agregar mascota',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class AddPetPanelContent extends ConsumerStatefulWidget {
  final bool isDarkMode;
  final VoidCallback onSaved;

  const AddPetPanelContent({
    super.key,
    required this.isDarkMode,
    required this.onSaved,
  });

  @override
  ConsumerState<AddPetPanelContent> createState() => _AddPetPanelContentState();
}

class _AddPetPanelContentState extends ConsumerState<AddPetPanelContent> {
  late final TextEditingController _nameController;
  String? _storedPhotoPath;
  String _defaultPetName = 'Mascota';
  bool _isSaving = false;
  bool _isPickingPhoto = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadDefaultPetName();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultPetName() async {
    try {
      final int nextNumber = await ref.read(petsControllerProvider.notifier).getNextDefaultPetNumber();
      if (!mounted) {
        return;
      }

      setState(() {
        _defaultPetName = 'Mascota $nextNumber';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _defaultPetName = 'Mascota 1';
      });
    }
  }

  Future<void> _pickPhoto() async {
    setState(() {
      _isPickingPhoto = true;
    });

    try {
      final String? storedPath = await ref.read(localMediaStorageServiceProvider).pickAndStorePetPhoto();

      if (!mounted) {
        return;
      }

      setState(() {
        _storedPhotoPath = storedPath;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo cargar la imagen: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingPhoto = false;
        });
      }
    }
  }

  Future<void> _savePet() async {
    setState(() {
      _isSaving = true;
    });

    final String resolvedName = _nameController.text.trim().isEmpty
        ? _defaultPetName
        : _nameController.text.trim();

    try {
      await ref.read(petsControllerProvider.notifier).addPet(
        name: resolvedName,
        photoPath: _storedPhotoPath,
      );

      if (!mounted) {
        return;
      }

      widget.onSaved();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo guardar la mascota: $error'),
        ),
      );
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
    final Color borderColor = AppPalette.border(widget.isDarkMode);
    final Color textColor = AppPalette.textPrimary(widget.isDarkMode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PetPhotoEditor(
          photoPath: _storedPhotoPath,
          borderColor: borderColor,
          isBusy: _isPickingPhoto,
          onEditPressed: _pickPhoto,
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _nameController,
          builder: (BuildContext context, TextEditingValue value, Widget? child) {
            final String previewName = value.text.trim().isEmpty
                ? _defaultPetName
                : value.text.trim();
            return Text(
              previewName,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            );
          },
        ),
        const Spacer(),
        _PetNameField(
          isDarkMode: widget.isDarkMode,
          controller: _nameController,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _savePet,
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
                    'Guardar Mascota',
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
}

class _PetCard extends StatelessWidget {
  final PetRecord pet;
  final bool isDarkMode;
  final VoidCallback onEditPressed;

  const _PetCard({
    required this.pet,
    required this.isDarkMode,
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
                    child: InkWell(
                      onTap: onEditPressed,
                      child: SizedBox.expand(
                        child: pet.photoPath != null && pet.photoPath!.isNotEmpty
                            ? buildLocalImageWidget(
                                source: pet.photoPath,
                                fit: BoxFit.cover,
                                fallback: const _PetPlaceholder(),
                                errorBuilder: (context, error, stackTrace) {
                                  return const _PetPlaceholder();
                                },
                              )
                            : const _PetPlaceholder(),
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
                      child: InkWell(
                        onTap: onEditPressed,
                        customBorder: const CircleBorder(),
                        child: const Icon(
                          Icons.settings,
                          size: 14,
                          color: AppPalette.charcoal,
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
            pet.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
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
                child: photoPath != null && photoPath!.isNotEmpty
                    ? buildLocalImageWidget(
                        source: photoPath,
                        fit: BoxFit.cover,
                        fallback: const _PetPlaceholder(
                          iconSize: 54,
                          backgroundColor: Colors.transparent,
                        ),
                        errorBuilder: (context, error, stackTrace) {
                          return const _PetPlaceholder(
                            iconSize: 54,
                            backgroundColor: Colors.transparent,
                          );
                        },
                      )
                    : const _PetPlaceholder(
                        iconSize: 54,
                        backgroundColor: Colors.transparent,
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

class _PetNameField extends StatelessWidget {
  final bool isDarkMode;
  final TextEditingController controller;

  const _PetNameField({
    required this.isDarkMode,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final Color fieldBackground = AppPalette.fieldBackground(isDarkMode);
    final Color textColor = AppPalette.textPrimary(isDarkMode);

    return TextField(
      controller: controller,
      style: TextStyle(
        color: textColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'Nombre',
        hintStyle: const TextStyle(
          color: AppPalette.textMutedDark,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: fieldBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
    );
  }
}

class _PetPlaceholder extends StatelessWidget {
  final double iconSize;
  final Color backgroundColor;

  const _PetPlaceholder({
    this.iconSize = 36,
    this.backgroundColor = AppPalette.placeholderGray,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Center(
        child: Icon(
          Icons.pets,
          size: iconSize,
          color: AppPalette.iconGray,
        ),
      ),
    );
  }
}

class EditPetPanelContent extends ConsumerStatefulWidget {
  final PetRecord pet;
  final bool isDarkMode;
  final VoidCallback onSaved;

  const EditPetPanelContent({
    super.key,
    required this.pet,
    required this.isDarkMode,
    required this.onSaved,
  });

  @override
  ConsumerState<EditPetPanelContent> createState() => _EditPetPanelContentState();
}

class _EditPetPanelContentState extends ConsumerState<EditPetPanelContent> {
  late final TextEditingController _nameController;
  String? _storedPhotoPath;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isPickingPhoto = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pet.name);
    _storedPhotoPath = widget.pet.photoPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    setState(() {
      _isPickingPhoto = true;
    });

    try {
      final String? storedPath = await ref.read(localMediaStorageServiceProvider).pickAndStorePetPhoto();

      if (!mounted) {
        return;
      }

      setState(() {
        _storedPhotoPath = storedPath;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo cargar la imagen: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingPhoto = false;
        });
      }
    }
  }

  Future<void> _updatePet() async {
    setState(() {
      _isSaving = true;
    });

    final String resolvedName = _nameController.text.trim().isEmpty
        ? widget.pet.name
        : _nameController.text.trim();

    try {
      await ref.read(petsControllerProvider.notifier).updatePet(
        petId: widget.pet.id,
        name: resolvedName,
        photoPath: _storedPhotoPath,
      );

      if (!mounted) {
        return;
      }

      widget.onSaved();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo guardar la mascota: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deletePet() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await ref.read(petsControllerProvider.notifier).deletePet(petId: widget.pet.id);

      if (!mounted) {
        return;
      }

      widget.onSaved();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo eliminar la mascota: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _showDeleteConfirmation() {
    final bool isDarkMode = widget.isDarkMode;

    showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppPalette.dialogBackground(isDarkMode),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppPalette.border(isDarkMode)),
          ),
          title: Text(
            'Eliminar mascota',
            style: TextStyle(
              color: AppPalette.dialogTitle(isDarkMode),
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            '¿Estás seguro de que deseas eliminar a ${widget.pet.name}?',
            style: TextStyle(color: AppPalette.dialogBody(isDarkMode)),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: AppPalette.dialogCancel(isDarkMode),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
                _deletePet();
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(
                  color: AppPalette.dangerRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color borderColor = AppPalette.border(widget.isDarkMode);
    final Color textColor = AppPalette.textPrimary(widget.isDarkMode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PetPhotoEditor(
          photoPath: _storedPhotoPath,
          borderColor: borderColor,
          isBusy: _isPickingPhoto,
          onEditPressed: _pickPhoto,
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _nameController,
          builder: (BuildContext context, TextEditingValue value, Widget? child) {
            final String previewName = value.text.trim().isEmpty
                ? widget.pet.name
                : value.text.trim();
            return Text(
              previewName,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            );
          },
        ),
        const Spacer(),
        _PetNameField(
          isDarkMode: widget.isDarkMode,
          controller: _nameController,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isDeleting || _isSaving ? null : _showDeleteConfirmation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.dangerRed,
                    foregroundColor: AppPalette.white,
                    elevation: 0,
                    disabledBackgroundColor: AppPalette.dangerRed.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppPalette.white,
                          ),
                        )
                      : const Text(
                          'Eliminar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving || _isDeleting ? null : _updatePet,
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
                          'Guardar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
