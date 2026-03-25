class EntryTypeDefinition {
  final String id;
  final String name;
  final List<EntryTypeVariable> variables;
  final DateTime createdAt;

  EntryTypeDefinition({
    required this.id,
    required this.name,
    required this.variables,
    required this.createdAt,
  });

  Map<String, dynamic> toStorageMap() {
    return {
      'id': id,
      'name': name,
      'variables': variables
          .map((variable) => variable.toStorageMap())
          .toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EntryTypeDefinition.fromStorageMap(Map<String, dynamic> map) {
    return EntryTypeDefinition(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Entry Type',
      variables:
          (map['variables'] as List<dynamic>?)
              ?.map(
                (variable) => EntryTypeVariable.fromStorageMap(
                  Map<String, dynamic>.from(variable as Map),
                ),
              )
              .toList() ??
          const [],
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class EntryTypeVariable {
  final String id;
  final String name;
  final EntryVariableKind kind;
  final String? referenceEntryTypeId;

  EntryTypeVariable({
    required this.id,
    required this.name,
    required this.kind,
    this.referenceEntryTypeId,
  });

  Map<String, dynamic> toStorageMap() {
    return {
      'id': id,
      'name': name,
      'kind': kind.name,
      'referenceEntryTypeId': referenceEntryTypeId,
    };
  }

  factory EntryTypeVariable.fromStorageMap(Map<String, dynamic> map) {
    return EntryTypeVariable(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Variable',
      kind: EntryVariableKind.values.firstWhere(
        (kind) => kind.name == map['kind'],
        orElse: () => EntryVariableKind.text,
      ),
      referenceEntryTypeId: map['referenceEntryTypeId'] as String?,
    );
  }
}

enum EntryVariableKind { text, number, longText, entryList }

extension EntryVariableKindLabel on EntryVariableKind {
  String get label {
    switch (this) {
      case EntryVariableKind.text:
        return 'Text';
      case EntryVariableKind.number:
        return 'Number';
      case EntryVariableKind.longText:
        return 'Long Text';
      case EntryVariableKind.entryList:
        return 'Entry List';
    }
  }
}
