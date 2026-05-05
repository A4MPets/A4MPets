import 'package:flutter/material.dart';

import 'image_preview_dialog.dart';
import 'local_image_widget.dart';

class UserIdentityHeader extends StatelessWidget {
  final bool isDarkMode;
  final String username;
  final String? avatarPath;
  final VoidCallback? onEditAvatarPressed;
  final bool isEditingAvatar;

  const UserIdentityHeader({
    super.key,
    required this.isDarkMode,
    required this.username,
    this.avatarPath,
    this.onEditAvatarPressed,
    this.isEditingAvatar = false,
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
          isDarkMode: isDarkMode,
          borderColor: avatarBorderColor,
          avatarPath: avatarPath,
          onEditPressed: onEditAvatarPressed,
          isBusy: isEditingAvatar,
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
  final bool isDarkMode;
  final Color borderColor;
  final String? avatarPath;
  final VoidCallback? onEditPressed;
  final bool isBusy;

  const _UserAvatar({
    required this.isDarkMode,
    required this.borderColor,
    this.avatarPath,
    this.onEditPressed,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    final String? imageSource = avatarPath?.trim();
    final Widget avatarImage = buildLocalImageWidget(
      source: avatarPath,
      fit: BoxFit.cover,
      fallback: _buildFallbackAvatar(),
      errorBuilder: (context, error, stackTrace) {
        return _buildFallbackAvatar();
      },
    );

    return SizedBox(
      width: 106,
      height: 106,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 106,
            height: 106,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2),
            ),
            child: ClipOval(
              child: imageSource != null && imageSource.isNotEmpty
                  ? ExpandableImage(
                      source: imageSource,
                      isDarkMode: isDarkMode,
                      title: 'Foto de perfil',
                      child: avatarImage,
                    )
                  : avatarImage,
            ),
          ),
          if (onEditPressed != null)
            Positioned(
              right: -4,
              bottom: -4,
              child: SizedBox(
                width: 34,
                height: 34,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: isBusy ? null : onEditPressed,
                    customBorder: const CircleBorder(),
                    child: isBusy
                        ? const Padding(
                            padding: EdgeInsets.all(9),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF404040),
                            ),
                          )
                        : const Icon(
                            Icons.edit,
                            size: 18,
                            color: Color(0xFF404040),
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      color: const Color(0xFFCFCFCF),
      child: const Icon(Icons.person, size: 48, color: Color(0xFF666666)),
    );
  }
}
