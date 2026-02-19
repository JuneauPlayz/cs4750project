class GameProject {
  String title;
  String description;
  List<String> genres;
  final DateTime createdAt;

  GameProject({
    this.title = 'New Game Project',
    this.description = '',
    this.genres = const [],
    required this.createdAt,
  });

  GameProject copyWith({
    String? title,
    String? description,
    List<String>? genres,
  }) {
    return GameProject(
      title: title ?? this.title,
      description: description ?? this.description,
      genres: genres ?? this.genres,
      createdAt: createdAt,
    );
  }
}
