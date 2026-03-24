import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/game.dart';
import '../models/game_project.dart';
import '../models/note.dart';

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

  Future<GameProject?> loadProject(String userId) async {
    final snapshot = await _projectDoc(userId).get();
    if (!snapshot.exists) return null;

    final data = snapshot.data();
    if (data == null) return null;
    return GameProject.fromStorageMap(data);
  }

  Future<void> saveProject(String userId, GameProject project) async {
    await _projectDoc(userId).set({
      ...project.toStorageMap(),
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
