import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'bottom_nav.dart';

/// Root scaffold that wraps all tabbed screens.
///
/// Provides the persistent bottom navigation bar and manages
/// the push logger trigger from the center nav button.
class AppScaffold extends StatelessWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(child: child),
      extendBody: true,
      bottomNavigationBar: const BottomNav(),
    );
  }
}
