import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/discovery_provider.dart';
import '../widgets/discovery_card.dart';
import 'game_review_screen.dart';

class RecommendedGamesScreen extends StatelessWidget {
  const RecommendedGamesScreen({super.key});

  void _finishSelection(BuildContext context, DiscoveryProvider discovery) {
    if (discovery.similarGames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one similar game before finishing.'),
        ),
      );
      return;
    }

    Navigator.pop(context, true);
  }

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

          return ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pick the games that feel closest to your project, then tap Done to open your Discover feed.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${discovery.similarGames.length} selected',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  _finishSelection(context, discovery),
                              child: const Text('Done'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ...discovery.recommendations.map((game) {
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
              }),
            ],
          );
        },
      ),
    );
  }
}
