import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/game.dart';
import '../services/game_concept_service.dart';
import '../services/firestore_user_data_service.dart';

class DiscoveryProvider extends ChangeNotifier {
  DiscoveryProvider({FirestoreUserDataService? userDataService})
    : _userDataService = userDataService ?? FirestoreUserDataService();

  final GameConceptService _gameConceptService = GameConceptService();
  final FirestoreUserDataService _userDataService;
  final List<Game> _similarGames = [];
  List<Game> _searchResults = [];
  List<Game> _recommendations = [];
  bool _isSearching = false;
  bool _isLoadingRecommendations = false;
  String? _searchError;
  String? _userId;
  bool _hasSavedResearchPool = false;
  final Map<int, String> _recommendationReasons = {};
  final Set<int> _dismissedRecommendationIds = {};

  List<Game> get similarGames => List.unmodifiable(_similarGames);
  List<Game> get searchResults => _searchResults;
  List<Game> get recommendations => _recommendations;
  bool get isSearching => _isSearching;
  bool get isLoadingRecommendations => _isLoadingRecommendations;
  String? get searchError => _searchError;
  bool get hasSavedResearchPool => _hasSavedResearchPool;
  String? recommendationReasonFor(int gameId) => _recommendationReasons[gameId];

  void addSimilarGame(Game game) {
    if (!_similarGames.any((g) => g.id == game.id)) {
      _similarGames.add(game);
      notifyListeners();
      unawaited(_persistSimilarGame(game));
    }
  }

  void removeSimilarGame(int id) {
    _similarGames.removeWhere((g) => g.id == id);
    if (_similarGames.isEmpty) {
      _hasSavedResearchPool = false;
    }
    notifyListeners();
    unawaited(_deleteSimilarGame(id));
  }

  void updateGameNotes(Game game, String notes) {
    final index = _similarGames.indexWhere(
      (existing) => existing.id == game.id,
    );
    final updatedGame = game.copyWith(userNotes: notes);

    if (index >= 0) {
      _similarGames[index] = _mergeGameDetails(
        _similarGames[index],
        updatedGame,
        notes,
      );
    } else {
      _similarGames.add(updatedGame);
    }

    notifyListeners();
    unawaited(
      _persistSimilarGame(index >= 0 ? _similarGames[index] : updatedGame),
    );
  }

  Game _mergeGameDetails(Game existing, Game incoming, String notes) {
    return Game(
      id: existing.id,
      title: incoming.title.isNotEmpty ? incoming.title : existing.title,
      coverUrl: incoming.coverUrl.isNotEmpty
          ? incoming.coverUrl
          : existing.coverUrl,
      summary: incoming.summary.isNotEmpty
          ? incoming.summary
          : existing.summary,
      genres: incoming.genres.isNotEmpty ? incoming.genres : existing.genres,
      platform: incoming.platform ?? existing.platform,
      metacriticScore: incoming.metacriticScore ?? existing.metacriticScore,
      released: incoming.released ?? existing.released,
      website: incoming.website ?? existing.website,
      metacriticUrl: incoming.metacriticUrl ?? existing.metacriticUrl,
      redditUrl: incoming.redditUrl ?? existing.redditUrl,
      userNotes: notes,
    );
  }

