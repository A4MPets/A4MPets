import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/found_pet_report_record.dart';
import '../models/generic_report_record.dart';
import '../models/hazard_report_record.dart';
import '../models/local_user_profile.dart';
import '../models/lost_pet_report_record.dart';
import '../models/report_comment_record.dart';
import '../providers/local_data_providers.dart';
import '../theme/app_palette.dart';
import 'shared/local_image_widget.dart';
import 'shared/panel_scroll_view.dart';

enum ReportCommentSubjectType { hazard, lostPet, foundPet, generic }

class HazardCommentsPanelContent extends StatelessWidget {
  final bool isDarkMode;
  final HazardReportRecord hazard;

  const HazardCommentsPanelContent({
    super.key,
    required this.isDarkMode,
    required this.hazard,
  });

  @override
  Widget build(BuildContext context) {
    return ReportCommentsPanelContent(
      isDarkMode: isDarkMode,
      subjectType: ReportCommentSubjectType.hazard,
      reportId: hazard.id,
    );
  }
}

class ReportCommentsPanelContent extends ConsumerStatefulWidget {
  final bool isDarkMode;
  final ReportCommentSubjectType subjectType;
  final int reportId;

  const ReportCommentsPanelContent({
    super.key,
    required this.isDarkMode,
    required this.subjectType,
    required this.reportId,
  });

  @override
  ConsumerState<ReportCommentsPanelContent> createState() =>
      _ReportCommentsPanelContentState();
}

