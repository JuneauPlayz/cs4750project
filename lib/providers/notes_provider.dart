import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';

class NotesProvider extends ChangeNotifier {
  final List<Note> _notes = [];
  final _uuid = const Uuid();

  List<Note> get notes => List.unmodifiable(_notes..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)));
  
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
    }
  }

  void deleteNote(String id) {
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  List<Note> searchNotes(String query) {
    if (query.isEmpty) return notes;
    final lowerQuery = query.toLowerCase();
    return _notes.where((n) => 
      n.title.toLowerCase().contains(lowerQuery) || 
      n.body.toLowerCase().contains(lowerQuery)
    ).toList();
  }
}
