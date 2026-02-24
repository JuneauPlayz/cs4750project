import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';
import '../constants.dart';
import '../models/entry_type.dart';
import '../models/folder_entry.dart';
import 'tres_parser.dart';

class AiService {
  final _model = GenerativeModel(
    model: 'gemini-3-flash-preview',
    apiKey: geminiApiKey,
    generationConfig: GenerationConfig(responseMimeType: 'application/json'),
  );

  final _uuid = const Uuid();

  Future<FolderEntry> analyzeResource(
    ParsedResource resource, {
    List<EntryTypeDefinition> entryTypes = const [],
  }) async {
    final entryTypeInstructions = entryTypes.isEmpty
        ? '- No user-defined entry types are available. Set "detectedEntryType" to "UNMATCHED".'
        : entryTypes
              .map((type) {
                final variableSpec = type.variables.isEmpty
                    ? 'no variables'
                    : type.variables
                          .map((variable) {
                            if (variable.kind == EntryVariableKind.entryList) {
                              final referenceType = _findEntryTypeById(
                                entryTypes,
                                variable.referenceEntryTypeId,
                              );
                              final referenceLabel =
                                  referenceType?.name ?? 'another entry type';
                              return '${variable.name} [${variable.kind.label}, list of $referenceLabel]';
                            }
                            return '${variable.name} [${variable.kind.label}]';
                          })
                          .join(', ');
                return '- ${type.name}: $variableSpec';
              })
              .join('\n');

    final prompt =
        '''
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
3. Classify the resource into one of the user-defined entry types below. If no clear match exists, mark it as "UNMATCHED".
4. If classified, extract best-effort values for that entry type's variables.

USER-DEFINED ENTRY TYPES:
$entryTypeInstructions

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
  "description": "MECHANICAL_BEHAVIOR_DESCRIPTION_ONLY",
  "detectedEntryType": "EXACT_ENTRY_TYPE_NAME_OR_UNMATCHED",
  "variables": {
    "Variable Name": "Value extracted from resource, otherwise Unknown"
  }
}
''';

    final response = await _model.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null) throw Exception('AI failed to generate a response');

    final Map<String, dynamic> data = jsonDecode(text);

    // Prioritize the name from the parser if it found one
    final finalName =
        (resource.name != null &&
            resource.name!.trim().isNotEmpty &&
            resource.name != 'Unknown')
        ? resource.name!
        : (data['name'] ?? 'Unknown Resource');
    final detectedEntryTypeName = _normalizeDetectedEntryType(
      data['detectedEntryType']?.toString(),
      entryTypes,
    );
    final variableValues = _extractVariableValues(
      rawVariables: data['variables'],
      detectedEntryTypeName: detectedEntryTypeName,
      entryTypes: entryTypes,
      entryName: finalName,
      resource: resource,
    );

    return FolderEntry(
      id: _uuid.v4(),
      name: finalName,
      description: data['description'] ?? 'No description generated.',
      sourceEngine: 'godot',
      resourceType: data['resourceType'] ?? resource.resourceType,
      detectedEntryTypeName: detectedEntryTypeName,
      variableValues: variableValues,
      rawContent: resource.rawText,
      createdAt: DateTime.now(),
    );
  }

  String? _normalizeDetectedEntryType(
    String? detectedEntryType,
    List<EntryTypeDefinition> entryTypes,
  ) {
    final raw = detectedEntryType?.trim();
    if (raw == null || raw.isEmpty) return null;

    final upper = raw.toUpperCase();
    if (upper == 'UNMATCHED' || upper == 'UNKNOWN' || upper == 'NONE') {
      return null;
    }

    for (final entryType in entryTypes) {
      if (entryType.name.toLowerCase() == raw.toLowerCase()) {
        return entryType.name;
      }
    }

    final normalizedRaw = _normalizeToken(raw);
    for (final entryType in entryTypes) {
      if (_normalizeToken(entryType.name) == normalizedRaw) {
        return entryType.name;
      }
    }
    return null;
  }

  Map<String, String> _extractVariableValues({
    required dynamic rawVariables,
    required String? detectedEntryTypeName,
    required List<EntryTypeDefinition> entryTypes,
    required String entryName,
    required ParsedResource resource,
  }) {
    if (rawVariables is! Map) {
      return const {};
    }

    final extracted = <String, String>{};
    rawVariables.forEach((key, value) {
      final variableKey = key.toString().trim();
      if (variableKey.isEmpty) return;
      final variableValue = value?.toString().trim();
      extracted[variableKey] = (variableValue == null || variableValue.isEmpty)
          ? 'Unknown'
          : variableValue;
    });

    if (detectedEntryTypeName == null) {
      return extracted;
    }

    EntryTypeDefinition? matchedType;
    for (final entryType in entryTypes) {
      if (entryType.name.toLowerCase() == detectedEntryTypeName.toLowerCase()) {
        matchedType = entryType;
        break;
      }
    }
    if (matchedType == null) {
      return extracted;
    }

    final aligned = <String, String>{};
    for (final variable in matchedType.variables) {
      String? value;
      for (final candidate in extracted.entries) {
        if (_normalizeToken(candidate.key) == _normalizeToken(variable.name)) {
          value = candidate.value;
          break;
        }
      }
      aligned[variable.name] = _resolveVariableValue(
        variableName: variable.name,
        currentValue: value,
        entryName: entryName,
        resource: resource,
      );
    }
    return aligned;
  }

  String _resolveVariableValue({
    required String variableName,
    required String? currentValue,
    required String entryName,
    required ParsedResource resource,
  }) {
    final normalizedCurrent = currentValue?.trim();
    if (normalizedCurrent != null &&
        normalizedCurrent.isNotEmpty &&
        normalizedCurrent.toLowerCase() != 'unknown') {
      return normalizedCurrent;
    }

    final normalizedVariable = _normalizeToken(variableName);
    if (normalizedVariable == 'name' || normalizedVariable == 'title') {
      if (entryName.trim().isNotEmpty && entryName != 'Unknown Resource') {
        return entryName;
      }
      if (resource.name != null && resource.name!.trim().isNotEmpty) {
        return resource.name!.trim();
      }
    }

    final propertyMatch = _findPropertyValueForVariable(
      variableName: variableName,
      properties: resource.properties,
    );
    if (propertyMatch != null && propertyMatch.isNotEmpty) {
      return propertyMatch;
    }

    return 'Unknown';
  }

  String? _findPropertyValueForVariable({
    required String variableName,
    required Map<String, String> properties,
  }) {
    final normalizedVariable = _normalizeToken(variableName);
    if (normalizedVariable.isEmpty) return null;

    for (final entry in properties.entries) {
      if (_normalizeToken(entry.key) == normalizedVariable) {
        return entry.value.trim();
      }
    }

    if (normalizedVariable == 'maxhp') {
      for (final candidateKey in const [
        'max_hp',
        'maxhp',
        'hp',
        'health',
        'starting_health',
      ]) {
        final candidate = properties[candidateKey];
        if (candidate != null && candidate.trim().isNotEmpty) {
          return candidate.trim();
        }
      }
    }

    return null;
  }

  String _normalizeToken(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  EntryTypeDefinition? _findEntryTypeById(
    List<EntryTypeDefinition> entryTypes,
    String? id,
  ) {
    if (id == null || id.isEmpty) return null;
    for (final entryType in entryTypes) {
      if (entryType.id == id) return entryType;
    }
    return null;
  }
}
