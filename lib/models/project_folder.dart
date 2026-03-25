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

  Map<String, dynamic> toStorageMap() {
    return {
      'id': id,
      'name': name,
      'entryTypeId': entryTypeId,
      'entries': entries.map((entry) => entry.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ProjectFolder.fromStorageMap(Map<String, dynamic> map) {
    return ProjectFolder(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Folder',
      entryTypeId: map['entryTypeId'] as String?,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      entries:
          (map['entries'] as List<dynamic>?)
              ?.map(
                (entry) => FolderEntry.fromStorageMap(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList() ??
          const [],
    );
  }

  ProjectFolder copyWith({
    String? name,
    String? entryTypeId,
    bool clearEntryTypeId = false,
    List<FolderEntry>? entries,
  }) {
    return ProjectFolder(
      id: id,
      name: name ?? this.name,
      entryTypeId: clearEntryTypeId ? null : (entryTypeId ?? this.entryTypeId),
      createdAt: createdAt,
      entries: entries ?? List<FolderEntry>.from(this.entries),
    );
  }
}
