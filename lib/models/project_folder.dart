import 'folder_entry.dart';

class ProjectFolder {
  final String id;
  String name;
  final String? entryTypeId;
  final List<FolderEntry> entries;
  final DateTime createdAt;

  ProjectFolder({
    required this.id,
    required this.name,
    required this.createdAt,
    this.entryTypeId,
    List<FolderEntry>? entries,
  }) : entries = entries ?? [];
}
