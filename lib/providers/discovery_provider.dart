import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/game.dart';

class DiscoveryProvider extends ChangeNotifier {
  final List<Game> _similarGames = [];
  List<Game> _searchResults = [];
  List<Game> _recommendations = [];
  bool _isSearching = false;
  bool _isLoadingRecommendations = false;
  String? _searchError;

  List<Game> get similarGames => List.unmodifiable(_similarGames);
  List<Game> get searchResults => _searchResults;
  List<Game> get recommendations => _recommendations;
  bool get isSearching => _isSearching;
  bool get isLoadingRecommendations => _isLoadingRecommendations;
  String? get searchError => _searchError;

  void addSimilarGame(Game game) {
    if (!_similarGames.any((g) => g.id == game.id)) {
      _similarGames.add(game);
      notifyListeners();
    }
  }

  void removeSimilarGame(int id) {
    _similarGames.removeWhere((g) => g.id == id);
    notifyListeners();
  }

  void updateGameNotes(int id, String notes) {
    final index = _similarGames.indexWhere((g) => g.id == id);
    if (index >= 0) {
      _similarGames[index].userNotes = notes;
      notifyListeners();
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

  Future<void> fetchRecommendations(List<String> genres) async {
    if (genres.isEmpty) {
      _recommendations = [];
      notifyListeners();
      return;
    }

    _isLoadingRecommendations = true;
    notifyListeners();

    try {
      // Create genre slug list for API call (simplified)
      final genreSlugs = genres.take(3).map((g) => g.toLowerCase().replaceAll(' ', '-')).join(',');
      final uri = Uri.parse(
        '$rawgBaseUrl/games?key=$rawgApiKey&genres=$genreSlugs&ordering=-rating&page_size=10',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>;
        _recommendations = results.map((r) => Game.fromRawgJson(r)).toList();
      }
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
}
