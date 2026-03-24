import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../models/game.dart';
import '../models/game_research_link.dart';
import '../providers/discovery_provider.dart';
import '../services/game_research_service.dart';
import '../services/link_launcher_service.dart';

class GameReviewScreen extends StatefulWidget {
  final Game game;

  const GameReviewScreen({super.key, required this.game});

  @override
  State<GameReviewScreen> createState() => _GameReviewScreenState();
}

class _GameReviewScreenState extends State<GameReviewScreen> {
  final GameResearchService _gameResearchService = GameResearchService();
  final LinkLauncherService _linkLauncherService = LinkLauncherService();
  late TextEditingController _notesController;
  bool _isLoadingDetails = false;
  late Game _fullGame;

  @override
  void initState() {
    super.initState();
    _fullGame = widget.game;
    _notesController = TextEditingController(text: _fullGame.userNotes ?? '');
    _loadFullDetails();
  }

  Future<void> _loadFullDetails() async {
    if (_fullGame.summary.isNotEmpty) return;

    setState(() => _isLoadingDetails = true);
    final details = await context.read<DiscoveryProvider>().fetchGameDetails(
      widget.game.id,
    );
    if (details != null && mounted) {
      setState(() {
        _fullGame = _fullGame.copyWith(
          summary: details.summary,
          platform: details.platform,
          genres: details.genres,
          metacriticScore: details.metacriticScore,
          released: details.released,
          website: details.website,
          metacriticUrl: details.metacriticUrl,
          redditUrl: details.redditUrl,
        );
        _isLoadingDetails = false;
      });
    } else if (mounted) {
      setState(() => _isLoadingDetails = false);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _saveNotes() {
    context.read<DiscoveryProvider>().updateGameNotes(
      _fullGame.id,
      _notesController.text,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Inspiration notes saved')));
  }

  Future<void> _openLink(Uri url) async {
    await _linkLauncherService.open(context, url, title: _fullGame.title);
  }

  List<GameResearchLink> _buildReviewSources() =>
      _gameResearchService.buildLinks(_fullGame);

  Widget _buildGameDescriptionTab(ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            if (_fullGame.metacriticScore != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'Metacritic: ${_fullGame.metacriticScore!.toInt()}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
            ],
            if (_fullGame.released != null)
              Expanded(
                child: Text(
                  'Released: ${_fullGame.released}',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (_isLoadingDetails)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_fullGame.summary.isNotEmpty) ...[
          Text(
            'About this Game',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _fullGame.summary,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
        ],
        const Divider(),
        const SizedBox(height: 24),
        Text(
          'Design Inspiration & Notes',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'What can you learn from this game for your own project? Note down mechanics, art style, or design choices that inspired you.',
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          maxLines: 10,
          decoration: InputDecoration(
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            hintText:
                'e.g. The inventory system is really intuitive because...',
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _saveNotes,
            icon: const Icon(Icons.save),
            label: const Text('Save Inspiration Notes'),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildReviewsTab(ColorScheme colorScheme) {
    final sources = _buildReviewSources();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Research Links',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'A single list of pages that are useful when studying this game: critic reviews, mechanics analysis, player discussion, and raw gameplay footage.',
          style: TextStyle(color: colorScheme.onSurfaceVariant, height: 1.4),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < sources.length; i++) ...[
                ListTile(
                  leading: Icon(sources[i].icon, color: colorScheme.primary),
                  title: Text(sources[i].title),
                  subtitle: Text(sources[i].subtitle),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openLink(sources[i].url),
                ),
                if (i != sources.length - 1)
                  Divider(
                    height: 1,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
              ],
            ],
          ),
        ),
        if (_isLoadingDetails) ...[
          const SizedBox(height: 20),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
          ),
        ],
        if (_fullGame.summary.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Quick context',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            _fullGame.summary,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tabs = [
      const Tab(text: 'Game Description'),
      const Tab(text: 'Reviews'),
    ];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                title: Text(
                  _fullGame.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                centerTitle: false,
                titleSpacing: 20,
                expandedHeight: 250,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: _fullGame.coverUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: _fullGame.coverUrl,
                          fit: BoxFit.cover,
                        )
                      : Container(color: colorScheme.surfaceContainerHighest),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(70),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: TabBar(
                        tabs: tabs,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.35),
                          ),
                        ),
                        indicatorPadding: const EdgeInsets.all(6),
                        labelColor: colorScheme.onPrimaryContainer,
                        unselectedLabelColor: colorScheme.onSurfaceVariant,
                        labelStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildGameDescriptionTab(colorScheme),
              _buildReviewsTab(colorScheme),
            ],
          ),
        ),
      ),
    );
  }
}
