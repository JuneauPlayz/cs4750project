import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/folder_entry.dart';
import '../providers/project_provider.dart';
import 'create_folder_entry_screen.dart';

class FolderDetailScreen extends StatelessWidget {
  final String folderId;

  const FolderDetailScreen({super.key, required this.folderId});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (context, provider, child) {
        final folder = provider.getFolderById(folderId);

        if (folder == null) {
          return const Scaffold(body: Center(child: Text('Folder not found')));
        }

        final entryType = folder.entryTypeId == null
            ? null
            : provider.getEntryTypeById(folder.entryTypeId!);

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
          body: folder.entries.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: folder.entries.length,
                  itemBuilder: (context, index) {
                    final entry = folder.entries[index];
                    return _EntryCard(
                      entry: entry,
                      onDelete: () => provider.deleteEntry(folderId, entry.id),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          const Text('No entries in this folder yet'),
          const SizedBox(height: 8),
          const Text(
            'Add objects manually here or use the import button in the Hub.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final FolderEntry entry;
  final VoidCallback onDelete;

  const _EntryCard({required this.entry, required this.onDelete});

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
            const SizedBox(height: 8),
            Text(
              entry.description,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
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
