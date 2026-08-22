import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../features/push_logger/widgets/push_logger_sheet.dart';

/// Bottom navigation bar matching the prototype's 5-column layout.
///
/// Today | Signal | [Push] | Crew | Profile
///
/// The center "Push" button opens the push logger sheet.
class BottomNav extends StatelessWidget {
  const BottomNav({super.key});

  static const _tabs = [
    _NavTab(path: '/today', label: 'TODAY', icon: Icons.home_outlined, activeIcon: Icons.home),
    _NavTab(path: '/signal', label: 'SIGNAL', icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart),
    _NavTab(path: '', label: 'PUSH', icon: Icons.add, activeIcon: Icons.add), // center
    _NavTab(path: '/crew', label: 'CREW', icon: Icons.people_outline, activeIcon: Icons.people),
    _NavTab(path: '/profile', label: 'PROFILE', icon: Icons.person_outline, activeIcon: Icons.person),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/today')) return 0;
    if (location.startsWith('/signal')) return 1;
    if (location.startsWith('/crew')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Container(
      margin: const EdgeInsets.all(10),
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF111312),
        border: Border.all(color: AppColors.lineStrong, width: 1),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final tab = _tabs[i];

          // Center push button.
          if (i == 2) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: GestureDetector(
                  onTap: () => _openPushLogger(context),
                  child: Container(
                    height: 50,
                    color: AppColors.signal,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(tab.icon, size: 18, color: const Color(0xFF16100D)),
                        const SizedBox(height: 4),
                        Text(
                          tab.label,
                          style: AppTypography.navLabel.copyWith(
                            color: const Color(0xFF16100D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          final isActive = currentIndex == i;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                final nav = Navigator.of(context, rootNavigator: true);
                while (nav.canPop()) {
                  nav.pop();
                }
                if (!isActive) context.go(tab.path);
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isActive ? tab.activeIcon : tab.icon,
                    size: 16,
                    color: isActive ? AppColors.ink : AppColors.inkFaint,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tab.label,
                    style: AppTypography.navLabel.copyWith(
                      color: isActive ? AppColors.ink : AppColors.inkFaint,
                    ),
                  ),
                  if (isActive)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 15,
                      height: 2,
                      color: AppColors.signal,
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  void _openPushLogger(BuildContext context) {
    HapticFeedback.mediumImpact();
    final nav = Navigator.of(context, rootNavigator: true);
    while (nav.canPop()) {
      nav.pop();
    }
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xC7050606),
      builder: (_) => const PushLoggerSheet(),
    );
  }
}

class _NavTab {
  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavTab({
    required this.path,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
