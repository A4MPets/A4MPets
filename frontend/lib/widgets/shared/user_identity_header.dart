import 'package:flutter/material.dart';

import 'local_image_widget.dart';

class UserIdentityHeader extends StatelessWidget {
  final bool isDarkMode;
  final String username;
  final String? avatarPath;

  const UserIdentityHeader({
    super.key,
    required this.isDarkMode,
    required this.username,
    this.avatarPath,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = isDarkMode
        ? const Color(0xFFAAAAAA)
        : const Color(0xFF404040);

    final Color avatarBorderColor = isDarkMode
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF404040);

    return Column(
      children: [
        _UserAvatar(
          borderColor: avatarBorderColor,
          avatarPath: avatarPath,
        ),
        const SizedBox(height: 14),
        Text(
          username,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final Color borderColor;
  final String? avatarPath;

  const _UserAvatar({
    required this.borderColor,
    this.avatarPath,
  });

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
        child: buildLocalImageWidget(
          source: avatarPath,
          fit: BoxFit.cover,
          fallback: _buildFallbackAvatar(),
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackAvatar();
          },
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      color: const Color(0xFFCFCFCF),
      child: const Icon(
        Icons.person,
        size: 48,
        color: Color(0xFF666666),
      ),
    );
  }
}
