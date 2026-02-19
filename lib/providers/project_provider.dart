import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/game_project.dart';
import '../models/content_entry.dart';
import '../models/mechanic.dart';

class ProjectProvider extends ChangeNotifier {
  GameProject? _project;
  final List<ContentEntry> _content = [];
  final List<Mechanic> _mechanics = [];
  final _uuid = const Uuid();

  GameProject? get project => _project;
  List<ContentEntry> get allContent => List.unmodifiable(_content);
  List<Mechanic> get mechanics => List.unmodifiable(_mechanics);

  void setupProject(String title, {String description = '', List<String> genres = const []}) {
    _project = GameProject(
      title: title,
      description: description,
      genres: genres,
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }

  // Content Management
  List<ContentEntry> getContentByType(ContentType type) {
    return _content.where((c) => c.type == type).toList();
  }

  void addContent(String name, ContentType type, {String description = '', Map<String, String> attributes = const {}}) {
    final newContent = ContentEntry(
      id: _uuid.v4(),
      name: name,
      type: type,
      description: description,
      attributes: attributes,
      createdAt: DateTime.now(),
    );
    _content.add(newContent);
    notifyListeners();
  }

  void deleteContent(String id) {
    _content.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  // Mechanic Management
  void addMechanic(String title, {String description = '', String? sourceGame}) {
    final newMechanic = Mechanic(
      id: _uuid.v4(),
      title: title,
      description: description,
      sourceGameTitle: sourceGame,
      createdAt: DateTime.now(),
    );
    _mechanics.add(newMechanic);
    notifyListeners();
  }

  void deleteMechanic(String id) {
    _mechanics.removeWhere((m) => m.id == id);
    notifyListeners();
  }
}
