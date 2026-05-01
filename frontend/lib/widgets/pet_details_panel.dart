import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pet_record.dart';
import '../providers/local_data_providers.dart';
import '../theme/app_palette.dart';
import 'shared/local_image_widget.dart';
import 'shared/panel_scroll_view.dart';

class PetDetailsPanelContent extends ConsumerWidget {
  final bool isDarkMode;
  final PetRecord pet;
  final VoidCallback onEditPressed;
  final VoidCallback onMarkedFound;

  const PetDetailsPanelContent({
    super.key,
    required this.isDarkMode,
    required this.pet,
    required this.onEditPressed,
    required this.onMarkedFound,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color textColor = AppPalette.textPrimary(isDarkMode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: PanelScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 1.15,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: pet.photoPath == null || pet.photoPath!.isEmpty
                        ? const _PetFallback()
                        : buildLocalImageWidget(
                            source: pet.photoPath,
                            fit: BoxFit.cover,
                            fallback: const _PetFallback(),
                            errorBuilder: (_, _, _) => const _PetFallback(),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  pet.displayName,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (pet.isLost) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Mascota perdida',
                    style: TextStyle(
                      color: AppPalette.reportYellow,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                _InfoRow(
                  label: 'Paseos completados',
                  value: '${pet.totalWalks}',
                ),
                _InfoRow(
                  label: 'Fecha de registro',
                  value: _formatDate(pet.registeredAt),
                ),
                if (pet.adoptionDate != null)
                  _InfoRow(
                    label: 'Fecha de adopcion',
                    value: _formatDate(pet.adoptionDate!),
                  ),
                if (pet.birthDate != null)
                  _InfoRow(
                    label: 'Fecha de nacimiento',
                    value: _formatDate(pet.birthDate!),
                  ),
              ],
            ),
          ),
        ),
        if (pet.isLost) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: () async {
                await ref
                    .read(petsControllerProvider.notifier)
                    .markPetFound(petId: pet.id);
                await ref
                    .read(lostPetReportsControllerProvider.notifier)
                    .reload();
                onMarkedFound();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.reportYellow,
                foregroundColor: AppPalette.charcoal,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Ya se encontro',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        SizedBox(
          height: 46,
          child: OutlinedButton(
            onPressed: onEditPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: textColor,
              side: BorderSide(color: AppPalette.border(isDarkMode)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Editar',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppPalette.textMutedDark,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: AppPalette.charcoal,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PetFallback extends StatelessWidget {
  const _PetFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppPalette.placeholderGray,
      alignment: Alignment.center,
      child: const Icon(Icons.pets, size: 54, color: AppPalette.iconGray),
    );
  }
}
