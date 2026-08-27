import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../../providers/app_providers.dart';
import 'notification_sheet.dart';

/// Reusable Notification Bell icon with dynamic unread dot indicator.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final unreadNotifications = state.notifications
        .where((n) => !(n['read'] as bool? ?? false))
        .toList();
    final hasUnread = unreadNotifications.isNotEmpty || state.requests.isNotEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showNotificationSheet(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.panel,
          border: Border.all(color: AppColors.lineStrong),
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(Icons.notifications_outlined, size: 20, color: AppColors.ink),
            ),
            if (hasUnread)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.signal,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
