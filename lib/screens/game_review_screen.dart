import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/game.dart';
import '../providers/discovery_provider.dart';

class GameReviewScreen extends StatefulWidget {
  final Game game;

  const GameReviewScreen({super.key, required this.game});

  @override
  State<GameReviewScreen> createState() => _GameReviewScreenState();
}

class _GameReviewScreenState extends State<GameReviewScreen> {
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
    final details = await context.read<DiscoveryProvider>().fetchGameDetails(widget.game.id);
    if (details != null && mounted) {
      setState(() {
        _fullGame = _fullGame.copyWith(
          summary: details.summary,
          platform: details.platform,
          genres: details.genres,
          metacriticScore: details.metacriticScore,
          released: details.released,
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
    context.read<DiscoveryProvider>().updateGameNotes(_fullGame.id, _notesController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Inspiration notes saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _fullGame.title,
                style: const TextStyle(shadows: [Shadow(color: Colors.black, blurRadius: 10)]),
              ),
              background: _fullGame.coverUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: _fullGame.coverUrl,
                      fit: BoxFit.cover,
                    )
                  : Container(color: colorScheme.surfaceContainerHighest),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (_fullGame.metacriticScore != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                          Text('Released: ${_fullGame.released}', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_isLoadingDetails)
                      const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                    else if (_fullGame.summary.isNotEmpty) ...[
                      Text(
                        'About this Game',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
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
                        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        hintText: 'e.g. The inventory system is really intuitive because...',
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
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
