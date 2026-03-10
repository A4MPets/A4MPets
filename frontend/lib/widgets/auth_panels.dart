import 'package:flutter/material.dart';

class LoginPanelContent extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onSwitchToRegister;
  final VoidCallback? onSubmit;

  const LoginPanelContent({
    super.key,
    required this.isDarkMode,
    required this.onSwitchToRegister,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryText = isDarkMode
        ? const Color(0xFFAAAAAA)
        : const Color(0xFF404040);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AuthTextField(
          isDarkMode: isDarkMode,
          hintText: 'Nombre de Usuario',
        ),
        const SizedBox(height: 12),
        _AuthTextField(
          isDarkMode: isDarkMode,
          hintText: 'Contraseña',
          obscureText: true,
        ),
        const SizedBox(height: 16),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '¿No tienes una cuenta?',
              style: TextStyle(
                color: primaryText,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            _InlineLinkText(
              text: 'Regístrate',
              onTap: onSwitchToRegister,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _PrimaryActionButton(
          label: 'Iniciar Sesión',
          onPressed: onSubmit,
        ),
      ],
    );
  }
}

class RegisterPanelContent extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onSwitchToLogin;
  final VoidCallback? onSubmit;

  const RegisterPanelContent({
    super.key,
    required this.isDarkMode,
    required this.onSwitchToLogin,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryText = isDarkMode
        ? const Color(0xFFAAAAAA)
        : const Color(0xFF404040);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AuthTextField(
          isDarkMode: isDarkMode,
          hintText: 'Nombre de Usuario',
        ),
        const SizedBox(height: 12),
        _AuthTextField(
          isDarkMode: isDarkMode,
          hintText: 'Correo electrónico',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _AuthTextField(
          isDarkMode: isDarkMode,
          hintText: 'Contraseña',
          obscureText: true,
        ),
        const SizedBox(height: 12),
        _AuthTextField(
          isDarkMode: isDarkMode,
          hintText: 'Repetir Contraseña',
          obscureText: true,
        ),
        const SizedBox(height: 16),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '¿Ya tienes una cuenta?',
              style: TextStyle(
                color: primaryText,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            _InlineLinkText(
              text: 'Iniciar Sesión',
              onTap: onSwitchToLogin,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _PrimaryActionButton(
          label: 'Registrarse',
          onPressed: onSubmit,
        ),
      ],
    );
  }
}

class _AuthTextField extends StatelessWidget {
  final bool isDarkMode;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;

  const _AuthTextField({
    required this.isDarkMode,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final Color fieldBackground = isDarkMode
        ? const Color(0xFF404040)
        : const Color(0xFFFFFFFF);

    final Color textColor = isDarkMode
        ? const Color(0xFFAAAAAA)
        : const Color(0xFF404040);

    return TextField(
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(
        color: textColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFFAAAAAA),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: fieldBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
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
          borderSide: const BorderSide(
            color: Color(0xFF5984BC),
            width: 1,
          ),
        ),
      ),
    );
  }
}

class _InlineLinkText extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _InlineLinkText({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF5984BC),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _PrimaryActionButton({
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5984BC),
          foregroundColor: const Color(0xFFFFFFFF),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
