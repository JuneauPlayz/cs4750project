import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/profile_provider.dart';
import '../models/game.dart';
import '../widgets/game_card.dart';
import 'game_search_screen.dart';
import 'game_detail_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Consumer2<ProfileProvider, GameProvider>(
        builder: (context, profileProvider, gameProvider, child) {
          final profile = profileProvider.profile;
          final completedGames = gameProvider.completedGames;
          final currentlyPlaying = gameProvider.currentlyPlaying;
          final topFive = gameProvider.topFive;

          return CustomScrollView(
            slivers: [
              // Profile Header
              SliverToBoxAdapter(
                child: _buildProfileHeader(
                    context, profile.username, completedGames.length),
              ),

              // Top 5 Recommended
              SliverToBoxAdapter(
                child: _buildSection(
                  context,
                  title: '⭐ Top 5 Recommended',
                  child: _buildTopFiveRow(context, topFive),
                ),
              ),

              // Currently Playing
              SliverToBoxAdapter(
                child: _buildSection(
                  context,
                  title: '🎮 Currently Playing',
                  child: currentlyPlaying.isEmpty
                      ? _buildEmptyMessage(
                          context, 'No games in progress — start playing!')
                      : _buildHorizontalGameList(context, currentlyPlaying),
                ),
              ),

              // Completed Games header
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    '✅ Completed (${completedGames.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),

              // Completed Games list
              if (completedGames.isEmpty)
                SliverToBoxAdapter(
                  child: _buildEmptyMessage(context,
                      'No completed games yet. Tap + to add your first!'),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final game = completedGames[index];
                      return GameCard(
                        game: game,
                        onTap: () => _openGameDetail(context, game),
                      );
                    },
                    childCount: completedGames.length,
                  ),
                ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openGameSearch(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Game'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildProfileHeader(
      BuildContext context, String username, int completedCount) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.3),
            colorScheme.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(Icons.person, size: 36, color: colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completedCount games completed',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context,
      {required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildTopFiveRow(BuildContext context, List<Game> topFive) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) {
          if (index < topFive.length) {
            return GameCard(
              game: topFive[index],
              compact: true,
              onTap: () => _openGameDetail(context, topFive[index]),
            );
          }
          // Placeholder slot
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 160,
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outlineVariant,
                      width: 2,
                    ),
                    color: colorScheme.surfaceContainerHighest,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.add_rounded,
                      size: 32,
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Slot ${index + 1}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.outlineVariant,
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalGameList(BuildContext context, List<Game> games) {
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: games.length,
        itemBuilder: (context, index) => GameCard(
          game: games[index],
          compact: true,
          onTap: () => _openGameDetail(context, games[index]),
        ),
      ),
    );
  }

  Widget _buildEmptyMessage(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }

  void _openGameSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GameSearchScreen()),
    );
  }

  void _openGameDetail(BuildContext context, Game game) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GameDetailScreen(game: game)),
    );
  }
}
