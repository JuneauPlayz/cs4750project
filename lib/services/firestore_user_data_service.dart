import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/game.dart';
import '../models/game_project.dart';
import '../models/entry_type.dart';
import '../models/note.dart';
import '../models/project_folder.dart';

class StoredProjectWorkspace {
  const StoredProjectWorkspace({
    this.project,
    this.folders = const [],
    this.entryTypes = const [],
  });

  final GameProject? project;
  final List<ProjectFolder> folders;
  final List<EntryTypeDefinition> entryTypes;
}

class FirestoreUserDataService {
  FirestoreUserDataService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _projectDoc(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('profile')
        .doc('game_project');
  }

  CollectionReference<Map<String, dynamic>> _notesRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('notes');
  }

  CollectionReference<Map<String, dynamic>> _similarGamesRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('similar_games');
  }

  Future<StoredProjectWorkspace> loadProjectWorkspace(String userId) async {
    final snapshot = await _projectDoc(userId).get();
    if (!snapshot.exists) {
      return const StoredProjectWorkspace();
    }

    final data = snapshot.data();
    if (data == null) {
      return const StoredProjectWorkspace();
    }

    if (data.containsKey('project')) {
      final projectData = data['project'];
      final foldersData = data['folders'] as List<dynamic>? ?? const [];
      final entryTypesData = data['entryTypes'] as List<dynamic>? ?? const [];

      return StoredProjectWorkspace(
        project: projectData is Map<String, dynamic>
            ? GameProject.fromStorageMap(projectData)
            : projectData is Map
            ? GameProject.fromStorageMap(Map<String, dynamic>.from(projectData))
            : null,
        folders: foldersData
            .map(
              (folder) => ProjectFolder.fromStorageMap(
                Map<String, dynamic>.from(folder as Map),
              ),
            )
            .toList(),
        entryTypes: entryTypesData
            .map(
              (entryType) => EntryTypeDefinition.fromStorageMap(
                Map<String, dynamic>.from(entryType as Map),
              ),
            )
            .toList(),
      );
    }

    return StoredProjectWorkspace(project: GameProject.fromStorageMap(data));
  }

  Future<void> saveProjectWorkspace(
    String userId, {
    required GameProject? project,
    required List<ProjectFolder> folders,
    required List<EntryTypeDefinition> entryTypes,
  }) async {
    await _projectDoc(userId).set({
      'project': project?.toStorageMap(),
      'folders': folders.map((folder) => folder.toStorageMap()).toList(),
      'entryTypes': entryTypes
          .map((entryType) => entryType.toStorageMap())
          .toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<Note>> loadNotes(String userId) async {
    final snapshot = await _notesRef(userId).get();
    return snapshot.docs
        .map((doc) => Note.fromStorageMap(doc.id, doc.data()))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> saveNote(String userId, Note note) async {
    await _notesRef(
      userId,
    ).doc(note.id).set(note.toStorageMap(), SetOptions(merge: true));
  }

  Future<void> deleteNote(String userId, String noteId) {
    return _notesRef(userId).doc(noteId).delete();
  }

  Future<List<Game>> loadSimilarGames(String userId) async {
    final snapshot = await _similarGamesRef(userId).get();
    return snapshot.docs
        .map((doc) => Game.fromStorageMap(doc.data()))
        .where((game) => game.id != 0)
        .toList();
  }

  Future<void> saveSimilarGame(String userId, Game game) async {
    await _similarGamesRef(
      userId,
    ).doc(game.id.toString()).set(game.toStorageMap(), SetOptions(merge: true));
  }

  Future<void> deleteSimilarGame(String userId, int gameId) {
    return _similarGamesRef(userId).doc(gameId.toString()).delete();
  }
}
