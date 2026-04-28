class ReportCommentRecord {
  final String authorUsername;
  final String? authorAvatarUrl;
  final bool isAnonymous;
  final String commentText;
  final DateTime createdAt;

  const ReportCommentRecord({
    required this.authorUsername,
    required this.authorAvatarUrl,
    required this.isAnonymous,
    required this.commentText,
    required this.createdAt,
  });

  factory ReportCommentRecord.fromMap(Map<String, dynamic> map) {
    return ReportCommentRecord(
      authorUsername: map['author_username'] as String? ?? 'Anonimo',
      authorAvatarUrl: map['author_avatar_url'] as String?,
      isAnonymous: (map['is_anonymous'] as bool?) ?? true,
      commentText: map['comment_text'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'author_username': authorUsername,
      'author_avatar_url': authorAvatarUrl,
      'is_anonymous': isAnonymous,
      'comment_text': commentText,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}
