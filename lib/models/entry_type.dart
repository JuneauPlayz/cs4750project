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
