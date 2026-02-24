import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/entry_type.dart';
import '../providers/project_provider.dart';

class CreateEntryTypeScreen extends StatefulWidget {
  const CreateEntryTypeScreen({super.key});

  @override
  State<CreateEntryTypeScreen> createState() => _CreateEntryTypeScreenState();
}

class _CreateEntryTypeScreenState extends State<CreateEntryTypeScreen> {
  final _uuid = const Uuid();
  final _nameController = TextEditingController();
  final List<_EntryVariableDraft> _variableDrafts = [_EntryVariableDraft()];

  @override
  void dispose() {
    _nameController.dispose();
    for (final draft in _variableDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _addVariable() {
    setState(() {
      _variableDrafts.add(_EntryVariableDraft());
    });
  }

  void _removeVariable(int index) {
    if (_variableDrafts.length <= 1) return;
    setState(() {
      final removed = _variableDrafts.removeAt(index);
      removed.dispose();
    });
  }

  void _save() {
    final typeName = _nameController.text.trim();
    if (typeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry type name is required.')),
      );
      return;
    }

    final variables = <EntryTypeVariable>[];
    for (final draft in _variableDrafts) {
      final variableName = draft.nameController.text.trim();
      if (variableName.isEmpty) continue;
      variables.add(
        EntryTypeVariable(
          id: _uuid.v4(),
          name: variableName,
          kind: draft.kind,
          referenceEntryTypeId: draft.kind == EntryVariableKind.entryList
              ? draft.referenceEntryTypeId
              : null,
        ),
      );
    }

    try {
      context.read<ProjectProvider>().addEntryType(typeName, variables);
      Navigator.pop(context);
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final entryTypes = context.watch<ProjectProvider>().entryTypes;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Entry Type')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Entry Type Name',
                hintText: 'Skill, Enemy, Item...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Variables',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ..._variableDrafts.asMap().entries.map((entry) {
              final index = entry.key;
              final draft = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: draft.nameController,
                              decoration: InputDecoration(
                                labelText: 'Variable ${index + 1}',
                                hintText: 'Name, Max HP, Description...',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: _variableDrafts.length == 1
                                ? null
                                : () => _removeVariable(index),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<EntryVariableKind>(
                        initialValue: draft.kind,
                        decoration: const InputDecoration(
                          labelText: 'Variable Type',
                          border: OutlineInputBorder(),
                        ),
                        items: EntryVariableKind.values
                            .map(
                              (kind) => DropdownMenuItem(
                                value: kind,
                                child: Text(kind.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            draft.kind = value ?? EntryVariableKind.text;
                            if (draft.kind != EntryVariableKind.entryList) {
                              draft.referenceEntryTypeId = null;
                            }
                          });
                        },
                      ),
                      if (draft.kind == EntryVariableKind.entryList) ...[
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String?>(
                          initialValue: draft.referenceEntryTypeId,
                          decoration: const InputDecoration(
                            labelText: 'List Item Entry Type',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Any Entry Type'),
                            ),
                            ...entryTypes.map(
                              (entryType) => DropdownMenuItem<String?>(
                                value: entryType.id,
                                child: Text(entryType.name),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              draft.referenceEntryTypeId = value;
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addVariable,
                icon: const Icon(Icons.add),
                label: const Text('Add Variable'),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _save,
              child: const Text('Create Entry Type'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryVariableDraft {
  final TextEditingController nameController = TextEditingController();
  EntryVariableKind kind = EntryVariableKind.text;
  String? referenceEntryTypeId;

  void dispose() {
    nameController.dispose();
  }
}
