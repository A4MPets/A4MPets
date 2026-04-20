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
  bool _browserAutofillEnabled = false;
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
    final Future<void> Function(String login, String password)? onSubmit =
        widget.onSubmit;
    if (onSubmit == null) {
      return;
    }

    final String loginValue = _loginController.text.trim();
    final String passwordValue = _passwordController.text;

    if (loginValue.isEmpty) {
      setState(() {
        _errorText = 'Escribe tu usuario o correo electrónico para continuar.';
      });
      return;
    }

    if (passwordValue.isEmpty) {
      setState(() {
        _errorText = 'Escribe tu contraseña para iniciar sesión.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await onSubmit(loginValue, passwordValue);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = _friendlyError(error);
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

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AuthTextField(
            isDarkMode: widget.isDarkMode,
            controller: _loginController,
            hintText: 'Usuario o correo',
            autofillHints: _browserAutofillEnabled
                ? const [AutofillHints.username]
                : null,
            textInputAction: TextInputAction.next,
            enableSuggestions: false,
            autocorrect: false,
            onTap: () {
              if (_browserAutofillEnabled) {
                return;
              }
              setState(() {
                _browserAutofillEnabled = true;
              });
            },
          ),
          const SizedBox(height: 6),
          const Text(
            'Puedes iniciar sesión con tu nombre de usuario o correo.',
            style: TextStyle(
              color: Color(0xFF7A7A7A),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _AuthTextField(
            isDarkMode: widget.isDarkMode,
            controller: _passwordController,
            hintText: 'Contraseña',
            obscureText: true,
            autofillHints: _browserAutofillEnabled
                ? const [AutofillHints.password]
                : null,
            textInputAction: TextInputAction.done,
            enableSuggestions: false,
            autocorrect: false,
            onTap: () {
              if (_browserAutofillEnabled) {
                return;
              }
              setState(() {
                _browserAutofillEnabled = true;
              });
            },
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
      ),
    );
  }

  String _friendlyError(Object error) {
    final String raw = error.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length).trim();
    }
    return raw;
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
  )?
  onSubmit;

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
    )?
    onSubmit = widget.onSubmit;

    if (onSubmit == null) {
      return;
    }

    final String username = _usernameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    final String passwordConfirmation = _passwordConfirmationController.text;

    if (username.isEmpty) {
      setState(() {
        _errorText = 'El nombre de usuario es obligatorio.';
      });
      return;
    }

    if (email.isEmpty) {
      setState(() {
        _errorText = 'Escribe tu correo electrónico.';
      });
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() {
        _errorText = 'El correo electrónico no parece válido.';
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _errorText = 'Crea una contraseña para continuar.';
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        _errorText = 'La contraseña debe tener al menos 8 caracteres.';
      });
      return;
    }

    if (password != passwordConfirmation) {
      setState(() {
        _errorText = 'Las contraseñas no coinciden. Revisa ambos campos.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await onSubmit(username, email, password, passwordConfirmation);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = _friendlyError(error);
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

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AuthTextField(
            isDarkMode: widget.isDarkMode,
            controller: _usernameController,
            hintText: 'Nombre de Usuario',
            autofillHints: const [
              AutofillHints.newUsername,
              AutofillHints.username,
            ],
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
      ),
    );
  }

  bool _isValidEmail(String value) {
    final RegExp emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(value);
  }

  String _friendlyError(Object error) {
    final String raw = error.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length).trim();
    }
    return raw;
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
  final VoidCallback? onTap;
  final bool enableSuggestions;
  final bool autocorrect;

  const _AuthTextField({
    required this.isDarkMode,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.onTap,
    this.enableSuggestions = true,
    this.autocorrect = true,
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
      onTap: onTap,
      enableSuggestions: enableSuggestions,
      autocorrect: autocorrect,
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
          borderSide: const BorderSide(color: Color(0xFF5984BC), width: 1),
        ),
      ),
    );
  }
}

class _InlineLinkText extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _InlineLinkText({required this.text, required this.onTap});

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

  const _PrimaryActionButton({required this.label, this.onPressed});

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
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
