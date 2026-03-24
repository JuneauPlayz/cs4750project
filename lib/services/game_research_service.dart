import 'package:flutter/material.dart';

import '../models/game.dart';
import '../models/game_research_link.dart';

class GameResearchService {
  List<GameResearchLink> buildLinks(Game game) {
    final metacriticUrl = _normalizeExternalUrl(game.metacriticUrl);
    final websiteUrl = _normalizeExternalUrl(game.website);
    final redditUrl = _normalizeExternalUrl(game.redditUrl);

    return [
      if (metacriticUrl != null)
        GameResearchLink(
          game: game,
          title: 'Critic Consensus',
          subtitle: 'Metacritic critic page for the overall review spread.',
          icon: Icons.bar_chart_rounded,
          url: metacriticUrl,
        ),
      if (websiteUrl != null)
        GameResearchLink(
          game: game,
          title: 'Official Site',
          subtitle: 'Primary source for trailers, updates, and positioning.',
          icon: Icons.public,
          url: websiteUrl,
        ),
      GameResearchLink(
        game: game,
        title: 'Critic Coverage',
        subtitle:
            'Search for polished review coverage from major games outlets.',
        icon: Icons.article_outlined,
        url: _buildHtmlSearchUrl(
          '${game.title} review IGN GameSpot Eurogamer Rock Paper Shotgun',
        ),
      ),
      GameResearchLink(
        game: game,
        title: 'Mechanics Analysis',
        subtitle:
            'Videos and essays breaking down the systems, loops, and feel.',
        icon: Icons.psychology_alt_outlined,
        url: _buildHtmlSearchUrl(
          '${game.title} mechanics analysis game design breakdown',
        ),
      ),
      GameResearchLink(
        game: game,
        title: 'What Players Like / Dislike',
        subtitle:
            'Community threads discussing strengths, weaknesses, and pain points.',
        icon: Icons.forum_outlined,
        url:
            redditUrl ??
            _buildHtmlSearchUrl(
              'site:reddit.com ${game.title} review discussion what makes it good or bad',
            ),
      ),
      GameResearchLink(
        game: game,
        title: 'Longplay / Raw Gameplay',
        subtitle: 'Unfiltered gameplay to study pacing, UX, and combat flow.',
        icon: Icons.ondemand_video_outlined,
        url: _buildHtmlSearchUrl(
          'site:youtube.com ${game.title} longplay no commentary gameplay',
        ),
      ),
    ];
  }

  List<GameResearchLink> buildMixedFeed(List<Game> games, {int limit = 24}) {
    final perGameLinks = games.map(buildLinks).toList();
    final mixed = <GameResearchLink>[];
    var index = 0;

    while (mixed.length < limit) {
      var addedAny = false;
      for (final links in perGameLinks) {
        if (index < links.length) {
          mixed.add(links[index]);
          addedAny = true;
          if (mixed.length >= limit) break;
        }
      }
      if (!addedAny) break;
      index++;
    }

    return mixed;
  }

  Uri _buildHtmlSearchUrl(String query) {
    return Uri.https('html.duckduckgo.com', '/html/', {'q': query});
  }

  Uri? _normalizeExternalUrl(String? rawUrl) {
    final trimmed = rawUrl?.trim() ?? '';
    if (trimmed.isEmpty) return null;

    final parsed = Uri.tryParse(trimmed);
    if (parsed == null) return null;
    if (parsed.hasScheme) return parsed;

    return Uri.tryParse('https://$trimmed');
  }
}
