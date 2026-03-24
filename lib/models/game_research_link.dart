import 'package:flutter/material.dart';

import 'game.dart';

class GameResearchLink {
  final Game game;
  final String title;
  final String subtitle;
  final IconData icon;
  final Uri url;

  const GameResearchLink({
    required this.game,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.url,
  });
}
