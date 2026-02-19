import 'folder_entry.dart';

class ProjectFolder {
  final String id;
  String name;
  final List<FolderEntry> entries;
  final DateTime createdAt;

  ProjectFolder({
    required this.id,
    required this.name,
    required this.createdAt,
    List<FolderEntry>? entries,
  }) : entries = entries ?? [];
}
