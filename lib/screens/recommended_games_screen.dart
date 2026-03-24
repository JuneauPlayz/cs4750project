import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/discovery_provider.dart';
import '../widgets/discovery_card.dart';
import 'game_review_screen.dart';

class RecommendedGamesScreen extends StatelessWidget {
  const RecommendedGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recommended for You')),
      body: Consumer<DiscoveryProvider>(
        builder: (context, discovery, child) {
          if (discovery.isLoadingRecommendations) {
            return const Center(child: CircularProgressIndicator());
          }

          if (discovery.recommendations.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No recommendations yet. Update your game description in Game Hub and try again.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: discovery.recommendations.length,
            itemBuilder: (context, index) {
              final game = discovery.recommendations[index];
              final isInSimilarGames = discovery.similarGames.any(
                (existing) => existing.id == game.id,
              );

              return DiscoveryCard(
                game: game,
                onQuickAdd: isInSimilarGames
                    ? null
                    : () {
                        discovery.addSimilarGame(game);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Added ${game.title} to similar games',
                            ),
                          ),
                        );
                      },
                isQuickAdded: isInSimilarGames,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameReviewScreen(game: game),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
