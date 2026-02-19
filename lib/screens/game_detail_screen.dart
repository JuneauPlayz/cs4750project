import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/game.dart';
import '../providers/game_provider.dart';
import '../widgets/rating_widget.dart';

class GameDetailScreen extends StatefulWidget {
  final Game game;

  const GameDetailScreen({super.key, required this.game});

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  late GameStatus _status;
  late double _rating;
  late TextEditingController _reviewController;
  late bool _isTopFive;

  @override
  void initState() {
    super.initState();
    _status = widget.game.status;
    _rating = widget.game.userRating ?? 0.0;
    _reviewController = TextEditingController(text: widget.game.userReview ?? '');
    _isTopFive = widget.game.isTopFive;
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _saveGame() {
    final gameProvider = context.read<GameProvider>();
    
    // Validation for Top 5
    if (_isTopFive && !_isTopFiveWasSavedBefore && !gameProvider.canAddToTopFive()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You already have 5 games in your Top 5!')),
      );
      return;
    }

    final updatedGame = widget.game.copyWith(
      status: _status,
      userRating: _rating > 0 ? _rating : null,
      userReview: _reviewController.text,
      isTopFive: _isTopFive,
      dateCompleted: _status == GameStatus.completed ? DateTime.now() : null,
    );

    gameProvider.addGame(updatedGame);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  bool get _isTopFiveWasSavedBefore => widget.game.isTopFive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.game.title,
                style: const TextStyle(
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                ),
              ),
              background: widget.game.coverUrl.isNotEmpty
                  ? Hero(
                      tag: 'game_cover_${widget.game.id}',
                      child: CachedNetworkImage(
                        imageUrl: widget.game.coverUrl,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(color: colorScheme.surfaceContainerHighest),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<GameStatus>(
                      segments: const [
                        ButtonSegment(
                          value: GameStatus.playing,
                          label: Text('Playing'),
                          icon: Icon(Icons.play_arrow),
                        ),
                        ButtonSegment(
                          value: GameStatus.completed,
                          label: Text('Completed'),
                          icon: Icon(Icons.check),
                        ),
                        ButtonSegment(
                          value: GameStatus.wishlist,
                          label: Text('Wishlist'),
                          icon: Icon(Icons.bookmark),
                        ),
                      ],
                      selected: {_status},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          _status = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Your Rating',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: RatingWidget(
                        rating: _rating,
                        onChanged: (val) => setState(() => _rating = val),
                        starSize: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Your Thoughts',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reviewController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'What did you think of the game?',
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    CheckboxListTile(
                      title: const Text('Add to my Top 5 Recommended'),
                      subtitle: const Text('Show this game off on your profile'),
                      value: _isTopFive,
                      onChanged: (val) => setState(() => _isTopFive = val ?? false),
                      contentPadding: EdgeInsets.zero,
                      activeColor: colorScheme.primary,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saveGame,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Save Entry'),
                      ),
                    ),
                    const SizedBox(height: 48),
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
