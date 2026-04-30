class Note {
  final String id;
  String title;
  String body;
  final DateTime createdAt;
  DateTime updatedAt;
  String? tag;
  bool isPinned;

  Note({
    required this.id,
    this.title = '',
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.tag,
    this.isPinned = false,
  });

  Note copyWith({
    String? title,
    String? body,
    DateTime? updatedAt,
    String? tag,
    bool? isPinned,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tag: tag ?? this.tag,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toStorageMap() {
    return {
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tag': tag,
      'isPinned': isPinned,
    };
  }

  factory Note.fromStorageMap(String id, Map<String, dynamic> map) {
    final now = DateTime.now();
    return Note(
      id: id,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? now,
      tag: map['tag'] as String?,
      isPinned: map['isPinned'] as bool? ?? false,
    );
  }
}
