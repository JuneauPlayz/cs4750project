import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../models/content_entry.dart';

class ContentEditorScreen extends StatefulWidget {
  final ContentEntry? entry;
  final ContentType? initialType;

  const ContentEditorScreen({super.key, this.entry, this.initialType});

  @override
  State<ContentEditorScreen> createState() => _ContentEditorScreenState();
}

class _ContentEditorScreenState extends State<ContentEditorScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late ContentType _type;
  final Map<String, TextEditingController> _attributeControllers = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.entry?.name);
    _descController = TextEditingController(text: widget.entry?.description);
    _type = widget.entry?.type ?? widget.initialType ?? ContentType.character;
    
    widget.entry?.attributes.forEach((key, value) {
      _attributeControllers[key] = TextEditingController(text: value);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    for (var controller in _attributeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) return;

    final attributes = _attributeControllers.map((key, controller) => MapEntry(key, controller.text));
    
    final provider = context.read<ProjectProvider>();
    if (widget.entry == null) {
      provider.addContent(
        _nameController.text,
        _type,
        description: _descController.text,
        attributes: attributes,
      );
    } else {
      // Future: Implement updateContent in provider
      provider.deleteContent(widget.entry!.id);
      provider.addContent(
        _nameController.text,
        _type,
        description: _descController.text,
        attributes: attributes,
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? 'Add Content' : 'Edit Content'),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.check)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<ContentType>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Type'),
            items: ContentType.values.map((t) => DropdownMenuItem(
              value: t,
              child: Text(t.name.toUpperCase()),
            )).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _type = val);
            },
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. Hero Name, Sword, Fireball',
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attributes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _attributeControllers['New Attribute ${_attributeControllers.length + 1}'] = TextEditingController();
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const Divider(),
          ..._attributeControllers.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(entry.key, style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: entry.value,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => setState(() => _attributeControllers.remove(entry.key)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
