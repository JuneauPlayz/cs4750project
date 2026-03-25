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

  List<Game> get similarGames => List.unmodifiable(_similarGames);
  List<Game> get searchResults => _searchResults;
  List<Game> get recommendations => _recommendations;
  bool get isSearching => _isSearching;
  bool get isLoadingRecommendations => _isLoadingRecommendations;
  String? get searchError => _searchError;
  bool get hasSavedResearchPool => _hasSavedResearchPool;

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

  void updateGameNotes(int id, String notes) {
    final index = _similarGames.indexWhere((g) => g.id == id);
    if (index >= 0) {
      _similarGames[index].userNotes = notes;
      notifyListeners();
      unawaited(_persistSimilarGame(_similarGames[index]));
    }
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
      for (final title in suggestedTitles) {
        final match = await _searchSuggestedGame(title);
        if (match != null &&
            !candidates.any((existing) => existing.id == match.id)) {
          candidates.add(match);
        }
      }

      candidates.sort((a, b) => _scoreGame(b).compareTo(_scoreGame(a)));
      _recommendations = candidates.take(10).toList();
    } catch (e) {
      _recommendations = [];
    }

    _isLoadingRecommendations = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _searchError = null;
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
}
