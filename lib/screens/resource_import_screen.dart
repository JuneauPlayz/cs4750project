import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../models/folder_entry.dart';
import '../providers/project_provider.dart';
import '../services/tres_parser.dart';
import '../services/ai_service.dart';

class ResourceImportScreen extends StatefulWidget {
  const ResourceImportScreen({super.key});

  @override
  State<ResourceImportScreen> createState() => _ResourceImportScreenState();
}

class _ResourceImportScreenState extends State<ResourceImportScreen> {
  final _aiService = AiService();
  final _pasteController = TextEditingController();
  File? _selectedFile;
  String? _rawContent;
  FolderEntry? _analysisResult;
  bool _isAnalyzing = false;
  String? _selectedFolderId;
  String? _autoRouteMessage;
  bool _isManualPaste = false;

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      setState(() {
        _selectedFile = file;
        _rawContent = content;
        _isManualPaste = false;
        _analysisResult = null;
        _selectedFolderId = null;
        _autoRouteMessage = null;
      });
    }
  }

  Future<void> _analyzeResource() async {
    final contentToAnalyze = _isManualPaste
        ? _pasteController.text
        : _rawContent;

    if (contentToAnalyze == null || contentToAnalyze.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file or paste content first'),
        ),
      );
      return;
    }

    setState(() => _isAnalyzing = true);
    try {
      final parsed = TresParser.parse(contentToAnalyze);
      final projectProvider = context.read<ProjectProvider>();
      final result = await _aiService.analyzeResource(
        parsed,
        entryTypes: projectProvider.entryTypes,
      );
      final targetFolder = projectProvider.resolveImportFolder(
        detectedEntryTypeName: result.detectedEntryTypeName,
        resourceType: result.resourceType,
      );
      final routeMessage = result.detectedEntryTypeName != null
          ? 'Matched entry type "${result.detectedEntryTypeName}"'
          : targetFolder.name == 'Uncategorized Imports'
          ? 'No matching entry type detected. Routed to Uncategorized Imports'
          : 'No entry type match. Routed by resource type to "${targetFolder.name}"';
      setState(() {
        _analysisResult = result;
        _selectedFolderId = targetFolder.id;
        _autoRouteMessage = routeMessage;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Analysis failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _saveEntry() {
    if (_analysisResult == null || _selectedFolderId == null) return;

    final projectProvider = context.read<ProjectProvider>();
    final folder = projectProvider.getFolderById(_selectedFolderId!);
    if (folder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selected folder no longer exists. Please choose another folder.',
          ),
        ),
      );
      return;
    }

    projectProvider.addEntry(folder.id, _analysisResult!);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resource imported successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final folders = context.watch<ProjectProvider>().folders;
    final selectedFolderStillExists =
        _selectedFolderId != null &&
        folders.any((folder) => folder.id == _selectedFolderId);
    final dropdownInitialValue = selectedFolderStillExists
        ? _selectedFolderId
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Import Godot Resource')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Selection Source
            if (_selectedFile == null && !_isManualPaste) ...[
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.file_open),
                label: const Text('Select .tres File'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(24),
                ),
              ),
              const SizedBox(height: 16),
              const Center(child: Text('OR')),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => setState(() => _isManualPaste = true),
                icon: const Icon(Icons.paste),
                label: const Text('Paste .tres Text'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(24),
                ),
              ),
            ] else if (_selectedFile != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.insert_drive_file),
                  title: Text(_selectedFile!.path.split('/').last),
                  subtitle: const Text('File selected'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _selectedFile = null;
                      _rawContent = null;
                      _analysisResult = null;
                      _selectedFolderId = null;
                      _autoRouteMessage = null;
                    }),
                  ),
                ),
              )
            else if (_isManualPaste) ...[
              TextField(
                controller: _pasteController,
                maxLines: 10,
                onChanged: (val) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Paste your .tres content here...',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _isManualPaste = false;
                      _pasteController.clear();
                      _analysisResult = null;
                      _selectedFolderId = null;
                      _autoRouteMessage = null;
                    }),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // 2. Analysis Button
            if ((_selectedFile != null ||
                    (_isManualPaste && _pasteController.text.isNotEmpty)) &&
                _analysisResult == null)
              ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _analyzeResource,
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.psychology),
                label: Text(
                  _isAnalyzing ? 'Analyzing with AI...' : 'Analyze with Gemini',
                ),
              ),

            // 3. Analysis Results
            if (_analysisResult != null) ...[
              const Divider(height: 40),
              Text(
                'Analysis Result',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Card(
                color: colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Chip(label: Text(_analysisResult!.resourceType)),
                          if (_analysisResult!.detectedEntryTypeName !=
                              null) ...[
                            const SizedBox(width: 8),
                            Chip(
                              avatar: const Icon(Icons.category, size: 16),
                              label: Text(
                                _analysisResult!.detectedEntryTypeName!,
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _analysisResult!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _analysisResult!.description,
                        style: const TextStyle(height: 1.4),
                      ),
                      if (_analysisResult!.variableValues.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Extracted Variables',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        ..._analysisResult!.variableValues.entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('${entry.key}: ${entry.value}'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_autoRouteMessage != null) ...[
                Text(
                  _autoRouteMessage!,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Folder Selection
              DropdownButtonFormField<String>(
                key: ValueKey(dropdownInitialValue),
                initialValue: dropdownInitialValue,
                decoration: const InputDecoration(
                  labelText: 'Target Folder (Auto-selected)',
                  border: OutlineInputBorder(),
                ),
                items: folders
                    .map(
                      (f) => DropdownMenuItem(value: f.id, child: Text(f.name)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedFolderId = val),
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _selectedFolderId == null ? null : _saveEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: const Text('Save to Project'),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
