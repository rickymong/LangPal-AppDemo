import 'package:flutter/material.dart';

class Game {
  final String name;
  final int xp;
  final int time; // in minutes
  final String difficulty; // "Easy", "Medium", "Hard"
  final IconData icon;
  final String summary;
  final Widget? gamePage;

  Game({
    required this.name,
    required this.xp,
    required this.time,
    required this.difficulty,
    required this.icon,
    required this.summary,
    this.gamePage,
  });
}