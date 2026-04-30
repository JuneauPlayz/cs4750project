import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../widgets/account_menu_button.dart';
import '../widgets/note_card.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _query = '';
  String? _selectedTag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Design Notes'),
        actions: const [AccountMenuButton()],
      ),
      body: Consumer<NotesProvider>(
        builder: (context, provider, child) {
          final filteredNotes = provider.notes.where((note) {
            final matchesQuery =
                _query.trim().isEmpty ||
                note.title.toLowerCase().contains(_query.toLowerCase()) ||
                note.body.toLowerCase().contains(_query.toLowerCase());
            final matchesTag = _selectedTag == null || note.tag == _selectedTag;
            return matchesQuery && matchesTag;
          }).toList();

          final pinnedNotes = filteredNotes
              .where((note) => note.isPinned)
              .toList();
          final recentNotes = filteredNotes
              .where((note) => !note.isPinned)
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search notes',
                  ),
                ),
              ),
              if (provider.availableTags.isNotEmpty)
                SizedBox(
                  height: 46,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: const Text('All'),
                          selected: _selectedTag == null,
                          onSelected: (_) =>
                              setState(() => _selectedTag = null),
                        ),
                      ),
                      ...provider.availableTags.map(
                        (tag) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(tag),
                            selected: _selectedTag == tag,
                            onSelected: (_) =>
                                setState(() => _selectedTag = tag),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: filteredNotes.isEmpty
                    ? _EmptyNotesState(
                        hasFilters: _query.isNotEmpty || _selectedTag != null,
                      )
                    : ListView(
                        padding: const EdgeInsets.only(top: 8, bottom: 88),
                        children: [
                          if (pinnedNotes.isNotEmpty) ...[
                            _SectionLabel(title: 'Pinned'),
                            ...pinnedNotes.map(
                              (note) => NoteCard(
                                note: note,
                                onTap: () =>
                                    _showNoteEditor(context, note: note),
                                onDelete: () => provider.deleteNote(note.id),
                                onTogglePin: () => provider.togglePin(note.id),
                              ),
                            ),
                          ],
                          if (recentNotes.isNotEmpty) ...[
                            _SectionLabel(
                              title: pinnedNotes.isEmpty
                                  ? 'All Notes'
                                  : 'Recent',
                            ),
                            ...recentNotes.map(
                              (note) => NoteCard(
                                note: note,
                                onTap: () =>
                                    _showNoteEditor(context, note: note),
                                onDelete: () => provider.deleteNote(note.id),
                                onTogglePin: () => provider.togglePin(note.id),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ],
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
    var isPinned = note?.isPinned ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                decoration: const InputDecoration(hintText: 'Title (optional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                maxLines: 5,
                autofocus: note == null,
                decoration: const InputDecoration(
                  hintText: 'What\'s on your mind?',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedTag,
                decoration: const InputDecoration(
                  hintText: 'Select Tag (optional)',
                ),
                items: ['Mechanic', 'Story', 'Level', 'General']
                    .map(
                      (tag) => DropdownMenuItem(value: tag, child: Text(tag)),
                    )
                    .toList(),
                onChanged: (value) => selectedTag = value,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Pin this note'),
                value: isPinned,
                onChanged: (value) => setModalState(() => isPinned = value),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  if (bodyController.text.trim().isEmpty) return;

                  final provider = context.read<NotesProvider>();
                  if (note == null) {
                    provider.addNote(
                      bodyController.text,
                      title: titleController.text,
                      tag: selectedTag,
                      isPinned: isPinned,
                    );
                  } else {
                    provider.updateNote(
                      note.id,
                      title: titleController.text,
                      body: bodyController.text,
                      tag: selectedTag,
                      isPinned: isPinned,
                    );
                  }
                  Navigator.pop(context);
                },
                child: const Text('Save Note'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptyNotesState extends StatelessWidget {
  const _EmptyNotesState({required this.hasFilters});

  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.edit_note,
              size: 72,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters
                  ? 'No notes match your current search.'
                  : 'No notes yet — tap + to capture your first idea!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
