import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../data/models/exercise.dart';
import '../../providers/app_providers.dart';

enum ExerciseFilterBarMode {
  today,    // User-enabled exercises + "+ ADD EXERCISE" button
  userOnly, // User-enabled exercises only
  all,      // All available exercises (for Crew Leaderboard)
}

/// Reusable text-only Exercise Filter Bar supporting Today mode, User-specific mode, and All mode.
class ExerciseFilterBar extends ConsumerWidget {
  final ExerciseFilterBarMode mode;
  final List<String>? customExerciseIds;

  const ExerciseFilterBar({
    super.key,
    this.mode = ExerciseFilterBarMode.all,
    this.customExerciseIds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(selectedExerciseFilterProvider);
    final userEnabledIds = ref.watch(userEnabledExercisesProvider);

    final builtInExercises = [
      ExerciseDef.pushups,
      ExerciseDef.pullups,
      ExerciseDef.squats,
    ];

    final filters = switch (mode) {
      ExerciseFilterBarMode.today || ExerciseFilterBarMode.userOnly =>
        userEnabledIds.map((id) => ExerciseDef.fromId(id)).toList(),
      ExerciseFilterBarMode.all => (customExerciseIds != null && customExerciseIds!.isNotEmpty)
          ? customExerciseIds!.map((id) => ExerciseDef.fromId(id)).toList()
          : builtInExercises,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...filters.map((ex) {
            final isSelected = selectedFilter == ex.id;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  ref.read(selectedExerciseFilterProvider.notifier).state = ex.id;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? ex.color.withValues(alpha: 0.15) : AppColors.panel,
                    border: Border.all(
                      color: isSelected ? ex.color : AppColors.line,
                    ),
                  ),
                  child: Text(
                    ex.name.toUpperCase(),
                    style: AppTypography.mono.copyWith(
                      color: isSelected ? ex.color : AppColors.inkFaint,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
            );
          }),

          // "+ ADD EXERCISE" button on Today screen
          if (mode == ExerciseFilterBarMode.today) ...[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showAddExerciseSheet(context, ref, userEnabledIds, builtInExercises),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.panel2,
                  border: Border.all(color: AppColors.signal.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add, size: 12, color: AppColors.signal),
                    const SizedBox(width: 4),
                    Text(
                      'ADD EXERCISE',
                      style: AppTypography.mono.copyWith(
                        color: AppColors.signal,
                        fontWeight: FontWeight.w900,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddExerciseSheet(
    BuildContext context,
    WidgetRef ref,
    List<String> userEnabledIds,
    List<ExerciseDef> allExercises,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      builder: (ctx) {
        final customController = TextEditingController();

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ADD EXERCISE TO TODAY TABS',
                      style: AppTypography.monoSmall.copyWith(
                        color: AppColors.signal,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close, color: AppColors.inkFaint, size: 18),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Available Exercises List
                ...allExercises.map((ex) {
                  final isAdded = userEnabledIds.contains(ex.id);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.panel2,
                      border: Border.all(color: isAdded ? ex.color : AppColors.line),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ex.name.toUpperCase(),
                          style: AppTypography.heading.copyWith(
                            color: isAdded ? ex.color : AppColors.ink,
                            fontSize: 13,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (isAdded) {
                              if (ex.id != 'pushups') {
                                ref.read(userEnabledExercisesProvider.notifier).removeExercise(ex.id);
                                if (ref.read(selectedExerciseFilterProvider) == ex.id) {
                                  ref.read(selectedExerciseFilterProvider.notifier).state = 'pushups';
                                }
                              }
                            } else {
                              ref.read(userEnabledExercisesProvider.notifier).addExercise(ex.id);
                              ref.read(selectedExerciseFilterProvider.notifier).state = ex.id;
                            }
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isAdded ? AppColors.panel3 : ex.color,
                              border: Border.all(color: ex.color),
                            ),
                            child: Text(
                              isAdded ? (ex.id == 'pushups' ? 'DEFAULT' : 'REMOVE') : 'ADD TAB',
                              style: AppTypography.monoTiny.copyWith(
                                color: isAdded ? AppColors.inkFaint : const Color(0xFF160D09),
                                fontWeight: FontWeight.w900,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                // User-added Custom Exercises
                ...userEnabledIds
                    .where((id) => !allExercises.any((e) => e.id == id))
                    .map((customId) {
                  final customEx = ExerciseDef.fromId(customId);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.panel2,
                      border: Border.all(color: customEx.color),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          customEx.name.toUpperCase(),
                          style: AppTypography.heading.copyWith(
                            color: customEx.color,
                            fontSize: 13,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            ref.read(userEnabledExercisesProvider.notifier).removeExercise(customId);
                            if (ref.read(selectedExerciseFilterProvider) == customId) {
                              ref.read(selectedExerciseFilterProvider.notifier).state = 'pushups';
                            }
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.panel3,
                              border: Border.all(color: customEx.color),
                            ),
                            child: Text(
                              'REMOVE',
                              style: AppTypography.monoTiny.copyWith(
                                color: AppColors.inkFaint,
                                fontWeight: FontWeight.w900,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 12),
                Container(height: 1, color: AppColors.line),
                const SizedBox(height: 12),

                // Custom Exercise Creation Panel
                Text(
                  'CREATE CUSTOM EXERCISE',
                  style: AppTypography.monoSmall.copyWith(
                    color: AppColors.inkFaint,
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.panel2,
                          border: Border.all(color: AppColors.lineStrong),
                        ),
                        alignment: Alignment.center,
                        child: TextField(
                          controller: customController,
                          textAlignVertical: TextAlignVertical.center,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.ink, fontSize: 12),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintText: 'e.g. Dips, Burpees, Lunges...',
                            hintStyle: TextStyle(color: AppColors.inkFaint, fontSize: 11),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        final text = customController.text.trim();
                        if (text.isNotEmpty) {
                          final customId = text.toLowerCase().replaceAll(' ', '_');
                          ref.read(userEnabledExercisesProvider.notifier).addExercise(customId);
                          ref.read(selectedExerciseFilterProvider.notifier).state = customId;
                        }
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        color: AppColors.signal,
                        alignment: Alignment.center,
                        child: Text(
                          'CREATE & ADD',
                          style: AppTypography.monoTiny.copyWith(
                            color: const Color(0xFF160D09),
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
