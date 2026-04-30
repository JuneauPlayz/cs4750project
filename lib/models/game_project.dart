class GameProject {
  String title;
  String? imageUrl;
  String conceptDescription;
  final DateTime createdAt;

  GameProject({
    this.title = 'New Game Project',
    this.imageUrl,
    this.conceptDescription = '',
    required this.createdAt,
  });

  GameProject copyWith({
    String? title,
    String? imageUrl,
    String? conceptDescription,
  }) {
    return GameProject(
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      conceptDescription: conceptDescription ?? this.conceptDescription,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toStorageMap() {
    return {
      'title': title,
      'imageUrl': _persistableImageUrl(imageUrl),
      'conceptDescription': conceptDescription,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GameProject.fromStorageMap(Map<String, dynamic> map) {
    return GameProject(
      title: map['title'] as String? ?? 'New Game Project',
      imageUrl: map['imageUrl'] as String?,
      conceptDescription: map['conceptDescription'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static String? _persistableImageUrl(String? value) {
    if (value == null || value.isEmpty) return null;

    final normalized = value.toLowerCase();
    if (normalized.startsWith('http://') ||
        normalized.startsWith('https://') ||
        normalized.startsWith('gs://')) {
      return value;
    }

    return null;
  }
}
