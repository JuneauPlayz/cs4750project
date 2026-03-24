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
      'imageUrl': imageUrl,
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
}