  Future<void> searchGames(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _searchError = null;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _searchError = null;
    notifyListeners();

    try {
      final uri = Uri.parse(
        '$rawgBaseUrl/games?key=$rawgApiKey&search=${Uri.encodeComponent(query)}&page_size=20',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>;
        _searchResults = results.map((r) => Game.fromRawgJson(r)).toList();
      } else {
        _searchError = 'Search failed (${response.statusCode})';
        _searchResults = [];
      }
    } catch (e) {
      _searchError = 'Network error. Check your connection.';
      _searchResults = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  Future<Game?> fetchGameDetails(int gameId) async {
    try {
      final uri = Uri.parse('$rawgBaseUrl/games/$gameId?key=$rawgApiKey');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Game.fromRawgJson(data);
      }
    } catch (e) {
      // return null on failure
    }
    return null;
  }

  Future<void> fetchRecommendationsForConcept(String conceptDescription) async {
    final trimmedDescription = conceptDescription.trim();
    if (trimmedDescription.isEmpty) {
      _recommendations = [];
      notifyListeners();
      return;
    }

    _isLoadingRecommendations = true;
    notifyListeners();

    try {
      final suggestedTitles = await _gameConceptService.suggestReferenceGames(
        trimmedDescription,
      );

      final candidates = <Game>[];
      final reasons = <int, String>{};
      for (final title in suggestedTitles) {
        final match = await _searchSuggestedGame(title);
        if (match != null &&
            !candidates.any((existing) => existing.id == match.id)) {
          candidates.add(match);
          reasons[match.id] = _buildRecommendationReason(
            game: match,
            suggestedTitle: title,
          );
        }
      }

      candidates.sort((a, b) => _scoreGame(b).compareTo(_scoreGame(a)));
      _recommendations = candidates
          .where((game) => !_dismissedRecommendationIds.contains(game.id))
          .take(10)
          .toList();
      _recommendationReasons
        ..clear()
        ..addAll(reasons);
    } catch (e) {
      _recommendations = [];
      _recommendationReasons.clear();
    }

    _isLoadingRecommendations = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _searchError = null;
    notifyListeners();
  }

  void dismissRecommendation(int id) {
    _dismissedRecommendationIds.add(id);
    _recommendations.removeWhere((game) => game.id == id);
    notifyListeners();
  }

  Future<void> loadForUser(String userId) async {
    _userId = userId;
    _searchResults = [];
    _recommendations = [];
    _isSearching = false;
    _isLoadingRecommendations = false;
    _searchError = null;

    try {
      _similarGames
        ..clear()
        ..addAll(await _userDataService.loadSimilarGames(userId));
      _hasSavedResearchPool = _similarGames.isNotEmpty;
    } catch (_) {
      _similarGames.clear();
      _hasSavedResearchPool = false;
    }
    _recommendationReasons.clear();
    _dismissedRecommendationIds.clear();
    notifyListeners();
  }

  Future<void> _persistSimilarGame(Game game) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      await _userDataService.saveSimilarGame(userId, game);
    } catch (_) {
      // Keep local state even if the network write fails.
    }
  }

  Future<void> _deleteSimilarGame(int gameId) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      await _userDataService.deleteSimilarGame(userId, gameId);
    } catch (_) {
      // Ignore remote delete failures for now.
    }
  }

  void reset() {
    _userId = null;
    _similarGames.clear();
    _searchResults = [];
    _recommendations = [];
    _isSearching = false;
    _isLoadingRecommendations = false;
    _searchError = null;
    _hasSavedResearchPool = false;
    _recommendationReasons.clear();
    _dismissedRecommendationIds.clear();
    notifyListeners();
  }

  Future<Game?> _searchSuggestedGame(String title) async {
    final uri = Uri.parse(
      '$rawgBaseUrl/games?key=$rawgApiKey&search=${Uri.encodeComponent(title)}&page_size=8',
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) return null;

    final data = json.decode(response.body);
    final results = (data['results'] as List<dynamic>? ?? [])
        .map((result) => Game.fromRawgJson(result))
        .toList();
    if (results.isEmpty) return null;

    results.sort(
      (a, b) =>
          _matchTitleScore(b, title).compareTo(_matchTitleScore(a, title)),
    );
    return results.first;
  }

  double _matchTitleScore(Game game, String requestedTitle) {
    final normalizedTitle = game.title.trim().toLowerCase();
    final normalizedRequested = requestedTitle.trim().toLowerCase();

    double score = _scoreGame(game);
    if (normalizedTitle == normalizedRequested) {
      score += 100;
    } else if (normalizedTitle.contains(normalizedRequested) ||
        normalizedRequested.contains(normalizedTitle)) {
      score += 40;
    }
    return score;
  }

  double _scoreGame(Game game) {
    double score = 0;
    final year = int.tryParse(game.released?.split('-').first ?? '');
    if (year != null) {
      if (year >= 2016) {
        score += 35 + (year - 2016).clamp(0, 10);
      } else {
        score -= (2016 - year).clamp(0, 30);
      }
    }

    if (game.metacriticScore != null) {
      score += game.metacriticScore! / 4;
    }

    return score;
  }

  String _buildRecommendationReason({
    required Game game,
    required String suggestedTitle,
  }) {
    final sameTitle =
        game.title.trim().toLowerCase() == suggestedTitle.trim().toLowerCase();
    final year = game.released?.split('-').first;

    if (sameTitle && year != null) {
      return 'AI flagged $suggestedTitle as a close reference, and this is the current match from $year.';
    }
    if (sameTitle) {
      return 'AI flagged $suggestedTitle as a close reference for your concept.';
    }
    return 'Matches the reference direction of $suggestedTitle and shares a similar design lane.';
  }
}
