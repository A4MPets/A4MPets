import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/local_user_profile.dart';
import '../providers/local_data_providers.dart';
import '../theme/app_palette.dart';
import 'shared/user_identity_header.dart';

class ProfileMenuPanel extends ConsumerStatefulWidget {
  final bool isDarkMode;
  final VoidCallback? onLoginPressed, onRegisterPressed;
  final Future<String?> Function()? onLogoutPressed;
  final VoidCallback? onManagePetsPressed, onManageRoutesPressed;

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
  static const String _publicWebBaseUrl = String.fromEnvironment(
    'A4M_PUBLIC_WEB_BASE_URL',
    defaultValue: 'https://a4mpets.com',
  );
  static const String _appVersion = '1.0.0+1';
  static const Color _danger = Color(0xFFD7263D);
  static const Color _white = Color(0xFFFFFFFF);

  String? _actionErrorText;
  bool _isPickingAvatar = false;

  Future<void> _handleEditAvatar() async {
    setState(() {
      _actionErrorText = null;
      _isPickingAvatar = true;
    });

    try {
      final String? avatarPath = await ref.read(localMediaStorageServiceProvider).pickAndStoreProfilePhoto();

      if (avatarPath == null || avatarPath.isEmpty) return;

      await ref.read(userLocalRepositoryProvider).updateProfileAvatar(avatarPath: avatarPath);

      ref.invalidate(localUserProfileProvider);
    } catch (_) {
      if (!mounted) return;
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
    if (callback == null) return;

    final String? errorText = await callback();
    if (!mounted) return;

    setState(() {
      _actionErrorText = errorText;
    });
  }

  Future<void> _openExternalPath(String path) async {
    final Uri uri = Uri.parse('${_publicWebBaseUrl.replaceAll(RegExp(r"/+$"), "")}$path');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      setState(() {
        _actionErrorText = 'No se pudo abrir el enlace.';
      });
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmationController = TextEditingController();
    bool isSubmitting = false;
    String? errorText;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: !isSubmitting,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              Future<void> submit() async {
                setDialogState(() {
                  isSubmitting = true;
                  errorText = null;
                });
                try {
                  await ref
                      .read(userLocalRepositoryProvider)
                      .deleteAccount(
                        password: passwordController.text,
                        confirmation: confirmationController.text.trim(),
                      );
                  ref.invalidate(localUserProfileProvider);
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  if (mounted) {
                    setState(() {
                      _actionErrorText = null;
                    });
                  }
                } catch (error) {
                  setDialogState(() {
                    isSubmitting = false;
                    errorText = error.toString().replaceFirst('Exception: ', '');
                  });
                }
              }

              return AlertDialog(
                title: const Text('Eliminar cuenta'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Se borraran tus datos privados y tus aportes publicos quedaran anonimizados.'),
                    const SizedBox(height: 14),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(labelText: 'Contrasena'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmationController,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(labelText: 'Escribe ELIMINAR'),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorText!,
                        style: const TextStyle(color: _danger, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: isSubmitting ? null : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: isSubmitting ? null : submit,
                    style: FilledButton.styleFrom(backgroundColor: _danger),
                    child: Text(isSubmitting ? 'Eliminando...' : 'Eliminar'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      passwordController.dispose();
      confirmationController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color neutralButtonBackground = widget.isDarkMode ? const Color(0xFF404040) : _white;

    final Color neutralButtonText = widget.isDarkMode ? _white : const Color(0xFF404040);

    final AsyncValue<LocalUserProfile> userProfile = ref.watch(localUserProfileProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _identityHeader(userProfile),
        const SizedBox(height: 22),
        userProfile.when(
          data: (LocalUserProfile profile) => profile.isAuthenticated ? _authenticatedActions() : _guestActions(),
          loading: () => const SizedBox(height: 14),
          error: (Object error, StackTrace stackTrace) => const SizedBox(height: 14),
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
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Privacidad',
                height: 44,
                background: neutralButtonBackground,
                foreground: neutralButtonText,
                onPressed: () {
                  _openExternalPath('/privacidad');
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                label: 'Términos',
                height: 44,
                background: neutralButtonBackground,
                foreground: neutralButtonText,
                onPressed: () {
                  _openExternalPath('/terminos');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Versión $_appVersion',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.isDarkMode ? const Color(0xFFCFCFCF) : const Color(0xFF696969),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _identityHeader(AsyncValue<LocalUserProfile> userProfile) {
    return userProfile.when(
      data: (LocalUserProfile profile) {
        if (!profile.isAuthenticated) return _guestHeader();
        return UserIdentityHeader(
          isDarkMode: widget.isDarkMode,
          username: profile.username,
          avatarPath: profile.avatarPath,
          onEditAvatarPressed: _handleEditAvatar,
          isEditingAvatar: _isPickingAvatar,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (Object error, StackTrace stackTrace) => _guestHeader(),
    );
  }

  UserIdentityHeader _guestHeader() {
    return UserIdentityHeader(isDarkMode: widget.isDarkMode, username: 'Usuario');
  }

  Widget _authenticatedActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ActionButton(
          label: 'Cerrar sesión',
          height: 46,
          background: AppPalette.primaryBlue,
          foreground: _white,
          onPressed: _handleLogoutPressed,
        ),
        const SizedBox(height: 10),
        _ActionButton(
          label: 'Eliminar cuenta',
          height: 46,
          background: _danger,
          foreground: _white,
          onPressed: _showDeleteAccountDialog,
        ),
        if (_actionErrorText != null) ...[
          const SizedBox(height: 8),
          Text(
            _actionErrorText!,
            style: const TextStyle(color: _danger, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _guestActions() {
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
                foreground: _white,
                onPressed: widget.onLoginPressed,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                label: 'Registrarse',
                height: 46,
                background: const Color(0xFF5984BC),
                foreground: _white,
                onPressed: widget.onRegisterPressed,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final double height;
  final Color background, foreground;
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
