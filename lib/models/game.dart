class Game {
  final int id;
  final String title;
  final String coverUrl;
  final String summary;
  final List<String> genres;
  final String? platform;
  final double? metacriticScore;
  final String? released;
  final String? website;
  final String? metacriticUrl;
  final String? redditUrl;
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
    this.website,
    this.metacriticUrl,
    this.redditUrl,
    this.userNotes,
  });

  factory Game.fromRawgJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'] as int,
      title: json['name'] as String? ?? 'Unknown',
      coverUrl: json['background_image'] as String? ?? '',
      summary: json['description_raw'] as String? ?? '',
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((g) => g['name'] as String)
              .toList() ??
          [],
      platform: (json['platforms'] as List<dynamic>?)
          ?.map((p) => p['platform']['name'] as String)
          .join(', '),
      metacriticScore: (json['metacritic'] as num?)?.toDouble(),
      released: json['released'] as String?,
      website: json['website'] as String?,
      metacriticUrl: json['metacritic_url'] as String?,
      redditUrl: json['reddit_url'] as String?,
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
    String? website,
    String? metacriticUrl,
    String? redditUrl,
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
      website: website ?? this.website,
      metacriticUrl: metacriticUrl ?? this.metacriticUrl,
      redditUrl: redditUrl ?? this.redditUrl,
      userNotes: userNotes ?? this.userNotes,
    );
  }

  Map<String, dynamic> toStorageMap() {
    return {
      'id': id,
      'title': title,
      'coverUrl': coverUrl,
      'summary': summary,
      'genres': genres,
      'platform': platform,
      'metacriticScore': metacriticScore,
      'released': released,
      'website': website,
      'metacriticUrl': metacriticUrl,
      'redditUrl': redditUrl,
      'userNotes': userNotes,
    };
  }

  factory Game.fromStorageMap(Map<String, dynamic> map) {
    return Game(
      id: (map['id'] as num?)?.toInt() ?? 0,
      title: map['title'] as String? ?? 'Unknown',
      coverUrl: map['coverUrl'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      genres:
          (map['genres'] as List<dynamic>?)
              ?.map((genre) => genre.toString())
              .toList() ??
          const [],
      platform: map['platform'] as String?,
      metacriticScore: (map['metacriticScore'] as num?)?.toDouble(),
      released: map['released'] as String?,
      website: map['website'] as String?,
      metacriticUrl: map['metacriticUrl'] as String?,
      redditUrl: map['redditUrl'] as String?,
      userNotes: map['userNotes'] as String?,
    );
  }
}
