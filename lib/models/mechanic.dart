class Mechanic {
  final String id;
  String title;
  String description;
  String? sourceGameTitle;
  final DateTime createdAt;

  Mechanic({
    required this.id,
    required this.title,
    this.description = '',
    this.sourceGameTitle,
    required this.createdAt,
  });

  Mechanic copyWith({
    String? title,
    String? description,
    String? sourceGameTitle,
  }) {
    return Mechanic(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      sourceGameTitle: sourceGameTitle ?? this.sourceGameTitle,
      createdAt: createdAt,
    );
  }
}
