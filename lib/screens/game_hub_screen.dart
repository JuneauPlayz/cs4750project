import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/entry_type.dart';
import '../providers/project_provider.dart';
import '../providers/notes_provider.dart';
import 'resource_import_screen.dart';
import 'folder_detail_screen.dart';
import 'create_entry_type_screen.dart';

class GameHubScreen extends StatefulWidget {
  const GameHubScreen({super.key});

  @override
  State<GameHubScreen> createState() => _GameHubScreenState();
}

class _GameHubScreenState extends State<GameHubScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isEditingTitle = false;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      context.read<ProjectProvider>().updateImageUrl(image.path);
    }
  }

  void _showNewFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter folder name'),
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              context.read<ProjectProvider>().addFolder(val.trim());
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<ProjectProvider>().addFolder(
                  controller.text.trim(),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ResourceImportScreen()),
            ),
            tooltip: 'Import Godot Resource',
          ),
        ],
      ),
      body: Consumer2<ProjectProvider, NotesProvider>(
        builder: (context, projectProvider, notesProvider, child) {
          final project = projectProvider.project;

          // Initialize project if null
          if (project == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              projectProvider.setupProject('New Game Project');
            });
            return const Center(child: CircularProgressIndicator());
          }

          if (!_isEditingTitle && _titleController.text != project.title) {
            _titleController.text = project.title;
          }

          return CustomScrollView(
            slivers: [
              // 1. Editable Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: _isEditingTitle
                      ? TextField(
                          controller: _titleController,
                          autofocus: true,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          onSubmitted: (val) {
                            projectProvider.updateTitle(
                              val.isNotEmpty ? val : 'Untitled Project',
                            );
                            setState(() => _isEditingTitle = false);
                          },
                          onTapOutside: (_) {
                            projectProvider.updateTitle(
                              _titleController.text.isNotEmpty
                                  ? _titleController.text
                                  : 'Untitled Project',
                            );
                            setState(() => _isEditingTitle = false);
                          },
                        )
                      : GestureDetector(
                          onTap: () => setState(() => _isEditingTitle = true),
                          child: Text(
                            project.title,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                          ),
                        ),
                ),
              ),

              // 2. Optional Game Image
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        image: project.imageUrl != null
                            ? DecorationImage(
                                image: FileImage(File(project.imageUrl!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: project.imageUrl == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 40,
                                  color: colorScheme.outline,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add Game Concept Art',
                                  style: TextStyle(color: colorScheme.outline),
                                ),
                              ],
                            )
                          : Stack(
                              children: [
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // 3. Entry Types Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(
                    'Entry Types',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (projectProvider.entryTypes.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Text(
                      'No entry types yet. Create one to power AI auto-sorting.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final entryType = projectProvider.entryTypes[index];
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(top: 8),
                        color: colorScheme.surfaceContainerLow,
                        child: ListTile(
                          leading: Icon(
                            Icons.category_outlined,
                            color: colorScheme.primary,
                          ),
                          title: Text(entryType.name),
                          subtitle: entryType.variables.isEmpty
                              ? const Text('No variables')
                              : Text(
                                  entryType.variables
                                      .map((variable) => variable.name)
                                      .join(', '),
                                ),
                        ),
                      );
                    }, childCount: projectProvider.entryTypes.length),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateEntryTypeScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.add_chart_outlined),
                    label: const Text('Add Entry Type'),
                  ),
                ),
              ),

              // 4. Folders Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(
                    'Folders',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // 4a. Built-in "Notes" Folder
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerLow,
                    child: ListTile(
                      leading: Icon(Icons.folder, color: colorScheme.primary),
                      title: const Text(
                        'Notes',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Badge(
                        label: Text(notesProvider.notes.length.toString()),
                        backgroundColor: colorScheme.primary,
                      ),
                      onTap: () {
                        // For now, prompt they are managed in the Notes tab
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Quick capture notes are managed in the first tab',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // 4b. User folders list
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final folder = projectProvider.folders[index];
                    EntryTypeDefinition? linkedEntryType;
                    if (folder.entryTypeId != null) {
                      for (final entryType in projectProvider.entryTypes) {
                        if (entryType.id == folder.entryTypeId) {
                          linkedEntryType = entryType;
                          break;
                        }
                      }
                    }
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(top: 8),
                      color: colorScheme.surfaceContainerLow,
                      child: ListTile(
                        leading: Icon(
                          Icons.folder_open,
                          color: colorScheme.secondary,
                        ),
                        title: Text(folder.name),
                        subtitle: linkedEntryType == null
                            ? null
                            : const Text('Managed by Entry Type'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (folder.entries.isNotEmpty)
                              Badge(
                                label: Text(folder.entries.length.toString()),
                                backgroundColor: colorScheme.secondary,
                              ),
                            if (linkedEntryType == null)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    projectProvider.deleteFolder(folder.id),
                              )
                            else
                              Icon(
                                Icons.link,
                                size: 18,
                                color: colorScheme.outline,
                              ),
                          ],
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                FolderDetailScreen(folderId: folder.id),
                          ),
                        ),
                      ),
                    );
                  }, childCount: projectProvider.folders.length),
                ),
              ),

              // 5. "+ New Folder" Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: OutlinedButton.icon(
                    onPressed: _showNewFolderDialog,
                    icon: const Icon(Icons.create_new_folder_outlined),
                    label: const Text('Add Folder'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
    );
  }
}
