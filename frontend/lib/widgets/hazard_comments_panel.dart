import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../models/hazard_report_record.dart';
import '../models/local_user_profile.dart';
import '../providers/local_data_providers.dart';
import '../theme/app_palette.dart';
import 'shared/local_image_widget.dart';

class HazardCommentsPanelContent extends ConsumerStatefulWidget {
  final bool isDarkMode;
  final HazardReportRecord hazard;

  const HazardCommentsPanelContent({
    super.key,
    required this.isDarkMode,
    required this.hazard,
  });

  @override
  ConsumerState<HazardCommentsPanelContent> createState() =>
      _HazardCommentsPanelContentState();
}

class _HazardCommentsPanelContentState
    extends ConsumerState<HazardCommentsPanelContent> {
  late final TextEditingController _commentController;
  bool _isSending = false;
  String? _sendErrorText;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final String text = _commentController.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _sendErrorText = null;
    });

    setState(() {
      _isSending = true;
    });

    try {
      final LocalUserProfile profile = await ref.read(
        localUserProfileProvider.future,
      );

      final HazardCommentRecord comment = HazardCommentRecord(
        authorUsername: profile.isAuthenticated ? profile.username : 'Anónimo',
        authorAvatarUrl: profile.isAuthenticated ? profile.avatarPath : null,
        isAnonymous: !profile.isAuthenticated,
        commentText: text,
        createdAt: DateTime.now(),
      );

      await ref
          .read(hazardReportsControllerProvider.notifier)
          .addCommentToHazard(hazardId: widget.hazard.id, comment: comment);

      if (!mounted) {
        return;
      }

      _commentController.clear();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _sendErrorText = 'No se pudo enviar el comentario. Intenta nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<HazardReportRecord>> hazardsAsync = ref.watch(
      hazardReportsControllerProvider,
    );

    final List<HazardReportRecord> allHazards =
        hazardsAsync.asData?.value ?? const <HazardReportRecord>[];
    HazardReportRecord currentHazard = widget.hazard;
    for (final HazardReportRecord item in allHazards) {
      if (item.id == widget.hazard.id) {
        currentHazard = item;
        break;
      }
    }

    final List<HazardCommentRecord> comments = currentHazard.comments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.separated(
                itemCount: comments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int index) {
                  return _CommentTile(
                    isDarkMode: widget.isDarkMode,
                    comment: comments[index],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Focus(
          onKeyEvent: (FocusNode node, KeyEvent event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.enter &&
                !HardwareKeyboard.instance.isShiftPressed) {
              if (!_isSending) {
                _sendComment();
              }
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: TextField(
            controller: _commentController,
            onSubmitted: (_) {
              if (!_isSending) {
                _sendComment();
              }
            },
            onChanged: (_) {
              if (_sendErrorText != null) {
                setState(() {
                  _sendErrorText = null;
                });
              }
            },
            textInputAction: TextInputAction.send,
            maxLength: 140,
            maxLines: 3,
            minLines: 2,
            style: TextStyle(
              color: AppPalette.textPrimary(widget.isDarkMode),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Escribe un comentario...',
              hintStyle: const TextStyle(
                color: AppPalette.textMutedDark,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              counterStyle: const TextStyle(
                color: AppPalette.textMutedDark,
                fontSize: 11,
              ),
              filled: true,
              fillColor: AppPalette.fieldBackground(widget.isDarkMode),
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
                  color: AppPalette.primaryBlue,
                  width: 1,
                ),
              ),
            ),
          ),
        ),
        if (_sendErrorText != null) ...[
          const SizedBox(height: 6),
          Text(
            _sendErrorText!,
            style: const TextStyle(
              color: AppPalette.dangerRed,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: _isSending ? null : _sendComment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPalette.primaryBlue,
              foregroundColor: AppPalette.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppPalette.white,
                    ),
                  )
                : const Text(
                    'Enviar comentario',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  final bool isDarkMode;
  final HazardCommentRecord comment;

  const _CommentTile({required this.isDarkMode, required this.comment});

  @override
  Widget build(BuildContext context) {
    final Color textColor = AppPalette.textPrimary(isDarkMode);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppPalette.cardBackground(isDarkMode),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppPalette.border(isDarkMode)),
            ),
            child: ClipOval(
              child: buildLocalImageWidget(
                source: comment.authorAvatarUrl,
                fit: BoxFit.cover,
                fallback: _defaultAvatar(),
                errorBuilder: (_, __, ___) => _defaultAvatar(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.authorUsername,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatRelativeTime(comment.createdAt),
                      style: const TextStyle(
                        color: AppPalette.textMutedDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.commentText,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: AppPalette.placeholderGray,
      child: const Icon(Icons.person, size: 18, color: AppPalette.iconGray),
    );
  }

  String _formatRelativeTime(DateTime createdAt) {
    final Duration diff = DateTime.now().difference(createdAt);

    if (diff.inSeconds < 60) {
      return 'Hace un momento';
    }

    if (diff.inMinutes < 60) {
      final int m = diff.inMinutes;
      return 'Hace $m min';
    }

    if (diff.inHours < 24) {
      final int h = diff.inHours;
      return 'Hace $h h';
    }

    if (diff.inDays < 7) {
      final int d = diff.inDays;
      return 'Hace $d día${d == 1 ? '' : 's'}';
    }

    final int weeks = (diff.inDays / 7).floor();
    if (weeks < 5) {
      return 'Hace $weeks sem';
    }

    final int months = (diff.inDays / 30).floor();
    if (months < 12) {
      return 'Hace $months mes${months == 1 ? '' : 'es'}';
    }

    final int years = (diff.inDays / 365).floor();
    return 'Hace $years año${years == 1 ? '' : 's'}';
  }
}
