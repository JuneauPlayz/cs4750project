import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../models/mechanic.dart';

class MechanicEditorScreen extends StatefulWidget {
  final Mechanic? mechanic;

  const MechanicEditorScreen({super.key, this.mechanic});

  @override
  State<MechanicEditorScreen> createState() => _MechanicEditorScreenState();
}

class _MechanicEditorScreenState extends State<MechanicEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _sourceController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.mechanic?.title);
    _descController = TextEditingController(text: widget.mechanic?.description);
    _sourceController = TextEditingController(text: widget.mechanic?.sourceGameTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) return;

    final provider = context.read<ProjectProvider>();
    if (widget.mechanic == null) {
      provider.addMechanic(
        _titleController.text,
        description: _descController.text,
        sourceGame: _sourceController.text.isEmpty ? null : _sourceController.text,
      );
    } else {
      // Future: Implement updateMechanic in provider
      provider.deleteMechanic(widget.mechanic!.id);
      provider.addMechanic(
        _titleController.text,
        description: _descController.text,
        sourceGame: _sourceController.text.isEmpty ? null : _sourceController.text,
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mechanic == null ? 'New Mechanic' : 'Edit Mechanic'),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.check)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'e.g. Parry System, Crafting Flow',
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _sourceController,
            decoration: const InputDecoration(
              labelText: 'Inspiration (optional)',
              hintText: 'e.g. Inspired by Elden Ring',
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _descController,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Description',
              alignLabelWithHint: true,
              hintText: 'Describe how this mechanic works, the user flow, and why it\'s fun.',
            ),
          ),
        ],
      ),
    );
  }
}
