import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/app_providers.dart';
import '../../../data/models/exercise.dart';

/// Push-up & workout logger bottom sheet.
///
/// UI: Exercise type selector (Push-ups, Pull-ups, Squats, Custom),
/// counter with ±5 buttons, quick-value grid (10/20/30/50),
/// custom number input field, and save action.
class PushLoggerSheet extends ConsumerStatefulWidget {
  const PushLoggerSheet({super.key});

  @override
  ConsumerState<PushLoggerSheet> createState() => _PushLoggerSheetState();
}

class _PushLoggerSheetState extends ConsumerState<PushLoggerSheet> {
  int _count = AppConstants.counterDefault;
  String _selectedExerciseId = 'pushups';
  final _customController = TextEditingController();
  final _customExerciseController = TextEditingController();
  bool _isCustomMode = false;
  bool _isCustomExerciseMode = false;

  @override
  void initState() {
    super.initState();
    final activeFilter = ref.read(selectedExerciseFilterProvider);
    if (activeFilter != 'all') {
      final builtInIds = ExerciseDef.builtIn.map((e) => e.id).toSet();
      if (builtInIds.contains(activeFilter)) {
        _selectedExerciseId = activeFilter;
        _isCustomExerciseMode = false;
      } else {
        _isCustomExerciseMode = true;
        _customExerciseController.text = activeFilter;
      }
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    _customExerciseController.dispose();
    super.dispose();
  }

  void _setCount(int value) {
    setState(() {
      _count = value.clamp(1, 999);
      _isCustomMode = false;
    });
  }

  void _enterCustomMode() {
    _customController.text = _count > 0 ? '$_count' : '';
    _customController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _customController.text.length,
    );
    setState(() => _isCustomMode = true);
  }

