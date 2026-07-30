import 'package:flutter/material.dart';

enum SoundCategory {
  all('All', Icons.grid_view_rounded),
  nature('Nature', Icons.eco_outlined),
  rain('Rain', Icons.umbrella_outlined),
  whiteNoise('White noise', Icons.graphic_eq_rounded),
  sleepMusic('Sleep music', Icons.music_note_outlined),
  ambient('Ambient', Icons.nights_stay_outlined),
  relaxation('Relaxation', Icons.spa_outlined);

  final String label;
  final IconData icon;

  const SoundCategory(this.label, this.icon);

  bool get isPremium => this == SoundCategory.sleepMusic || this == SoundCategory.relaxation;
}
