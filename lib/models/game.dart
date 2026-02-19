enum GameStatus { completed, playing, wishlist }

class Game {
  final int id;
  final String title;
  final String coverUrl;
  final String summary;
  final List<String> genres;
  final String? platform;
  double? userRating;
  String? userReview;
  DateTime? dateCompleted;
  GameStatus status;
  bool isTopFive;

  Game({
    required this.id,
    required this.title,
    this.coverUrl = '',
    this.summary = '',
    this.genres = const [],
    this.platform,
    this.userRating,
    this.userReview,
    this.dateCompleted,
    this.status = GameStatus.completed,
    this.isTopFive = false,
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
    );
  }

  Game copyWith({
    int? id,
    String? title,
    String? coverUrl,
    String? summary,
    List<String>? genres,
    String? platform,
    double? userRating,
    String? userReview,
    DateTime? dateCompleted,
    GameStatus? status,
    bool? isTopFive,
  }) {
    return Game(
      id: id ?? this.id,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      summary: summary ?? this.summary,
      genres: genres ?? this.genres,
      platform: platform ?? this.platform,
      userRating: userRating ?? this.userRating,
      userReview: userReview ?? this.userReview,
      dateCompleted: dateCompleted ?? this.dateCompleted,
      status: status ?? this.status,
      isTopFive: isTopFive ?? this.isTopFive,
    );
  }
}
