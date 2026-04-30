import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/folder_entry.dart';
import '../providers/project_provider.dart';
import 'create_folder_entry_screen.dart';

class FolderDetailScreen extends StatefulWidget {
  const FolderDetailScreen({super.key, required this.folderId});

  final String folderId;

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        final folder = provider.getFolderById(widget.folderId);

        if (folder == null) {
          return const Scaffold(body: Center(child: Text('Folder not found')));
        }

        final entryType = folder.entryTypeId == null
            ? null
            : provider.getEntryTypeById(folder.entryTypeId!);
        final filteredEntries = folder.entries.where((entry) {
          if (_query.trim().isEmpty) return true;
          final q = _query.toLowerCase();
          return entry.name.toLowerCase().contains(q) ||
              entry.description.toLowerCase().contains(q) ||
              entry.variableValues.entries.any(
                (variable) =>
                    variable.key.toLowerCase().contains(q) ||
                    variable.value.toLowerCase().contains(q),
              );
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(folder.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: entryType == null
                    ? 'Add Object'
                    : 'Add ${entryType.name}',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CreateFolderEntryScreen(folderId: folder.id),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search folder objects',
                  ),
                ),
              ),
              Expanded(
                child: filteredEntries.isEmpty
                    ? _buildEmptyState(
                        context,
                        hasQuery: _query.trim().isNotEmpty,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredEntries.length,
                        itemBuilder: (context, index) {
                          final entry = filteredEntries[index];
                          return _EntryCard(
                            entry: entry,
                            onEdit: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateFolderEntryScreen(
                                  folderId: folder.id,
                                  entryId: entry.id,
                                ),
                              ),
                            ),
                            onDelete: () =>
                                provider.deleteEntry(folder.id, entry.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool hasQuery}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasQuery ? Icons.search_off : Icons.folder_open,
            size: 64,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            hasQuery
                ? 'No objects match your search'
                : 'No entries in this folder yet',
          ),
          const SizedBox(height: 8),
          Text(
            hasQuery
                ? 'Try a different search term.'
                : 'Add objects manually here or use the import button in the Hub.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final FolderEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    (entry.detectedEntryTypeName ?? entry.resourceType)
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              entry.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (entry.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                entry.description,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
            if (entry.variableValues.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Variables',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              ...entry.variableValues.entries.map(
                (variable) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${variable.key}: ${variable.value}',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
