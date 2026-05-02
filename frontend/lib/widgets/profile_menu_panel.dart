import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/local_user_profile.dart';
import '../providers/local_data_providers.dart';
import '../theme/app_palette.dart';
import 'shared/user_identity_header.dart';

class ProfileMenuPanel extends ConsumerStatefulWidget {
  final bool isDarkMode;
  final VoidCallback? onLoginPressed;
  final VoidCallback? onRegisterPressed;
  final Future<String?> Function()? onLogoutPressed;
  final VoidCallback? onManagePetsPressed;
  final VoidCallback? onManageRoutesPressed;

  const ProfileMenuPanel({
    super.key,
    required this.isDarkMode,
    this.onLoginPressed,
    this.onRegisterPressed,
    this.onLogoutPressed,
    this.onManagePetsPressed,
    this.onManageRoutesPressed,
  });

  @override
  ConsumerState<ProfileMenuPanel> createState() => _ProfileMenuPanelState();
}

class _ProfileMenuPanelState extends ConsumerState<ProfileMenuPanel> {
  String? _actionErrorText;
  bool _isPickingAvatar = false;

  Future<void> _handleEditAvatar() async {
    setState(() {
      _actionErrorText = null;
      _isPickingAvatar = true;
    });

    try {
      final String? avatarPath = await ref
          .read(localMediaStorageServiceProvider)
          .pickAndStoreProfilePhoto();

      if (avatarPath == null || avatarPath.isEmpty) {
        return;
      }

      await ref
          .read(userLocalRepositoryProvider)
          .updateProfileAvatar(avatarPath: avatarPath);

      ref.invalidate(localUserProfileProvider);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _actionErrorText = 'No se pudo actualizar la foto de perfil.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPickingAvatar = false;
        });
      }
    }
  }

  Future<void> _handleLogoutPressed() async {
    final Future<String?> Function()? callback = widget.onLogoutPressed;
    if (callback == null) {
      return;
    }

    final String? errorText = await callback();
    if (!mounted) {
      return;
    }

    setState(() {
      _actionErrorText = errorText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color neutralButtonBackground = widget.isDarkMode
        ? const Color(0xFF404040)
        : const Color(0xFFFFFFFF);

    final Color neutralButtonText = widget.isDarkMode
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF404040);

    final AsyncValue<LocalUserProfile> userProfile = ref.watch(
      localUserProfileProvider,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        userProfile.when(
          data: (LocalUserProfile profile) {
            return UserIdentityHeader(
              isDarkMode: widget.isDarkMode,
              username: profile.username,
              avatarPath: profile.avatarPath,
              onEditAvatarPressed: profile.isAuthenticated
                  ? _handleEditAvatar
                  : null,
              isEditingAvatar: _isPickingAvatar,
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (Object error, StackTrace stackTrace) {
            return UserIdentityHeader(
              isDarkMode: widget.isDarkMode,
              username: 'Usuario',
            );
          },
        ),
        const SizedBox(height: 22),
        userProfile.when(
          data: (LocalUserProfile profile) {
            if (profile.isAuthenticated) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ActionButton(
                    label: 'Cerrar sesión',
                    height: 46,
                    background: AppPalette.primaryBlue,
                    foreground: const Color(0xFFFFFFFF),
                    onPressed: _handleLogoutPressed,
                  ),
                  if (_actionErrorText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _actionErrorText!,
                      style: const TextStyle(
                        color: Color(0xFFD7263D),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'Iniciar Sesión',
                        height: 46,
                        background: const Color(0xFF5984BC),
                        foreground: const Color(0xFFFFFFFF),
                        onPressed: widget.onLoginPressed,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionButton(
                        label: 'Registrarse',
                        height: 46,
                        background: const Color(0xFF5984BC),
                        foreground: const Color(0xFFFFFFFF),
                        onPressed: widget.onRegisterPressed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
            );
          },
          loading: () => const SizedBox(height: 14),
          error: (Object error, StackTrace stackTrace) =>
              const SizedBox(height: 14),
        ),
        _ActionButton(
          label: 'Gestionar Mascotas',
          height: 48,
          background: neutralButtonBackground,
          foreground: neutralButtonText,
          onPressed: widget.onManagePetsPressed,
        ),
        const SizedBox(height: 10),
        _ActionButton(
          label: 'Gestionar Rutas',
          height: 48,
          background: neutralButtonBackground,
          foreground: neutralButtonText,
          onPressed: widget.onManageRoutesPressed,
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
