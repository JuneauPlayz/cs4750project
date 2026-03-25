import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/game_project.dart';
import '../models/project_folder.dart';
import '../models/entry_type.dart';
import '../models/folder_entry.dart';
import '../services/firestore_user_data_service.dart';

class ProjectProvider extends ChangeNotifier {
  ProjectProvider({FirestoreUserDataService? userDataService})
    : _userDataService = userDataService ?? FirestoreUserDataService();

  final FirestoreUserDataService _userDataService;
  GameProject? _project;
  final List<ProjectFolder> _folders = [];
  final List<EntryTypeDefinition> _entryTypes = [];
  final _uuid = const Uuid();
  String? _userId;
  static const _uncategorizedFolderName = 'Uncategorized Imports';

  GameProject? get project => _project;
  List<ProjectFolder> get folders => List.unmodifiable(_folders);
  List<EntryTypeDefinition> get entryTypes => List.unmodifiable(_entryTypes);
  bool get needsOnboarding =>
      _project == null || _project!.conceptDescription.trim().isEmpty;

  void setupProject(
    String title, {
    String? imageUrl,
    String conceptDescription = '',
  }) {
    _project = GameProject(
      title: title,
      imageUrl: imageUrl,
      conceptDescription: conceptDescription,
      createdAt: DateTime.now(),
    );
    notifyListeners();
    unawaited(_persistWorkspace());
  }

  void updateTitle(String newTitle) {
    if (_project != null) {
      _project = _project!.copyWith(title: newTitle);
      notifyListeners();
      unawaited(_persistWorkspace());
    }
  }

  void updateImageUrl(String? url) {
    if (_project != null) {
      _project = _project!.copyWith(imageUrl: url);
      notifyListeners();
      unawaited(_persistWorkspace());
    }
  }

  void updateConceptDescription(String conceptDescription) {
    if (_project == null) return;
    _project = _project!.copyWith(
      conceptDescription: conceptDescription.trim(),
    );
    notifyListeners();
    unawaited(_persistWorkspace());
  }

  void saveProjectProfile({
    required String title,
    required String conceptDescription,
    String? imageUrl,
  }) {
    final trimmedTitle = title.trim().isEmpty
        ? 'Untitled Project'
        : title.trim();
    final trimmedDescription = conceptDescription.trim();

    if (_project == null) {
      _project = GameProject(
        title: trimmedTitle,
        imageUrl: imageUrl,
        conceptDescription: trimmedDescription,
        createdAt: DateTime.now(),
      );
    } else {
      _project = _project!.copyWith(
        title: trimmedTitle,
        imageUrl: imageUrl ?? _project!.imageUrl,
        conceptDescription: trimmedDescription,
      );
    }

    notifyListeners();
    unawaited(_persistWorkspace());
  }

  Future<void> loadForUser(String userId) async {
    _userId = userId;
    try {
      final workspace = await _userDataService.loadProjectWorkspace(userId);
      _project = workspace.project;
      _folders
        ..clear()
        ..addAll(workspace.folders);
      _entryTypes
        ..clear()
        ..addAll(workspace.entryTypes);
    } catch (_) {
      _project = null;
      _folders.clear();
      _entryTypes.clear();
    }
    notifyListeners();
  }

  Future<void> _persistWorkspace() async {
    final userId = _userId;
    if (userId == null) return;

    try {
      await _userDataService.saveProjectWorkspace(
        userId,
        project: _project,
        folders: _folders,
        entryTypes: _entryTypes,
      );
    } catch (_) {
      // Keep local state even if the network write fails.
    }
  }

  void reset() {
    _userId = null;
    _project = null;
    _folders.clear();
    _entryTypes.clear();
    notifyListeners();
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
    unawaited(_persistWorkspace());
  }

  void deleteFolder(String id) {
    _folders.removeWhere((f) => f.id == id);
    notifyListeners();
    unawaited(_persistWorkspace());
  }

  void renameFolder(String id, String newName) {
    final index = _folders.indexWhere((f) => f.id == id);
    if (index != -1) {
      _folders[index].name = newName;
      notifyListeners();
      unawaited(_persistWorkspace());
    }
  }

  // Entry Management
  void addEntry(String folderId, FolderEntry entry) {
    final folderIndex = _folders.indexWhere((f) => f.id == folderId);
    if (folderIndex != -1) {
      _folders[folderIndex].entries.add(entry);
      notifyListeners();
      unawaited(_persistWorkspace());
    }
  }

  void deleteEntry(String folderId, String entryId) {
    final folderIndex = _folders.indexWhere((f) => f.id == folderId);
    if (folderIndex != -1) {
      _folders[folderIndex].entries.removeWhere((e) => e.id == entryId);
      notifyListeners();
      unawaited(_persistWorkspace());
    }
  }

  ProjectFolder? getFolderById(String id) {
    try {
      return _folders.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  EntryTypeDefinition? getEntryTypeById(String id) {
    try {
      return _entryTypes.firstWhere((entryType) => entryType.id == id);
    } catch (_) {
      return null;
    }
  }

  void addEntryType(String name, List<EntryTypeVariable> variables) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Entry type name cannot be empty.');
    }

    final alreadyExists = _entryTypes.any(
      (type) => type.name.toLowerCase() == trimmedName.toLowerCase(),
    );
    if (alreadyExists) {
      throw ArgumentError('Entry type "$trimmedName" already exists.');
    }

    final entryType = EntryTypeDefinition(
      id: _uuid.v4(),
      name: trimmedName,
      variables: variables,
      createdAt: DateTime.now(),
    );
    _entryTypes.add(entryType);
    _getOrCreateFolderForEntryType(entryType);
    notifyListeners();
    unawaited(_persistWorkspace());
  }

