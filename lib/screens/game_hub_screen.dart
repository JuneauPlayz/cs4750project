import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../providers/notes_provider.dart';
import '../models/content_entry.dart';
import '../widgets/content_card.dart';
import '../widgets/note_card.dart';
import 'content_editor_screen.dart';
import 'mechanic_editor_screen.dart';

class GameHubScreen extends StatelessWidget {
  const GameHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Hub'),
      ),
      body: Consumer2<ProjectProvider, NotesProvider>(
        builder: (context, projectProvider, notesProvider, child) {
          final project = projectProvider.project;

          return CustomScrollView(
            slivers: [
              // Project Header
              SliverToBoxAdapter(
                child: _ProjectHeader(project: project),
              ),

              // Recent Notes Section
              SliverToBoxAdapter(
                child: _HubSectionHeader(
                  title: 'Recent Notes',
                  onAdd: null, // Notes are added in Tab 1
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 160,
                  child: notesProvider.recentNotes.isEmpty
                      ? _EmptySection(message: 'No notes yet')
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: notesProvider.recentNotes.length,
                          itemBuilder: (context, index) {
                            final note = notesProvider.recentNotes[index];
                            return SizedBox(
                              width: 250,
                              child: NoteCard(
                                note: note,
                                onTap: () {}, // Future: Open note
                              ),
                            );
                          },
                        ),
                ),
              ),

              // Content Categories
              ...ContentType.values.map((type) => _SliverContentCategory(
                    type: type,
                    items: projectProvider.getContentByType(type),
                  )),

              // Mechanics Section
              SliverToBoxAdapter(
                child: _HubSectionHeader(
                  title: 'Mechanics',
                  onAdd: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MechanicEditorScreen()),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final mechanic = projectProvider.mechanics[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(mechanic.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            mechanic.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: mechanic.sourceGameTitle != null
                              ? Chip(
                                  label: Text(mechanic.sourceGameTitle!, style: const TextStyle(fontSize: 10)),
                                  visualDensity: VisualDensity.compact,
                                )
                              : null,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => MechanicEditorScreen(mechanic: mechanic)),
                          ),
                        ),
                      );
                    },
                    childCount: projectProvider.mechanics.length,
                  ),
                ),
              ),
              if (projectProvider.mechanics.isEmpty)
                const SliverToBoxAdapter(child: _EmptySection(message: 'No mechanics recorded')),

              const SliverToBoxAdapter(child: SizedBox(height: 50)),
            ],
          );
        },
      ),
    );
  }
}

class _ProjectHeader extends StatelessWidget {
  final dynamic project;

  const _ProjectHeader({this.project});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primaryContainer, colorScheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  project?.title ?? 'Untitled Project',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => _showProjectEditor(context),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            project?.description ?? 'Tap the edit icon to set up your project pitch.',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  void _showProjectEditor(BuildContext context) {
    final titleController = TextEditingController(text: project?.title);
    final descController = TextEditingController(text: project?.description);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
            const Text('Edit Project Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Working Title')),
            const SizedBox(height: 12),
            TextField(controller: descController, maxLines: 3, decoration: const InputDecoration(labelText: 'Elevator Pitch')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.read<ProjectProvider>().setupProject(
                  titleController.text,
                  description: descController.text,
                );
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _HubSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onAdd;

  const _HubSectionHeader({required this.title, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (onAdd != null)
            IconButton(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_outline),
              color: Theme.of(context).colorScheme.primary,
            ),
        ],
      ),
    );
  }
}

class _SliverContentCategory extends StatelessWidget {
  final ContentType type;
  final List<ContentEntry> items;

  const _SliverContentCategory({required this.type, required this.items});

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: _HubSectionHeader(
            title: '${type.name.characters.first.toUpperCase()}${type.name.substring(1)}s',
            onAdd: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ContentEditorScreen(initialType: type)),
            ),
          ),
        ),
        if (items.isEmpty)
          const SliverToBoxAdapter(child: _EmptySection(message: 'None added yet'))
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.5,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => ContentCard(
                  entry: items[index],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ContentEditorScreen(entry: items[index])),
                  ),
                ),
                childCount: items.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String message;
  const _EmptySection({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.outlineVariant)),
      ),
    );
  }
}
