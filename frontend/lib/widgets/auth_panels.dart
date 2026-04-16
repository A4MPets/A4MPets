import 'package:flutter/material.dart';

class LoginPanelContent extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onSwitchToRegister;
  final Future<void> Function(String login, String password)? onSubmit;

  const LoginPanelContent({
    super.key,
    required this.isDarkMode,
    required this.onSwitchToRegister,
    this.onSubmit,
  });

  @override
  State<LoginPanelContent> createState() => _LoginPanelContentState();
}

class _LoginPanelContentState extends State<LoginPanelContent> {
  late final TextEditingController _loginController;
  late final TextEditingController _passwordController;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loginController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final Future<void> Function(String login, String password)? onSubmit = widget.onSubmit;
    if (onSubmit == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await onSubmit(
        _loginController.text.trim(),
        _passwordController.text,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = 'No se pudo iniciar sesión: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryText = widget.isDarkMode
        ? const Color(0xFFAAAAAA)
        : const Color(0xFF404040);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AuthTextField(
          isDarkMode: widget.isDarkMode,
          controller: _loginController,
          hintText: 'Usuario o correo',
          autofillHints: const [AutofillHints.username],
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        _AuthTextField(
          isDarkMode: widget.isDarkMode,
          controller: _passwordController,
          hintText: 'Contraseña',
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
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
              onTap: widget.onSwitchToRegister,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _PrimaryActionButton(
          label: _isSubmitting ? 'Ingresando...' : 'Iniciar Sesión',
          onPressed: _isSubmitting ? null : _submit,
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 8),
          const _InlineErrorText(),
          const SizedBox(height: 2),
          Text(
            _errorText!,
            style: const TextStyle(
              color: Color(0xFFD7263D),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class RegisterPanelContent extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onSwitchToLogin;
  final Future<void> Function(
    String username,
    String email,
    String password,
    String passwordConfirmation,
  )? onSubmit;

  const RegisterPanelContent({
    super.key,
    required this.isDarkMode,
    required this.onSwitchToLogin,
    this.onSubmit,
  });

  @override
  State<RegisterPanelContent> createState() => _RegisterPanelContentState();
}

class _RegisterPanelContentState extends State<RegisterPanelContent> {
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _passwordConfirmationController;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _passwordConfirmationController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final Future<void> Function(
      String username,
      String email,
      String password,
      String passwordConfirmation,
    )? onSubmit = widget.onSubmit;

    if (onSubmit == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await onSubmit(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _passwordConfirmationController.text,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = 'No se pudo registrar la cuenta: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryText = widget.isDarkMode
        ? const Color(0xFFAAAAAA)
        : const Color(0xFF404040);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AuthTextField(
          isDarkMode: widget.isDarkMode,
          controller: _usernameController,
          hintText: 'Nombre de Usuario',
          autofillHints: const [AutofillHints.username],
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        _AuthTextField(
          isDarkMode: widget.isDarkMode,
          controller: _emailController,
          hintText: 'Correo electrónico',
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        _AuthTextField(
          isDarkMode: widget.isDarkMode,
          controller: _passwordController,
          hintText: 'Contraseña',
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        _AuthTextField(
          isDarkMode: widget.isDarkMode,
          controller: _passwordConfirmationController,
          hintText: 'Repetir Contraseña',
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
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
              onTap: widget.onSwitchToLogin,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _PrimaryActionButton(
          label: _isSubmitting ? 'Registrando...' : 'Registrarse',
          onPressed: _isSubmitting ? null : _submit,
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 8),
          const _InlineErrorText(),
          const SizedBox(height: 2),
          Text(
            _errorText!,
            style: const TextStyle(
              color: Color(0xFFD7263D),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _InlineErrorText extends StatelessWidget {
  const _InlineErrorText();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Error',
      style: TextStyle(
        color: Color(0xFFD7263D),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  final bool isDarkMode;
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _AuthTextField({
    required this.isDarkMode,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
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
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
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
