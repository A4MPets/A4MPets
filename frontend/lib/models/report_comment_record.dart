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
      createdAt: _parseCreatedAt(map['created_at']),
    );
  }

  static DateTime _parseCreatedAt(Object? value) {
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String) {
      final int? timestamp = int.tryParse(value);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      final DateTime? parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    return DateTime.now();
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