  void updateEntryType(
    String entryTypeId, {
    required String name,
    required List<EntryTypeVariable> variables,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Entry type name cannot be empty.');
    }

    final index = _entryTypes.indexWhere(
      (entryType) => entryType.id == entryTypeId,
    );
    if (index == -1) {
      throw ArgumentError('Entry type not found.');
    }

    final alreadyExists = _entryTypes.any(
      (entryType) =>
          entryType.id != entryTypeId &&
          entryType.name.toLowerCase() == trimmedName.toLowerCase(),
    );
    if (alreadyExists) {
      throw ArgumentError('Entry type "$trimmedName" already exists.');
    }

    final previous = _entryTypes[index];
    _entryTypes[index] = EntryTypeDefinition(
      id: previous.id,
      name: trimmedName,
      variables: variables,
      createdAt: previous.createdAt,
    );

    final previousNamesById = {
      for (final variable in previous.variables) variable.id: variable.name,
    };
    for (var folderIndex = 0; folderIndex < _folders.length; folderIndex++) {
      final folder = _folders[folderIndex];
      if (folder.entryTypeId != entryTypeId) continue;

      final migratedEntries = folder.entries.map((entry) {
        final migratedValues = <String, String>{};

        for (final variable in variables) {
          final oldName = previousNamesById[variable.id];
          final newName = variable.name;

          if (oldName != null && entry.variableValues.containsKey(oldName)) {
            migratedValues[newName] = entry.variableValues[oldName]!;
          } else if (entry.variableValues.containsKey(newName)) {
            migratedValues[newName] = entry.variableValues[newName]!;
          }
        }

        return FolderEntry(
          id: entry.id,
          name: entry.name,
          description: entry.description,
          sourceEngine: entry.sourceEngine,
          resourceType: trimmedName,
          detectedEntryTypeName: trimmedName,
          variableValues: migratedValues,
          rawContent: entry.rawContent,
          createdAt: entry.createdAt,
        );
      }).toList();

      _folders[folderIndex] = folder.copyWith(
        name: trimmedName,
        entries: migratedEntries,
      );
    }

    notifyListeners();
    unawaited(_persistWorkspace());
  }

  void deleteEntryType(String entryTypeId) {
    final index = _entryTypes.indexWhere(
      (entryType) => entryType.id == entryTypeId,
    );
    if (index == -1) return;

    _entryTypes.removeAt(index);

    for (var folderIndex = 0; folderIndex < _folders.length; folderIndex++) {
      final folder = _folders[folderIndex];
      if (folder.entryTypeId != entryTypeId) continue;

      final detachedEntries = folder.entries.map((entry) {
        return FolderEntry(
          id: entry.id,
          name: entry.name,
          description: entry.description,
          sourceEngine: entry.sourceEngine,
          resourceType: folder.name,
          detectedEntryTypeName: null,
          variableValues: Map<String, String>.from(entry.variableValues),
          rawContent: entry.rawContent,
          createdAt: entry.createdAt,
        );
      }).toList();

      _folders[folderIndex] = folder.copyWith(
        clearEntryTypeId: true,
        entries: detachedEntries,
      );
    }

    notifyListeners();
    unawaited(_persistWorkspace());
  }

  ProjectFolder resolveImportFolder({
    String? detectedEntryTypeName,
    String? resourceType,
  }) {
    final detected = _normalizeName(detectedEntryTypeName);
    if (detected != null) {
      EntryTypeDefinition? matchedType;
      for (final entryType in _entryTypes) {
        if (_normalizeName(entryType.name) == detected) {
          matchedType = entryType;
          break;
        }
      }
      if (matchedType != null) {
        return _getOrCreateFolderForEntryType(
          matchedType,
          notifyOnCreate: true,
        );
      }
    }

    final normalizedResourceType = _normalizeName(resourceType);
    if (normalizedResourceType != null) {
      for (final folder in _folders) {
        if (_normalizeName(folder.name) == normalizedResourceType) {
          return folder;
        }
      }
    }

    return _getOrCreateUncategorizedFolder();
  }

  EntryTypeDefinition? findEntryTypeByName(String name) {
    final normalizedName = _normalizeName(name);
    if (normalizedName == null) return null;
    try {
      return _entryTypes.firstWhere(
        (entryType) => _normalizeName(entryType.name) == normalizedName,
      );
    } catch (_) {
      return null;
    }
  }

  ProjectFolder _getOrCreateFolderForEntryType(
    EntryTypeDefinition entryType, {
    bool notifyOnCreate = false,
  }) {
    for (final folder in _folders) {
      if (folder.entryTypeId == entryType.id) {
        return folder;
      }
    }

    final newFolder = ProjectFolder(
      id: _uuid.v4(),
      name: entryType.name,
      entryTypeId: entryType.id,
      createdAt: DateTime.now(),
    );
    _folders.add(newFolder);
    if (notifyOnCreate) {
      notifyListeners();
      unawaited(_persistWorkspace());
    }
    return newFolder;
  }

  ProjectFolder _getOrCreateUncategorizedFolder() {
    final normalizedTarget = _normalizeName(_uncategorizedFolderName);
    for (final folder in _folders) {
      if (_normalizeName(folder.name) == normalizedTarget) {
        return folder;
      }
    }

    final newFolder = ProjectFolder(
      id: _uuid.v4(),
      name: _uncategorizedFolderName,
      createdAt: DateTime.now(),
    );
    _folders.add(newFolder);
    notifyListeners();
    unawaited(_persistWorkspace());
    return newFolder;
  }

  String? _normalizeName(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }
}
