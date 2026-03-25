import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/entry_type.dart';
import '../models/folder_entry.dart';
import '../providers/project_provider.dart';

class CreateFolderEntryScreen extends StatefulWidget {
  const CreateFolderEntryScreen({super.key, required this.folderId});

  final String folderId;

  @override
  State<CreateFolderEntryScreen> createState() =>
      _CreateFolderEntryScreenState();
}

class _CreateFolderEntryScreenState extends State<CreateFolderEntryScreen> {
  final _uuid = const Uuid();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Map<String, TextEditingController> _variableControllers = {};

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (final controller in _variableControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerForVariable(String variableId) {
    return _variableControllers.putIfAbsent(
      variableId,
      TextEditingController.new,
    );
  }

  void _save() {
    final provider = context.read<ProjectProvider>();
    final folder = provider.getFolderById(widget.folderId);
    if (folder == null) return;

    final entryType = folder.entryTypeId == null
        ? null
        : provider.getEntryTypeById(folder.entryTypeId!);
    final entryName = _nameController.text.trim();
    if (entryName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Object name is required.')));
      return;
    }

    final variableValues = <String, String>{};
    if (entryType != null) {
      for (final variable in entryType.variables) {
        final value = _controllerForVariable(variable.id).text.trim();
        if (value.isNotEmpty) {
          variableValues[variable.name] = value;
        }
      }
    }

    final entry = FolderEntry(
      id: _uuid.v4(),
      name: entryName,
      description: _descriptionController.text.trim(),
      sourceEngine: 'manual',
      resourceType: entryType?.name ?? folder.name,
      detectedEntryTypeName: entryType?.name,
      variableValues: variableValues,
      rawContent: '',
      createdAt: DateTime.now(),
    );

    provider.addEntry(folder.id, entry);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final folder = provider.getFolderById(widget.folderId);

    if (folder == null) {
      return const Scaffold(body: Center(child: Text('Folder not found')));
    }

    final entryType = folder.entryTypeId == null
        ? null
        : provider.getEntryTypeById(folder.entryTypeId!);

    return Scaffold(
      appBar: AppBar(
        title: Text(entryType == null ? 'Add Object' : 'Add ${entryType.name}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Object Name',
              hintText: 'Enter a name',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'What is this object and what does it do?',
              alignLabelWithHint: true,
            ),
          ),
          if (entryType != null) ...[
            const SizedBox(height: 24),
            Text(
              '${entryType.name} Fields',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            for (final variable in entryType.variables) ...[
              TextField(
                controller: _controllerForVariable(variable.id),
                minLines: variable.kind == EntryVariableKind.longText ? 3 : 1,
                maxLines: variable.kind == EntryVariableKind.longText ? 5 : 1,
                keyboardType: variable.kind == EntryVariableKind.number
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
                decoration: InputDecoration(
                  labelText: variable.name,
                  hintText: _hintForVariable(variable),
                  alignLabelWithHint:
                      variable.kind == EntryVariableKind.longText,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Object'),
          ),
        ],
      ),
    );
  }

  String _hintForVariable(EntryTypeVariable variable) {
    switch (variable.kind) {
      case EntryVariableKind.number:
        return 'Enter a numeric value';
      case EntryVariableKind.longText:
        return 'Enter a longer description';
      case EntryVariableKind.entryList:
        return 'List related entries or references';
      case EntryVariableKind.text:
        return 'Enter a value';
    }
  }
}
