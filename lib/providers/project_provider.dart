import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/game_project.dart';
import '../models/project_folder.dart';

import '../models/folder_entry.dart';

class ProjectProvider extends ChangeNotifier {
  GameProject? _project;
  final List<ProjectFolder> _folders = [];
  final _uuid = const Uuid();

  GameProject? get project => _project;
  List<ProjectFolder> get folders => List.unmodifiable(_folders);

  void setupProject(String title, {String? imageUrl, List<String> genres = const []}) {
    _project = GameProject(
      title: title,
      imageUrl: imageUrl,
      genres: genres,
      createdAt: DateTime.now(),
    );
    notifyListeners();
  }

  void updateTitle(String newTitle) {
    if (_project != null) {
      _project = _project!.copyWith(title: newTitle);
      notifyListeners();
    }
  }

  void updateImageUrl(String? url) {
    if (_project != null) {
      _project = _project!.copyWith(imageUrl: url);
      notifyListeners();
    }
  }

  // Folder Management
  void addFolder(String name) {
    final newFolder = ProjectFolder(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
    );
    _folders.add(newFolder);
    notifyListeners();
  }

  void deleteFolder(String id) {
    _folders.removeWhere((f) => f.id == id);
    notifyListeners();
  }

  void renameFolder(String id, String newName) {
    final index = _folders.indexWhere((f) => f.id == id);
    if (index != -1) {
      _folders[index].name = newName;
      notifyListeners();
    }
  }

  // Entry Management
  void addEntry(String folderId, FolderEntry entry) {
    final folderIndex = _folders.indexWhere((f) => f.id == folderId);
    if (folderIndex != -1) {
      _folders[folderIndex].entries.add(entry);
      notifyListeners();
    }
  }

  void deleteEntry(String folderId, String entryId) {
    final folderIndex = _folders.indexWhere((f) => f.id == folderId);
    if (folderIndex != -1) {
      _folders[folderIndex].entries.removeWhere((e) => e.id == entryId);
      notifyListeners();
    }
  }

  ProjectFolder? getFolderById(String id) {
    try {
      return _folders.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }
}
