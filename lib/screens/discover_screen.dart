import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_research_link.dart';
import '../providers/discovery_provider.dart';
import '../providers/project_provider.dart';
import '../services/game_research_service.dart';
import '../services/link_launcher_service.dart';
import '../widgets/account_menu_button.dart';
import '../widgets/discovery_card.dart';
import 'game_search_screen.dart';
import 'game_review_screen.dart';
import 'recommended_games_screen.dart';

class DiscoverScreen extends StatefulWidget {
  final bool isActive;

  const DiscoverScreen({super.key, required this.isActive});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final GameResearchService _gameResearchService = GameResearchService();
  final LinkLauncherService _linkLauncherService = LinkLauncherService();
  String _lastConceptSignature = '';
  bool _hasUnlockedResearchFeed = false;
  bool _hasPendingResearchFeedUnlock = false;

  @override
  void didUpdateWidget(covariant DiscoverScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hasSimilarGames = context
        .read<DiscoveryProvider>()
        .similarGames
        .isNotEmpty;

    if (oldWidget.isActive && !widget.isActive && hasSimilarGames) {
      _hasPendingResearchFeedUnlock = true;
    }

    if (!oldWidget.isActive &&
        widget.isActive &&
        hasSimilarGames &&
        _hasPendingResearchFeedUnlock &&
        !_hasUnlockedResearchFeed) {
      _hasPendingResearchFeedUnlock = false;
      if (mounted) {
        setState(() {
          _hasUnlockedResearchFeed = true;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  void _loadRecommendations([String? conceptOverride]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final concept =
          conceptOverride ??
          context.read<ProjectProvider>().project?.conceptDescription ??
          '';
      if (concept.trim().isNotEmpty) {
        context.read<DiscoveryProvider>().fetchRecommendationsForConcept(
          concept,
        );
      }
    });
  }

  Future<void> _openResearchLink(Uri url) async {
    await _linkLauncherService.open(context, url, title: 'Research Link');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: const [AccountMenuButton()],
      ),
      body: Consumer2<DiscoveryProvider, ProjectProvider>(
        builder: (context, discovery, project, child) {
          final concept = project.project?.conceptDescription ?? '';
          final conceptSignature = concept.trim();
          final hasSimilarGames = discovery.similarGames.isNotEmpty;
          final showResearchFeed = hasSimilarGames && _hasUnlockedResearchFeed;
          final researchFeed = _gameResearchService.buildMixedFeed(
            discovery.similarGames,
          );

          if (conceptSignature.isNotEmpty &&
              conceptSignature != _lastConceptSignature) {
            _lastConceptSignature = conceptSignature;
            _loadRecommendations(conceptSignature);
          } else if (conceptSignature.isEmpty &&
              _lastConceptSignature.isNotEmpty) {
            _lastConceptSignature = '';
          }

          if (!hasSimilarGames && _hasUnlockedResearchFeed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _hasUnlockedResearchFeed = false;
                _hasPendingResearchFeedUnlock = false;
              });
            });
          }

          return CustomScrollView(
            slivers: [
              if (!showResearchFeed) ...[
                if (hasSimilarGames)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${discovery.similarGames.length} similar game${discovery.similarGames.length == 1 ? '' : 's'} selected',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Keep picking more games if you want. Discover will stay in recommendation mode until you switch to another tab and come back.',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'Recommended for You',
                    onAdd: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GameSearchScreen(),
                      ),
                    ),
                  ),
                ),
                if (discovery.isLoadingRecommendations)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 14),
                              Text(
                                "We're looking for similar games based on your description...",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else if (discovery.recommendations.isEmpty)
                  SliverToBoxAdapter(
                    child: _EmptyState(
                      message: conceptSignature.isEmpty
                          ? 'Describe your game in Game Hub to see recommendations.'
                          : 'We could not find strong matches yet. Try refining your game description.',
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
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
                    }, childCount: discovery.recommendations.length),
                  ),
              ] else ...[
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: 'My Similar Games',
                    onAdd: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GameSearchScreen(),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 220,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: discovery.similarGames.length,
                      itemBuilder: (context, index) {
                        final game = discovery.similarGames[index];
                        return DiscoveryCard(
                          game: game,
                          isCompact: true,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GameReviewScreen(game: game),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (!showResearchFeed)
                  const SliverToBoxAdapter(
                    child: _EmptyState(
                      message:
                          'Your similar games are saved. Reopen the Discover tab to turn this page into a mixed research feed.',
                    ),
                  )
                else ...[
                  const SliverToBoxAdapter(
                    child: _FeedHeader(title: 'Research Feed'),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final link = researchFeed[index];
                      return _ResearchFeedCard(
                        link: link,
                        onOpen: () => _openResearchLink(link.url),
                        onOpenGame: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GameReviewScreen(game: link.game),
                          ),
                        ),
                      );
                    }, childCount: researchFeed.length),
                  ),
                ],
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                    child: FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RecommendedGamesScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.explore_outlined),
                      label: const Text('Open Recommended For You'),
                    ),
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 50)),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onAdd;

  const _SectionHeader({required this.title, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (onAdd != null)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: onAdd,
              color: Theme.of(context).colorScheme.primary,
            ),
        ],
      ),
    );
  }
}

class _FeedHeader extends StatelessWidget {
  final String title;

  const _FeedHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
    );
  }
}

class _ResearchFeedCard extends StatelessWidget {
  final GameResearchLink link;
  final VoidCallback onOpen;
  final VoidCallback onOpenGame;

  const _ResearchFeedCard({
    required this.link,
    required this.onOpen,
    required this.onOpenGame,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (link.game.coverUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(link.game.coverUrl, fit: BoxFit.cover),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(link.icon, color: colorScheme.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          link.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Icon(Icons.open_in_new, size: 18),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    link.game.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    link.subtitle,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      TextButton(
                        onPressed: onOpenGame,
                        child: const Text('Open Game Page'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: onOpen,
                        child: const Text('Open Link'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
