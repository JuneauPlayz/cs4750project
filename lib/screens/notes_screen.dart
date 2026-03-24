import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notes_provider.dart';
import '../models/note.dart';
import '../widgets/account_menu_button.dart';
import '../widgets/note_card.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Design Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Future: Implement search
            },
          ),
          const AccountMenuButton(),
        ],
      ),
      body: Consumer<NotesProvider>(
        builder: (context, provider, child) {
          final notes = provider.notes;

          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.edit_note,
                    size: 80,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notes yet — tap + to capture your first idea!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return NoteCard(
                note: note,
                onTap: () => _showNoteEditor(context, note: note),
                onDelete: () => provider.deleteNote(note.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNoteEditor(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showNoteEditor(BuildContext context, {Note? note}) {
    final titleController = TextEditingController(text: note?.title);
    final bodyController = TextEditingController(text: note?.body);
    String? selectedTag = note?.tag;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              note == null ? 'New Idea' : 'Edit Note',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: 'Title (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyController,
              maxLines: 5,
              autofocus: note == null,
              decoration: const InputDecoration(
                hintText: 'What\'s on your mind?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedTag,
              decoration: const InputDecoration(
                hintText: 'Select Tag (optional)',
                border: OutlineInputBorder(),
              ),
              items: [
                'Mechanic',
                'Story',
                'Level',
                'General',
              ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) => selectedTag = val,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (bodyController.text.trim().isEmpty) return;

                final provider = context.read<NotesProvider>();
                if (note == null) {
                  provider.addNote(
                    bodyController.text,
                    title: titleController.text,
                    tag: selectedTag,
                  );
                } else {
                  provider.updateNote(
                    note.id,
                    title: titleController.text,
                    body: bodyController.text,
                    tag: selectedTag,
                  );
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Save Note'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
