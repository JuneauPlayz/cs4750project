import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../services/firestore_user_data_service.dart';

class NotesProvider extends ChangeNotifier {
  NotesProvider({FirestoreUserDataService? userDataService})
    : _userDataService = userDataService ?? FirestoreUserDataService();

  final FirestoreUserDataService _userDataService;
  final List<Note> _notes = [];
  final _uuid = const Uuid();
  String? _userId;

  List<Note> get notes => List.unmodifiable(
    _notes..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
  );

  List<Note> get recentNotes => notes.take(5).toList();

  void addNote(String body, {String? title, String? tag}) {
    final now = DateTime.now();
    final newNote = Note(
      id: _uuid.v4(),
      title: title ?? '',
      body: body,
      createdAt: now,
      updatedAt: now,
      tag: tag,
    );
    _notes.add(newNote);
    notifyListeners();
    unawaited(_persistNote(newNote));
  }

  void updateNote(String id, {String? title, String? body, String? tag}) {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index >= 0) {
      _notes[index] = _notes[index].copyWith(
        title: title,
        body: body,
        tag: tag,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
      unawaited(_persistNote(_notes[index]));
    }
  }

  void deleteNote(String id) {
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
    unawaited(_deletePersistedNote(id));
  }

  List<Note> searchNotes(String query) {
    if (query.isEmpty) return notes;
    final lowerQuery = query.toLowerCase();
    return _notes
        .where(
          (n) =>
              n.title.toLowerCase().contains(lowerQuery) ||
              n.body.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  Future<void> loadForUser(String userId) async {
    _userId = userId;
    try {
      _notes
        ..clear()
        ..addAll(await _userDataService.loadNotes(userId));
    } catch (_) {
      _notes.clear();
    }
    notifyListeners();
  }

  Future<void> _persistNote(Note note) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      await _userDataService.saveNote(userId, note);
    } catch (_) {
      // Keep local notes even if the network write fails.
    }
  }

  Future<void> _deletePersistedNote(String noteId) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      await _userDataService.deleteNote(userId, noteId);
    } catch (_) {
      // Ignore remote delete failures for now.
    }
  }

  void reset() {
    _userId = null;
    _notes.clear();
    notifyListeners();
  }
}
