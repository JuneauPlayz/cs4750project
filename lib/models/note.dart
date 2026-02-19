class Note {
  final String id;
  String title;
  String body;
  final DateTime createdAt;
  DateTime updatedAt;
  String? tag;

  Note({
    required this.id,
    this.title = '',
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.tag,
  });

  Note copyWith({
    String? title,
    String? body,
    DateTime? updatedAt,
    String? tag,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tag: tag ?? this.tag,
    );
  }
}
