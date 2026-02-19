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
  bool _isManualPaste = false;

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      setState(() {
        _selectedFile = file;
        _rawContent = content;
        _isManualPaste = false;
        _analysisResult = null;
      });
    }
  }

  Future<void> _analyzeResource() async {
    final contentToAnalyze = _isManualPaste ? _pasteController.text : _rawContent;
    
    if (contentToAnalyze == null || contentToAnalyze.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file or paste content first')),
      );
      return;
    }

    setState(() => _isAnalyzing = true);
    try {
      final parsed = TresParser.parse(contentToAnalyze);
      final result = await _aiService.analyzeResource(parsed);
      setState(() => _analysisResult = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _saveEntry() {
    if (_analysisResult == null || _selectedFolderId == null) return;

    context.read<ProjectProvider>().addEntry(_selectedFolderId!, _analysisResult!);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resource imported successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final folders = context.watch<ProjectProvider>().folders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Godot Resource'),
      ),
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
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(24)),
              ),
              const SizedBox(height: 16),
              const Center(child: Text('OR')),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => setState(() => _isManualPaste = true),
                icon: const Icon(Icons.paste),
                label: const Text('Paste .tres Text'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(24)),
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
                    }),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // 2. Analysis Button
            if ((_selectedFile != null || (_isManualPaste && _pasteController.text.isNotEmpty)) && _analysisResult == null)
              ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _analyzeResource,
                icon: _isAnalyzing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.psychology),
                label: Text(_isAnalyzing ? 'Analyzing with AI...' : 'Analyze with Gemini'),
              ),

            // 3. Analysis Results
            if (_analysisResult != null) ...[
              const Divider(height: 40),
              Text('Analysis Result', style: Theme.of(context).textTheme.titleMedium),
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _analysisResult!.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(_analysisResult!.description, style: const TextStyle(height: 1.4)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Folder Selection
              DropdownButtonFormField<String>(
                initialValue: _selectedFolderId,
                decoration: const InputDecoration(
                  labelText: 'Select Target Folder',
                  border: OutlineInputBorder(),
                ),
                items: folders.map((f) => DropdownMenuItem(
                  value: f.id,
                  child: Text(f.name),
                )).toList(),
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
