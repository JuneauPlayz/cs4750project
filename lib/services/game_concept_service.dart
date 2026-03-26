import 'package:cloud_functions/cloud_functions.dart';

class GameConceptService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  Future<List<String>> suggestReferenceGames(String conceptDescription) async {
    final trimmedDescription = conceptDescription.trim();
    if (trimmedDescription.isEmpty) {
      return const [];
    }

    try {
      final callable = _functions.httpsCallable('suggestReferenceGames');
      final response = await callable.call(<String, dynamic>{
        'conceptDescription': trimmedDescription,
      });
      final data = response.data;
      if (data is! Map) {
        return const [];
      }
      final games = data['games'];
      if (games is! List) {
        return const [];
      }

      return games
          .map((game) => game.toString().trim())
          .where((game) => game.isNotEmpty)
          .take(7)
          .toList();
    } on FirebaseFunctionsException {
      return const [];
    }
  }
}
