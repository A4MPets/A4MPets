import 'package:flutter/material.dart';

class ProfileMenuPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final Color textColor = isDarkMode
        ? const Color(0xFFAAAAAA)
        : const Color(0xFF404040);

    final Color avatarBorderColor = isDarkMode
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF404040);

    final Color neutralButtonBackground = isDarkMode
        ? const Color(0xFF404040)
        : const Color(0xFFFFFFFF);

    final Color neutralButtonText = isDarkMode
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF404040);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: _ProfileAvatar(borderColor: avatarBorderColor),
        ),
        const SizedBox(height: 14),
        Text(
          'Usuario',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
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

class _ProfileAvatar extends StatelessWidget {
  final Color borderColor;

  const _ProfileAvatar({required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 106,
      height: 106,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/default_user.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: const Color(0xFFCFCFCF),
              child: const Icon(
                Icons.person,
                size: 48,
                color: Color(0xFF666666),
              ),
            );
          },
        ),
      ),
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