class _ReportCommentsPanelContentState
    extends ConsumerState<ReportCommentsPanelContent> {
  static const String _confirmHazardText =
      'Confirmo que hay un peligro en este area';
  static const String _denyHazardText = 'No veo que haya peligro en este area';

  late final TextEditingController _commentController;
  Future<List<ReportCommentRecord>>? _hazardCommentsFuture;
  bool _isSending = false;
  String? _sendErrorText;

  bool get _showsQuickHazardActions =>
      widget.subjectType == ReportCommentSubjectType.hazard;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    if (_showsQuickHazardActions) {
      _reloadHazardComments();
    }
  }

  @override
  void didUpdateWidget(covariant ReportCommentsPanelContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.subjectType != oldWidget.subjectType ||
        widget.reportId != oldWidget.reportId) {
      if (_showsQuickHazardActions) {
        _reloadHazardComments();
      } else {
        _hazardCommentsFuture = null;
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _reloadHazardComments() {
    _hazardCommentsFuture = ref
        .read(userLocalRepositoryProvider)
        .getHazardComments(widget.reportId);
  }

  Future<void> _sendComment([String? presetText]) async {
    final String text = (presetText ?? _commentController.text).trim();
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _sendErrorText = null;
      _isSending = true;
    });

    try {
      final LocalUserProfile profile = await ref.read(
        localUserProfileProvider.future,
      );

      final ReportCommentRecord comment = ReportCommentRecord(
        authorUsername: profile.isAuthenticated ? profile.username : 'Anonimo',
        authorAvatarUrl: profile.isAuthenticated ? profile.avatarPath : null,
        isAnonymous: !profile.isAuthenticated,
        commentText: text,
        createdAt: DateTime.now(),
      );

      switch (widget.subjectType) {
        case ReportCommentSubjectType.hazard:
          await ref
              .read(hazardReportsControllerProvider.notifier)
              .addCommentToHazard(
                hazardId: widget.reportId,
                comment: HazardCommentRecord(
                  authorUsername: comment.authorUsername,
                  authorAvatarUrl: comment.authorAvatarUrl,
                  isAnonymous: comment.isAnonymous,
                  commentText: comment.commentText,
                  createdAt: comment.createdAt,
                ),
              );
        case ReportCommentSubjectType.lostPet:
          await ref
              .read(lostPetReportsControllerProvider.notifier)
              .addCommentToLostPetReport(
                reportId: widget.reportId,
                comment: comment,
              );
        case ReportCommentSubjectType.foundPet:
          await ref
              .read(foundPetReportsControllerProvider.notifier)
              .addCommentToFoundPetReport(
                reportId: widget.reportId,
                comment: comment,
              );
        case ReportCommentSubjectType.generic:
          await ref
              .read(genericReportsControllerProvider.notifier)
              .addCommentToGenericReport(
                reportId: widget.reportId,
                comment: comment,
              );
      }

      if (!mounted) {
        return;
      }

      _commentController.clear();
      if (_showsQuickHazardActions) {
        setState(_reloadHazardComments);
      }
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

  List<ReportCommentRecord> _currentComments() {
    switch (widget.subjectType) {
      case ReportCommentSubjectType.hazard:
        final List<HazardReportRecord> hazards =
            ref.watch(hazardReportsControllerProvider).asData?.value ??
            const <HazardReportRecord>[];
        return hazards
                .where((HazardReportRecord item) => item.id == widget.reportId)
                .firstOrNull
                ?.comments ??
            const <ReportCommentRecord>[];
      case ReportCommentSubjectType.lostPet:
        final List<LostPetReportRecord> reports =
            ref.watch(lostPetReportsControllerProvider).asData?.value ??
            const <LostPetReportRecord>[];
        return reports
                .where((LostPetReportRecord item) => item.id == widget.reportId)
                .firstOrNull
                ?.comments ??
            const <ReportCommentRecord>[];
      case ReportCommentSubjectType.foundPet:
        final List<FoundPetReportRecord> reports =
            ref.watch(foundPetReportsControllerProvider).asData?.value ??
            const <FoundPetReportRecord>[];
        return reports
                .where(
                  (FoundPetReportRecord item) => item.id == widget.reportId,
                )
                .firstOrNull
                ?.comments ??
            const <ReportCommentRecord>[];
      case ReportCommentSubjectType.generic:
        final List<GenericReportRecord> reports =
            ref.watch(genericReportsControllerProvider).asData?.value ??
            const <GenericReportRecord>[];
        return reports
                .where((GenericReportRecord item) => item.id == widget.reportId)
                .firstOrNull
                ?.comments ??
            const <ReportCommentRecord>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    final Future<List<ReportCommentRecord>>? hazardCommentsFuture =
        _hazardCommentsFuture;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _showsQuickHazardActions && hazardCommentsFuture != null
              ? FutureBuilder<List<ReportCommentRecord>>(
                  future: hazardCommentsFuture,
                  builder: (BuildContext context, snapshot) {
                    return _buildCommentsList(
                      snapshot.data ?? const <ReportCommentRecord>[],
                      isLoading:
                          snapshot.connectionState != ConnectionState.done,
                    );
                  },
                )
              : _buildCommentsList(_currentComments()),
        ),
        if (_showsQuickHazardActions) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSending
                      ? null
                      : () => _sendComment(_confirmHazardText),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppPalette.primaryBlue,
                    side: const BorderSide(color: AppPalette.primaryBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Confirmar peligro',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSending
                      ? null
                      : () => _sendComment(_denyHazardText),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppPalette.dangerRed,
                    side: const BorderSide(color: AppPalette.dangerRed),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Desmentir peligro',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
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

  Widget _buildCommentsList(
    List<ReportCommentRecord> comments, {
    bool isLoading = false,
  }) {
    return PanelScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          if (!isLoading && comments.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppPalette.cardBackground(widget.isDarkMode),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Todavía no hay comentarios para este reporte.',
                style: TextStyle(
                  color: AppPalette.textPrimary(widget.isDarkMode),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (comments.isNotEmpty)
            ...comments.map(
              (ReportCommentRecord comment) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CommentTile(
                  isDarkMode: widget.isDarkMode,
                  comment: comment,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final bool isDarkMode;
  final ReportCommentRecord comment;

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
                errorBuilder: (_, _, _) => _defaultAvatar(),
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
      return 'Hace ${diff.inMinutes} min';
    }
    if (diff.inHours < 24) {
      return 'Hace ${diff.inHours} h';
    }
    if (diff.inDays < 7) {
      final int days = diff.inDays;
      return 'Hace $days dia${days == 1 ? '' : 's'}';
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
    return 'Hace $years ano${years == 1 ? '' : 's'}';
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
