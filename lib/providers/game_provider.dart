import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/game.dart';

class GameProvider extends ChangeNotifier {
  final List<Game> _games = [];
  List<Game> _searchResults = [];
  bool _isSearching = false;

  List<Game> get games => List.unmodifiable(_games);
  List<Game> get completedGames =>
      _games.where((g) => g.status == GameStatus.completed).toList();
  List<Game> get currentlyPlaying =>
      _games.where((g) => g.status == GameStatus.playing).toList();
  List<Game> get topFive => _games.where((g) => g.isTopFive).toList();
  List<Game> get searchResults => _searchResults;
  bool get isSearching => _isSearching;

  void addGame(Game game) {
    // Replace if game already exists
    final existingIndex = _games.indexWhere((g) => g.id == game.id);
    if (existingIndex >= 0) {
      _games[existingIndex] = game;
    } else {
      _games.add(game);
    }
    notifyListeners();
  }

  void updateGame(Game game) {
    final index = _games.indexWhere((g) => g.id == game.id);
    if (index >= 0) {
      _games[index] = game;
      notifyListeners();
    }
  }

  void removeGame(int id) {
    _games.removeWhere((g) => g.id == id);
    notifyListeners();
  }

  bool canAddToTopFive() {
    return topFive.length < 5;
  }

  Future<void> searchGames(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
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
        _searchResults = [];
      }
    } catch (e) {
      _searchResults = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }
}
