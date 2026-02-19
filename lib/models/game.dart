class Game {
  final int id;
  final String title;
  final String coverUrl;
  final String summary;
  final List<String> genres;
  final String? platform;
  final double? metacriticScore;
  final String? released;
  String? userNotes;

  Game({
    required this.id,
    required this.title,
    this.coverUrl = '',
    this.summary = '',
    this.genres = const [],
    this.platform,
    this.metacriticScore,
    this.released,
    this.userNotes,
  });

  factory Game.fromRawgJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'] as int,
      title: json['name'] as String? ?? 'Unknown',
      coverUrl: json['background_image'] as String? ?? '',
      summary: json['description_raw'] as String? ?? '',
      genres: (json['genres'] as List<dynamic>?)
              ?.map((g) => g['name'] as String)
              .toList() ??
          [],
      platform: (json['platforms'] as List<dynamic>?)
          ?.map((p) => p['platform']['name'] as String)
          .join(', '),
      metacriticScore: (json['metacritic'] as num?)?.toDouble(),
      released: json['released'] as String?,
    );
  }

  Game copyWith({
    int? id,
    String? title,
    String? coverUrl,
    String? summary,
    List<String>? genres,
    String? platform,
    double? metacriticScore,
    String? released,
    String? userNotes,
  }) {
    return Game(
      id: id ?? this.id,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      summary: summary ?? this.summary,
      genres: genres ?? this.genres,
      platform: platform ?? this.platform,
      metacriticScore: metacriticScore ?? this.metacriticScore,
      released: released ?? this.released,
      userNotes: userNotes ?? this.userNotes,
    );
  }
}
