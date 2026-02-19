class GameProject {
  String title;
  String? imageUrl;
  List<String> genres;
  final DateTime createdAt;

  GameProject({
    this.title = 'New Game Project',
    this.imageUrl,
    this.genres = const [],
    required this.createdAt,
  });

  GameProject copyWith({
    String? title,
    String? imageUrl,
    List<String>? genres,
  }) {
    return GameProject(
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      genres: genres ?? this.genres,
      createdAt: createdAt,
    );
  }
}
