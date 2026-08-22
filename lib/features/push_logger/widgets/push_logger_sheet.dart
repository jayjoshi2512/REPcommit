import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/app_providers.dart';

/// Push-up logger bottom sheet.
///
/// UI: counter with ±5 buttons, quick-value grid (10/20/30/50),
/// custom number input field, "Log push-ups" save button and cancel.
class PushLoggerSheet extends ConsumerStatefulWidget {
  const PushLoggerSheet({super.key});

  @override
  ConsumerState<PushLoggerSheet> createState() => _PushLoggerSheetState();
}

class _PushLoggerSheetState extends ConsumerState<PushLoggerSheet> {
  int _count = AppConstants.counterDefault;
  final _customController = TextEditingController();
  bool _isCustomMode = false;

  @override
  void dispose() {
    _customController.dispose();
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
            'NEW COMMIT / PUSH-UP SET',
            style: AppTypography.micro.copyWith(color: const Color(0xFF77766F)),
          ),
          const SizedBox(height: 6),
          Text(
            'How many push-ups did you do?',
            style: AppTypography.displaySmall.copyWith(color: AppColors.black),
          ),
          const SizedBox(height: 5),
          Text(
            'Tap the number to type a custom count.',
            style: AppTypography.bodySmall.copyWith(color: const Color(0xFF63625B)),
          ),
          // Counter
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
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
                            ? AppColors.signal.withValues(alpha: 0.15)
                            : const Color(0xFFE6E2D9),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.signal
                              : const Color(0xFFD0CBC0),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$v',
                        style: AppTypography.mono.copyWith(
                          color: isSelected ? AppColors.signal : AppColors.black,
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
          const SizedBox(height: 8),
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
                      HapticFeedback.mediumImpact();
                      ref.read(appStateProvider.notifier).logPushUps(_count);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('+$_count push-ups logged'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Container(
                    height: 43,
                    color: AppColors.signal,
                    alignment: Alignment.center,
                    child: Text(
                      'Log push-ups',
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
