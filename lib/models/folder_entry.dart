class FolderEntry {
  final String id;
  final String name; // e.g. "Fire Bolt", "Basic Fire Keystone"
  final String description; // LLM-generated explanation
  final String sourceEngine; // "godot"
  final String resourceType; // "Skill", "Keystone", "Item", etc.
  final String? detectedEntryTypeName;
  final Map<String, String> variableValues;
  final String rawContent; // Original .tres text
  final DateTime createdAt;

  FolderEntry({
    required this.id,
    required this.name,
    required this.description,
    required this.sourceEngine,
    required this.resourceType,
    this.detectedEntryTypeName,
    Map<String, String>? variableValues,
    required this.rawContent,
    required this.createdAt,
  }) : variableValues = variableValues ?? const {};

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sourceEngine': sourceEngine,
      'resourceType': resourceType,
      'detectedEntryTypeName': detectedEntryTypeName,
      'variableValues': variableValues,
      'rawContent': rawContent,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FolderEntry.fromStorageMap(Map<String, dynamic> map) {
    return FolderEntry(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Untitled Entry',
      description: map['description'] as String? ?? '',
      sourceEngine: map['sourceEngine'] as String? ?? 'manual',
      resourceType: map['resourceType'] as String? ?? 'Entry',
      detectedEntryTypeName: map['detectedEntryTypeName'] as String?,
      variableValues:
          (map['variableValues'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value.toString()),
          ) ??
          const {},
      rawContent: map['rawContent'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
