enum ContentType { character, enemy, skill, item }

class ContentEntry {
  final String id;
  String name;
  ContentType type;
  String description;
  String? imageUrl;
  Map<String, String> attributes;
  final DateTime createdAt;

  ContentEntry({
    required this.id,
    required this.name,
    this.type = ContentType.character,
    this.description = '',
    this.imageUrl,
    this.attributes = const {},
    required this.createdAt,
  });

  ContentEntry copyWith({
    String? name,
    ContentType? type,
    String? description,
    String? imageUrl,
    Map<String, String>? attributes,
  }) {
    return ContentEntry(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      attributes: attributes ?? this.attributes,
      createdAt: createdAt,
    );
  }
}
