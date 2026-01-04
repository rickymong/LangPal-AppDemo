import 'package:flutter/material.dart';

class Lesson {
  final String name;
  final double progress;
  final int xp;
  final String lessonType;
  final IconData icon;

  Lesson({
    required this.name,
    this.progress = 0.0,
    required this.xp,
    required this.lessonType,
    required this.icon,
  });
}