import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/game.dart';

class DiscoveryCard extends StatelessWidget {
  final Game game;
  final VoidCallback onTap;
  final bool isCompact;
  final VoidCallback? onQuickAdd;
  final VoidCallback? onRemove;
  final VoidCallback? onDismiss;
  final bool isQuickAdded;
  final String? supportingText;

  const DiscoveryCard({
    super.key,
    required this.game,
    required this.onTap,
    this.isCompact = false,
    this.onQuickAdd,
    this.onRemove,
    this.onDismiss,
    this.isQuickAdded = false,
    this.supportingText,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) return _buildCompact(context);

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  game.coverUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: game.coverUrl,
                          fit: BoxFit.cover,
                        )
                      : Container(color: colorScheme.surfaceContainerHighest),
                  if (game.metacriticScore != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getMetacriticColor(game.metacriticScore!),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          game.metacriticScore!.toInt().toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (onDismiss != null)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Material(
                        color: Colors.black54,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onDismiss,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (onQuickAdd != null)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Material(
                        color: Colors.black54,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: isQuickAdded ? null : onQuickAdd,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              isQuickAdded ? Icons.check : Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    game.genres.join(', '),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  if (supportingText != null &&
                      supportingText!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      supportingText!,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: game.coverUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: game.coverUrl,
                      fit: BoxFit.cover,
                    )
                  : Container(color: Colors.grey[800]),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  game.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getMetacriticColor(double score) {
    if (score >= 75) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
}
