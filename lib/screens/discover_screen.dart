import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/discovery_provider.dart';
import '../providers/project_provider.dart';
import '../widgets/discovery_card.dart';
import 'game_search_screen.dart';
import 'game_review_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  void _loadRecommendations() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final project = context.read<ProjectProvider>().project;
      if (project != null && project.genres.isNotEmpty) {
        context.read<DiscoveryProvider>().fetchRecommendations(project.genres);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
      ),
      body: Consumer2<DiscoveryProvider, ProjectProvider>(
        builder: (context, discovery, project, child) {
          return CustomScrollView(
            slivers: [
              // My Similar Games Section
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'My Similar Games',
                  onAdd: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GameSearchScreen()),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: discovery.similarGames.isEmpty
                      ? _EmptyState(message: 'Add games similar to your idea to get started')
                      : ListView.builder(
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
                                MaterialPageRoute(builder: (_) => GameReviewScreen(game: game)),
                              ),
                            );
                          },
                        ),
                ),
              ),

              // Review Feed Section
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Inspiration Feed',
                  onAdd: null,
                ),
              ),
              if (discovery.similarGames.isEmpty)
                const SliverToBoxAdapter(child: _EmptyState(message: 'Add similar games to see their details here'))
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final game = discovery.similarGames[index];
                      return DiscoveryCard(
                        game: game,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => GameReviewScreen(game: game)),
                        ),
                      );
                    },
                    childCount: discovery.similarGames.length,
                  ),
                ),

              // Recommendations Section
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Recommended for You',
                  onAdd: null,
                ),
              ),
              if (discovery.isLoadingRecommendations)
                const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())))
              else if (discovery.recommendations.isEmpty)
                const SliverToBoxAdapter(child: _EmptyState(message: 'Set project genres in Game Hub to see recommendations'))
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final game = discovery.recommendations[index];
                      return DiscoveryCard(
                        game: game,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => GameReviewScreen(game: game)),
                        ),
                      );
                    },
                    childCount: discovery.recommendations.length,
                  ),
                ),
              
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
