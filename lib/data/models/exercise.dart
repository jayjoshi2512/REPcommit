import 'package:flutter/material.dart';

/// Exercise definition model for RepCommit multi-exercise tracking.
class ExerciseDef {
  final String id;
  final String name;
  final IconData icon;
  final String unit; // 'reps' or 'sec'
  final Color color;

  const ExerciseDef({
    required this.id,
    required this.name,
    required this.icon,
    this.unit = 'reps',
    required this.color,
  });

  /// Built-in exercises
  static const pushups = ExerciseDef(
    id: 'pushups',
    name: 'Push-ups',
    icon: Icons.fitness_center,
    unit: 'reps',
    color: Color(0xFFFF521B), // AppColors.signal
  );

  static const pullups = ExerciseDef(
    id: 'pullups',
    name: 'Pull-ups',
    icon: Icons.height,
    unit: 'reps',
    color: Color(0xFF00E676), // AppColors.mint
  );

  static const squats = ExerciseDef(
    id: 'squats',
    name: 'Squats',
    icon: Icons.directions_run,
    unit: 'reps',
    color: Color(0xFF00B0FF), // Ice Blue
  );

  static const List<ExerciseDef> builtIn = [
    pushups,
    pullups,
    squats,
  ];

  /// Get exercise definition by ID or create dynamic custom definition.
  factory ExerciseDef.fromId(String id) {
    final cleanId = id.trim().toLowerCase();
    for (final ex in builtIn) {
      if (ex.id == cleanId) return ex;
    }
    // Dynamic Custom Exercise
    final formattedName = id.isEmpty
        ? 'Custom'
        : id[0].toUpperCase() + id.substring(1);
    return ExerciseDef(
      id: cleanId.isEmpty ? 'custom' : cleanId,
      name: formattedName,
      icon: Icons.bolt,
      unit: 'reps',
      color: const Color(0xFFFFAB00), // Amber
    );
  }
}
