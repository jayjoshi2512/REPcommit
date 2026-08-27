import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../providers/app_providers.dart';

/// Username selection screen — part of onboarding.
///
/// Validates uniqueness against the Firestore `usernames` collection.
class UsernameScreen extends ConsumerStatefulWidget {
  const UsernameScreen({super.key});

  @override
  ConsumerState<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends ConsumerState<UsernameScreen> {
  final _controller = TextEditingController();
  String _status = ''; // '', 'checking', 'available', 'taken', 'invalid'
  bool _isSaving = false;
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _debounce?.cancel();

    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) {
      setState(() => _status = '');
      return;
    }

    // Validate format: 3-20 chars, alphanumeric + underscores only.
    final regex = RegExp(r'^[a-z0-9_]{3,20}$');
    if (!regex.hasMatch(trimmed)) {
      setState(() => _status = 'invalid');
      return;
    }

    setState(() => _status = 'checking');

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final firestore = ref.read(firestoreServiceProvider);
      final available = await firestore.isUsernameAvailable(trimmed);
      if (mounted) {
        setState(() => _status = available ? 'available' : 'taken');
      }
    });
  }

  Future<void> _confirm() async {
    final username = _controller.text.trim().toLowerCase();
    if (_status != 'available') return;

    setState(() => _isSaving = true);

    try {
      final firestore = ref.read(firestoreServiceProvider);
      await firestore.reserveUsername(username);

      // Invalidate to trigger re-fetch → app.dart will switch to main view.
      ref.invalidate(hasUsernameProvider);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _status = 'taken'; // Race condition — someone grabbed it.
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              const KickerLabel('Onboarding'),
              const SizedBox(height: 8),
              Text(
                'Pick a\nusername.',
                style: AppTypography.displayLarge.copyWith(
                  color: AppColors.ink,
                  fontSize: 36,
                  height: 0.9,
                  letterSpacing: -2.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This is how you appear on the commit field and to your crew. Unique, lowercase, 3–20 characters.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.inkFaint,
                  height: 1.55,
                ),
              ),
              const Spacer(flex: 1),
              // Input
              Container(
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  border: Border.all(
                    color: _status == 'available'
                        ? AppColors.mint
                        : _status == 'taken' || _status == 'invalid'
                            ? AppColors.signal
                            : AppColors.lineStrong,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Text(
                      '@',
                      style: AppTypography.displaySmall.copyWith(
                        color: AppColors.inkFaint,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onChanged: _onUsernameChanged,
                        style: AppTypography.heading.copyWith(
                          color: AppColors.ink,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'your_username',
                          hintStyle: AppTypography.heading.copyWith(
                            color: AppColors.inkFaint,
                            fontSize: 16,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                          LengthLimitingTextInputFormatter(20),
                        ],
                        textInputAction: TextInputAction.done,
                        autocorrect: false,
                        enableSuggestions: false,
                      ),
                    ),
                    // Status indicator
                    if (_status == 'checking')
                      const InfiniteSymbolLoader(
                        size: 14,
                        color: AppColors.inkFaint,
                      )
                    else if (_status == 'available')
                      const Text('✓', style: TextStyle(fontSize: 16, color: AppColors.mint))
                    else if (_status == 'taken')
                      const Text('✗', style: TextStyle(fontSize: 16, color: AppColors.signal))
                    else if (_status == 'invalid')
                      const Text('!', style: TextStyle(fontSize: 16, color: AppColors.signal)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Status message
              Text(
                switch (_status) {
                  'checking' => 'Checking availability...',
                  'available' => '@${_controller.text.trim().toLowerCase()} is available.',
                  'taken' => 'That username is already taken.',
                  'invalid' => 'Use 3–20 characters: a–z, 0–9, underscore.',
                  _ => ' ',
                },
                style: TextStyle(
                  fontSize: 9,
                  color: _status == 'available'
                      ? AppColors.mint
                      : _status == 'taken' || _status == 'invalid'
                          ? AppColors.signal
                          : AppColors.inkFaint,
                ),
              ),
              const Spacer(flex: 2),
              // Confirm button
              GestureDetector(
                onTap: (_status == 'available' && !_isSaving) ? _confirm : null,
                child: Container(
                  height: 54,
                  width: double.infinity,
                  color: _status == 'available' ? AppColors.signal : const Color(0xFF2A2D2B),
                  child: _isSaving
                      ? const Center(
                          child: InfiniteSymbolLoader(
                            size: 18,
                            color: Color(0xFF16100D),
                          ),
                        )
                      : Center(
                          child: Text(
                            'LOCK USERNAME',
                            style: AppTypography.heading.copyWith(
                              color: _status == 'available'
                                  ? const Color(0xFF16100D)
                                  : AppColors.inkFaint,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'You can\'t change this later.',
                  style: AppTypography.monoSmall.copyWith(color: AppColors.inkFaint),
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
