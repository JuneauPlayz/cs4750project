import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../constants.dart';

class GameConceptService {
  final _model = GenerativeModel(
    model: 'gemini-3-flash-preview',
    apiKey: geminiApiKey,
    generationConfig: GenerationConfig(responseMimeType: 'application/json'),
  );

  Future<List<String>> suggestReferenceGames(String conceptDescription) async {
    final prompt =
        '''
You help game developers find modern reference games.

Given a short concept description, return JSON with a "games" array of 5 to 7 recognizable video game titles that are:
- stylistically or mechanically similar
- mostly modern (prefer 2016 and later)
- not obscure unless the description clearly asks for retro or niche inspirations
- useful references for a developer researching current market expectations

Concept:
$conceptDescription

Return JSON only:
{
  "games": ["Title 1", "Title 2", "Title 3"]
}
''';

    final response = await _model.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null || text.trim().isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      return const [];
    }

    final games = decoded['games'];
    if (games is! List) {
      return const [];
    }

    return games
        .map((game) => game.toString().trim())
        .where((game) => game.isNotEmpty)
        .take(7)
        .toList();
  }
}
