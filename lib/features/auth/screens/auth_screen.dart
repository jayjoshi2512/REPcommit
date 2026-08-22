import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../providers/app_providers.dart';

/// Auth screen — Google Sign-In landing.
///
/// Matches the prototype's intro/landing aesthetic: dark bg, brand mark,
/// tagline, single sign-in CTA.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoading = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final credential = await authService.signInWithGoogle();
      if (credential == null) {
        // User cancelled.
        setState(() => _isLoading = false);
        return;
      }

      // Create/update Firestore user doc.
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.createOrUpdateUser(credential.user!);

      // Auth state stream will automatically route to onboarding or home.
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Sign-in failed. Please try again.';
      });
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
            children: [
              const Spacer(flex: 3),
              // Brand
              const BrandMark(size: 48),
              const SizedBox(height: 18),
              Text(
                'RepCommit',
                style: AppTypography.displayLarge.copyWith(
                  color: AppColors.ink,
                  fontSize: 36,
                  letterSpacing: -2.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getGreeting(),
                style: AppTypography.title.copyWith(
                  color: AppColors.inkDim,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              // Tagline
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.line),
                    bottom: BorderSide(color: AppColors.line),
                  ),
                ),
                child: Text(
                  'A personal push-up tracker inspired by\nGitHub contribution history.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.inkFaint,
                    height: 1.6,
                  ),
                ),
              ),
              const Spacer(flex: 2),
              // Error
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.signal),
                    color: const Color(0xFF1E1411),
                  ),
                  child: Row(
                    children: [
                      const Text('⚠', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(fontSize: 10, color: AppColors.ink),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // Sign in button
              GestureDetector(
                onTap: _isLoading ? null : _signIn,
                child: Container(
                  height: 54,
                  width: double.infinity,
                  color: AppColors.signal,
                  child: _isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF16100D),
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google "G" icon
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'G',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF4285F4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'SIGN IN WITH GOOGLE',
                              style: AppTypography.heading.copyWith(
                                color: const Color(0xFF16100D),
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your push-ups. Your record. Nothing else.',
                style: AppTypography.monoSmall.copyWith(color: AppColors.inkFaint),
              ),
              const Spacer(flex: 1),
              // Footer
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'NO PENALTY · NO SHAME · JUST SIGNAL',
                  style: AppTypography.mono.copyWith(
                    color: AppColors.inkFaint,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _getGreeting() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) {
    return 'Good morning.';
  } else if (hour >= 12 && hour < 17) {
    return 'Good noon.';
  } else if (hour >= 17 && hour < 22) {
    return 'Good evening.';
  } else {
    return 'Late night.';
  }
}
