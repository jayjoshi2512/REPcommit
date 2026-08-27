import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'shared_widgets.dart';
import '../../providers/app_providers.dart';

/// Show notifications modal sheet.
void showNotificationSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xDD050606),
    builder: (_) => const NotificationSheet(),
  );
}

class NotificationSheet extends ConsumerWidget {
  const NotificationSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final unreadNotifications = state.notifications
        .where((n) => !(n['read'] as bool? ?? false))
        .toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.panel,
        border: Border(top: BorderSide(color: AppColors.signal, width: 2)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const KickerLabel('Unread Activity'),
                  const SizedBox(height: 4),
                  Text(
                    'Social Signals & Nudges',
                    style: AppTypography.displaySmall.copyWith(color: AppColors.ink),
                  ),
                ],
              ),
              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close, color: AppColors.inkFaint, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'UNREAD SIGNALS (${unreadNotifications.length})',
                style: AppTypography.monoSmall.copyWith(color: AppColors.inkFaint, fontWeight: FontWeight.w800),
              ),
              if (unreadNotifications.isNotEmpty)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    await ref.read(firestoreServiceProvider).clearNotifications();
                  },
                  child: Text(
                    'MARK ALL READ',
                    style: AppTypography.monoSmall.copyWith(color: AppColors.signal, fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Notifications List
          if (unreadNotifications.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28),
              width: double.infinity,
              alignment: Alignment.center,
              child: Text(
                'No unread notifications. Signals from your crew will appear here.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.inkFaint, fontSize: 11),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: unreadNotifications.length,
                separatorBuilder: (_, index) => Container(height: 1, color: AppColors.line),
                itemBuilder: (context, i) {
                  final n = unreadNotifications[i];
                  final message = (n['message'] as String?) ?? 'Nudge received!';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.panel3,
                            border: Border.all(color: AppColors.lineStrong),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.notifications_active_outlined, size: 14, color: AppColors.signal),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            message,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.ink, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
        ],
      ),
    );
  }
}