  void _exitCustomMode() {
    final parsed = int.tryParse(_customController.text);
    if (parsed != null && parsed > 0) {
      _count = parsed.clamp(1, 999);
    }
    setState(() => _isCustomMode = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final currentExDef = ExerciseDef.fromId(
      _isCustomExerciseMode
          ? (_customExerciseController.text.trim().isEmpty ? 'custom' : _customExerciseController.text.trim())
          : _selectedExerciseId,
    );

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(10),
          color: AppColors.paper,
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NEW COMMIT / WORKOUT SET',
                style: AppTypography.micro.copyWith(color: const Color(0xFF77766F)),
              ),
              const SizedBox(height: 6),
              Text(
                'Select Exercise & Reps',
                style: AppTypography.displaySmall.copyWith(color: AppColors.black),
              ),
              const SizedBox(height: 10),

              // Exercise Type Selector Chips (Text-only for user-enabled exercises)
              Builder(
                builder: (context) {
                  final userEnabledIds = ref.watch(userEnabledExercisesProvider);
                  final userExercises = userEnabledIds.map((id) => ExerciseDef.fromId(id)).toList();

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...userExercises.map((ex) {
                          final isSelected = !_isCustomExerciseMode && _selectedExerciseId == ex.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedExerciseId = ex.id;
                                  _isCustomExerciseMode = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected ? ex.color : const Color(0xFFE6E2D9),
                                  border: Border.all(
                                    color: isSelected ? ex.color : const Color(0xFFD0CBC0),
                                  ),
                                ),
                                child: Text(
                                  ex.name.toUpperCase(),
                                  style: AppTypography.mono.copyWith(
                                    color: isSelected ? Colors.black : AppColors.black,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        // Custom Exercise chip (Text-only)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isCustomExerciseMode = true;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                            decoration: BoxDecoration(
                              color: _isCustomExerciseMode ? const Color(0xFFFFAB00) : const Color(0xFFE6E2D9),
                              border: Border.all(
                                color: _isCustomExerciseMode ? const Color(0xFFFFAB00) : const Color(0xFFD0CBC0),
                              ),
                            ),
                            child: Text(
                              'CUSTOM',
                              style: AppTypography.mono.copyWith(
                                color: _isCustomExerciseMode ? Colors.black : AppColors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              if (_isCustomExerciseMode) ...[
                const SizedBox(height: 10),
                Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6E2D9),
                    border: Border.all(color: const Color(0xFFFFAB00)),
                  ),
                  child: TextField(
                    controller: _customExerciseController,
                    autofocus: true,
                    style: AppTypography.body.copyWith(color: AppColors.black, fontSize: 12),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter exercise name (e.g. Dips, Sit-ups, Plank)...',
                      hintStyle: AppTypography.bodySmall.copyWith(color: const Color(0xFF77766F), fontSize: 11),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 14),
              Text(
                'How many ${currentExDef.name.toLowerCase()} did you do?',
                style: AppTypography.bodySmall.copyWith(color: const Color(0xFF63625B)),
              ),

              // Counter
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    _RoundButton(
                      label: '−',
                      onTap: () => _setCount(_count - AppConstants.counterStep),
                    ),
                    Expanded(
                      child: Center(
                        child: _isCustomMode
                            ? SizedBox(
                                width: 100,
                                child: TextField(
                                  controller: _customController,
                                  autofocus: true,
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(3),
                                  ],
                                  style: AppTypography.counter.copyWith(
                                    color: AppColors.black,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (val) {
                                    final parsed = int.tryParse(val);
                                    if (parsed != null && parsed > 0) {
                                      setState(() {
                                        _count = parsed.clamp(1, 999);
                                      });
                                    }
                                  },
                                  onSubmitted: (_) => _exitCustomMode(),
                                  onTapOutside: (_) => _exitCustomMode(),
                                ),
                              )
                            : GestureDetector(
                                onTap: _enterCustomMode,
                                child: Text(
                                  '$_count',
                                  style: AppTypography.counter.copyWith(
                                    color: AppColors.black,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    _RoundButton(
                      label: '+',
                      onTap: () => _setCount(_count + AppConstants.counterStep),
                    ),
                  ],
                ),
              ),
              // Quick values
              Row(
                children: AppConstants.quickValues.map((v) {
                  final isSelected = v == _count;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: v == AppConstants.quickValues.last ? 0 : 5,
                      ),
                      child: GestureDetector(
                        onTap: () => _setCount(v),
                        child: Container(
                          height: 34,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? currentExDef.color.withValues(alpha: 0.2)
                                : const Color(0xFFE6E2D9),
                            border: Border.all(
                              color: isSelected
                                  ? currentExDef.color
                                  : const Color(0xFFD0CBC0),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$v',
                            style: AppTypography.mono.copyWith(
                              color: isSelected ? AppColors.black : AppColors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        height: 43,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9E5DB),
                          border: Border.all(color: const Color(0xFFD0CBC0)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Cancel',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.black),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // If in custom mode, read the text field first.
                        if (_isCustomMode) {
                          final parsed = int.tryParse(_customController.text);
                          if (parsed != null && parsed > 0) {
                            _count = parsed.clamp(1, 999);
                          }
                        }
                        if (_count > 0) {
                          final targetExId = _isCustomExerciseMode
                              ? (_customExerciseController.text.trim().isEmpty ? 'custom' : _customExerciseController.text.trim().toLowerCase())
                              : _selectedExerciseId;

                          HapticFeedback.mediumImpact();
                          ref.read(userEnabledExercisesProvider.notifier).addExercise(targetExId);
                          ref.read(selectedExerciseFilterProvider.notifier).state = targetExId;
                          ref.read(appStateProvider.notifier).logPushUps(_count, exerciseId: targetExId);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('+$_count ${ExerciseDef.fromId(targetExId).name} logged'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Container(
                        height: 43,
                        color: currentExDef.color,
                        alignment: Alignment.center,
                        child: Text(
                          'LOG SET',
                          style: AppTypography.bodySmall.copyWith(
                            color: const Color(0xFF150E0A),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _RoundButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFE9E5DB),
          border: Border.all(color: const Color(0xFFD5D1C8)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 22,
            color: Color(0xFF171713),
          ),
        ),
      ),
    );
  }
}
