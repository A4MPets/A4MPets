import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/local_user_profile.dart';
import '../providers/local_data_providers.dart';
import 'shared/user_identity_header.dart';

class ProfileMenuPanel extends ConsumerWidget {
  final bool isDarkMode;
  final VoidCallback? onLoginPressed;
  final VoidCallback? onRegisterPressed;
  final VoidCallback? onManagePetsPressed;
  final VoidCallback? onManageRoutesPressed;

  const ProfileMenuPanel({
    super.key,
    required this.isDarkMode,
    this.onLoginPressed,
    this.onRegisterPressed,
    this.onManagePetsPressed,
    this.onManageRoutesPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color neutralButtonBackground = isDarkMode
        ? const Color(0xFF404040)
        : const Color(0xFFFFFFFF);

    final Color neutralButtonText = isDarkMode
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF404040);

    final AsyncValue<LocalUserProfile> userProfile = ref.watch(localUserProfileProvider);

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
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Iniciar Sesión',
                height: 46,
                background: const Color(0xFF5984BC),
                foreground: const Color(0xFFFFFFFF),
                onPressed: onLoginPressed,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                label: 'Registrarse',
                height: 46,
                background: const Color(0xFF5984BC),
                foreground: const Color(0xFFFFFFFF),
                onPressed: onRegisterPressed,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _ActionButton(
          label: 'Gestionar Mascotas',
          height: 48,
          background: neutralButtonBackground,
          foreground: neutralButtonText,
          onPressed: onManagePetsPressed,
        ),
        const SizedBox(height: 10),
        _ActionButton(
          label: 'Gestionar Rutas',
          height: 48,
          background: neutralButtonBackground,
          foreground: neutralButtonText,
          onPressed: onManageRoutesPressed,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final double height;
  final Color background;
  final Color foreground;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.height,
    required this.background,
    required this.foreground,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
