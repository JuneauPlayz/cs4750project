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
}
