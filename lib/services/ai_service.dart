import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';
import '../constants.dart';
import '../models/folder_entry.dart';
import 'tres_parser.dart';

class AiService {
  final _model = GenerativeModel(
    model: 'gemini-3-flash-preview',
    apiKey: geminiApiKey,
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
    ),
  );

  final _uuid = const Uuid();

  Future<FolderEntry> analyzeResource(ParsedResource resource) async {
    final prompt = '''
You are a game design analyst. You are given a structured game resource from the Godot Engine. 
Your job is to explain the EXACT MECHANICAL behavior of this resource.

ANALYSIS RULES:
1. **Verbatim Priority**: If the 'Tooltip' or any field in 'Properties' that is a synonym for 'tooltip' or 'description' contains a designer-written explanation, you MUST copy that text EXACTLY and return it as the 'description'. Do not rephrase, summarize, or edit it.
2. **Strict Mechanical Falling Back**: ONLY if no clear tooltip/description exists should you decipher variables to explain the behavior.
3. **NO FLUFF**: If you must decipher variables, do NOT include lore or flavour text.
4. **Name Preservation**: If 'Name' below is not 'Unknown', you MUST return it EXACTLY.

ANALYSIS STRATEGY:
1. Check 'Name', 'Tooltip', and 'Properties' for existing mechanic descriptions.
2. If missing, decipher variables (triggers, effects, values) to build the mechanical sentence.

Resource Data:
Type: ${resource.resourceType}
Name: ${resource.name ?? 'Unknown'}
Tooltip: ${resource.tooltip ?? 'None'}
Properties: ${resource.properties}
Sub-Resources: ${resource.subResources}

Return JSON:
{
  "name": "RESOURCE_NAME_HERE",
  "resourceType": "RESOURCE_TYPE_HERE",
  "description": "MECHANICAL_BEHAVIOR_DESCRIPTION_ONLY"
}
''';

    final response = await _model.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null) throw Exception('AI failed to generate a response');

    final Map<String, dynamic> data = jsonDecode(text);

    // Prioritize the name from the parser if it found one
    final finalName = (resource.name != null && resource.name!.trim().isNotEmpty && resource.name != 'Unknown')
        ? resource.name!
        : (data['name'] ?? 'Unknown Resource');

    return FolderEntry(
      id: _uuid.v4(),
      name: finalName,
      description: data['description'] ?? 'No description generated.',
      sourceEngine: 'godot',
      resourceType: data['resourceType'] ?? resource.resourceType,
      rawContent: resource.rawText,
      createdAt: DateTime.now(),
    );
  }
}
