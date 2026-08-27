import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../core/widgets/exercise_filter_bar.dart';
import '../../../core/widgets/notification_bell.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../data/models/exercise.dart';
import '../../../providers/app_providers.dart';

/// Crew screen with Friends Leaderboard / Friend Requests.
class CrewScreen extends ConsumerStatefulWidget {
  const CrewScreen({super.key});

  @override
  ConsumerState<CrewScreen> createState() => _CrewScreenState();
}

class _CrewScreenState extends ConsumerState<CrewScreen> {
  int _activeTab = 0; // 0=Leaderboard/Friends, 1=Requests
  final _searchController = TextEditingController();
  int? _compareIndex;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);

    return Stack(
      children: [
        Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 11),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const KickerLabel('Social & Competition'),
                      const SizedBox(height: 4),
                      Text(
                        'Your crew, clearly.',
                        style: AppTypography.title.copyWith(color: AppColors.ink),
                      ),
                    ],
                  ),
                  const NotificationBell(),
                ],
              ),
            ),
            // Structured summary cards
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'LEADERBOARD',
                      value: '${state.friends.length + 1}',
                      icon: Icons.leaderboard_outlined,
                      isActive: _activeTab == 0,
                      onTap: () => setState(() => _activeTab = 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryCard(
                      label: 'REQUESTS',
                      value: '${state.requests.length}',
                      icon: Icons.inbox_outlined,
                      badgeCount: state.requests.length,
                      isActive: _activeTab == 1,
                      onTap: () => setState(() => _activeTab = 1),
                    ),
                  ),
                ],
              ),
            ),
            // Tab bar
            Container(
              decoration: BoxDecoration(
                color: AppColors.panel,
                border: Border.all(color: AppColors.line),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _TabButton(
                    label: 'Leaderboard',
                    isActive: _activeTab == 0,
                    onTap: () => setState(() => _activeTab = 0),
                  ),
                  _TabButton(
                    label: 'Requests',
                    isActive: _activeTab == 1,
                    onTap: () => setState(() => _activeTab = 1),
                    isLast: true,
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 102),
                child: switch (_activeTab) {
                  0 => _FriendsLeaderboardPanel(
                      state: state,
                      searchController: _searchController,
                      onCompare: (i) => setState(() => _compareIndex = i),
                      onSearchChanged: () => setState(() {}),
                    ),
                  1 => _RequestsPanel(state: state, ref: ref),
                  _ => const SizedBox.shrink(),
                },
              ),
            ),
          ],
        ),
        // Compare overlay
        if (_compareIndex != null && _compareIndex! < state.friends.length)
          _ComparePanel(
            state: state,
            friendIndex: _compareIndex!,
            onClose: () => setState(() => _compareIndex = null),
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isActive;
  final int badgeCount;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.isActive,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
        decoration: BoxDecoration(
          color: AppColors.panel,
          border: Border.all(
            color: AppColors.lineStrong,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: AppTypography.monoTiny.copyWith(
                    color: AppColors.inkFaint,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    fontSize: 9,
                  ),
                ),
                Stack(
                  children: [
                    Icon(
                      icon,
                      size: 14,
                      color: AppColors.inkFaint,
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: AppColors.signal,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTypography.statLarge.copyWith(
                color: AppColors.ink,
                fontSize: 22,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isLast;
  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF151817) : Colors.transparent,
            border: Border(
              right: isLast ? BorderSide.none : const BorderSide(color: AppColors.line),
              bottom: isActive ? const BorderSide(color: AppColors.signal, width: 2) : BorderSide.none,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label.toUpperCase(),
            style: AppTypography.mono.copyWith(
              color: isActive ? AppColors.ink : AppColors.inkFaint,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Friends Leaderboard Panel ───────────────────────────────────
class _FriendsLeaderboardPanel extends ConsumerStatefulWidget {
  final AppState state;
  final TextEditingController searchController;
  final void Function(int) onCompare;
  final VoidCallback onSearchChanged;

  const _FriendsLeaderboardPanel({
    required this.state,
    required this.searchController,
    required this.onCompare,
    required this.onSearchChanged,
  });

  @override
  ConsumerState<_FriendsLeaderboardPanel> createState() => _FriendsLeaderboardPanelState();
}

class _FriendsLeaderboardPanelState extends ConsumerState<_FriendsLeaderboardPanel> {
  bool _isSearching = false;
  Map<String, dynamic>? _searchedUser;
  bool _searchedUserNotFound = false;
  String _lastQuery = '';

  Future<void> _performSearch(String query) async {
    final cleanQuery = query.trim().toLowerCase().replaceFirst('@', '');
    if (cleanQuery.isEmpty) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchedUser = null;
          _searchedUserNotFound = false;
          _lastQuery = '';
        });
      }
      return;
    }

    _lastQuery = cleanQuery;

    final firestore = ref.read(firestoreServiceProvider);
    final user = await firestore.findUserByUsernameOrEmail(cleanQuery);

    if (mounted && _lastQuery == cleanQuery) {
      setState(() {
        _isSearching = false;
        if (user != null) {
          _searchedUser = user;
          _searchedUserNotFound = false;
        } else {
          _searchedUser = null;
          _searchedUserNotFound = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedFilter = ref.watch(selectedExerciseFilterProvider);
    final exDef = selectedFilter == 'all'
        ? ExerciseDef.pushups
        : ExerciseDef.fromId(selectedFilter);

    final query = widget.searchController.text.trim().toLowerCase().replaceFirst('@', '');
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final username = widget.state.username.isEmpty ? 'you' : widget.state.username;
    final now = DateTime.now();
    final todayKey = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final myExTotals = widget.state.dailyStats[todayKey]?.exerciseTotals ?? {'pushups': widget.state.todayTotal};

    // Helper to get count for selected exercise
    int getExerciseCount(Map<String, dynamic> item, String exId) {
      final totals = item['exerciseTotals'] as Map? ?? {};
      if (totals.containsKey(exId)) {
        return (totals[exId] as int?) ?? 0;
      }
      if (exId == 'pushups') {
        return (item['todayPushUps'] as int?) ?? 0;
      }
      return 0;
    }

    // Create leaderboard list combining user and friends
    final leaderboard = <Map<String, dynamic>>[];

    // Add current user
    leaderboard.add({
      'uid': currentUserUid,
      'username': username,
      'displayName': widget.state.displayName,
      'todayPushUps': widget.state.todayTotal,
      'exerciseTotals': myExTotals,
      'streak': widget.state.currentStreak,
      'isOnline': true,
      'isSelf': true,
      'originalIndex': -1,
    });

    // Add friends
    for (var i = 0; i < widget.state.friends.length; i++) {
      final f = widget.state.friends[i];
      final fExTotals = Map<String, dynamic>.from(f['exerciseTotals'] as Map? ?? {});
      final fPush = (f['todayPushUps'] as int?) ?? 0;
      if (!fExTotals.containsKey('pushups') && fPush > 0) {
        fExTotals['pushups'] = fPush;
      }

      leaderboard.add({
        'uid': f['uid'] ?? '',
        'id': f['id'] ?? '',
        'username': f['username'] ?? '',
        'displayName': f['displayName'] ?? '',
        'todayPushUps': fPush,
        'exerciseTotals': fExTotals,
        'streak': (f['streak'] as int?) ?? 0,
        'isOnline': (f['isOnline'] as bool?) ?? false,
        'isSelf': false,
        'originalIndex': i,
      });
    }

    // Sort leaderboard by selected exercise count descending, then streak descending
    leaderboard.sort((a, b) {
      final countA = getExerciseCount(a, exDef.id);
      final countB = getExerciseCount(b, exDef.id);
      if (countB != countA) return countB.compareTo(countA);
      final streakA = (a['streak'] as int);
      final streakB = (b['streak'] as int);
      return streakB.compareTo(streakA);
    });

    // Filter by search query if non-empty
    final filteredLeaderboard = leaderboard.where((entry) {
      if (query.isEmpty) return true;
      final uname = (entry['username'] as String).toLowerCase();
      return uname.contains(query);
    }).toList();

    // Dynamically collect exercise keys logged by any crew member or enabled by current user
    final userEnabledIds = ref.watch(userEnabledExercisesProvider);
    final crewExIdsSet = <String>{...userEnabledIds};
    for (final item in leaderboard) {
      final totals = item['exerciseTotals'] as Map? ?? {};
      for (final entry in totals.entries) {
        final k = entry.key.toString();
        final v = entry.value as int? ?? 0;
        if (k.isNotEmpty && v > 0) {
          crewExIdsSet.add(k);
        }
      }
    }
    final crewExerciseIds = crewExIdsSet.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Leaderboard', style: AppTypography.titleSmall.copyWith(color: AppColors.ink)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: AppColors.signal.withValues(alpha: 0.2),
                  child: Text(
                    "TODAY'S RANKINGS",
                    style: AppTypography.monoSmall.copyWith(
                      color: AppColors.signal,
                      fontWeight: FontWeight.w900,
                      fontSize: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              'Friends and crew ranked by today\'s ${exDef.name.toLowerCase()} commitment.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.inkFaint),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Exercise Filter Bar (Dynamically fetched crew exercise tabs)
        ExerciseFilterBar(
          mode: ExerciseFilterBarMode.all,
          customExerciseIds: crewExerciseIds,
        ),
        const SizedBox(height: 10),

        // Search bar
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.panel,
            border: Border.all(color: AppColors.lineStrong),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.search, size: 18, color: AppColors.inkFaint),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: widget.searchController,
                  onChanged: (val) {
                    widget.onSearchChanged();
                    final clean = val.trim().toLowerCase().replaceFirst('@', '');
                    setState(() {
                      _searchedUser = null;
                      _searchedUserNotFound = false;
                      _isSearching = clean.isNotEmpty;
                    });
                    _performSearch(val);
                  },
                  style: AppTypography.body.copyWith(color: AppColors.ink, fontSize: 13),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search username or email to add friend...',
                    hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.inkFaint, fontSize: 13),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (widget.searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    widget.searchController.clear();
                    widget.onSearchChanged();
                    setState(() {
                      _searchedUser = null;
                      _searchedUserNotFound = false;
                      _lastQuery = '';
                    });
                  },
                  child: const Icon(Icons.close, size: 16, color: AppColors.inkFaint),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Verified Search Result Card
        if (_isSearching)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Checking username or email in Firestore...',
              style: AppTypography.bodySmall.copyWith(color: AppColors.signal),
            ),
          )
        else if (_searchedUser != null)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.panel2,
              border: Border.all(color: AppColors.signal),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.panel,
                    border: Border.all(color: AppColors.lineStrong),
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: (_searchedUser!['photoUrl'] as String?)?.isNotEmpty == true
                      ? Image.network(_searchedUser!['photoUrl'] as String, fit: BoxFit.cover)
                      : Center(
                          child: Text(
                            ((_searchedUser!['displayName'] as String?)?.isNotEmpty == true
                                    ? (_searchedUser!['displayName'] as String)[0]
                                    : (_searchedUser!['username'] as String? ?? 'U')[0])
                                .toUpperCase(),
                            style: AppTypography.heading.copyWith(color: AppColors.ink, fontSize: 16),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (_searchedUser!['displayName'] as String?)?.isNotEmpty == true
                            ? _searchedUser!['displayName'] as String
                            : '@${_searchedUser!['username']}',
                        style: AppTypography.heading.copyWith(color: AppColors.ink, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${_searchedUser!['username'] ?? ''}',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.inkFaint),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.signal,
                    foregroundColor: const Color(0xFF160D09),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: const RoundedRectangleBorder(),
                  ),
                  onPressed: () async {
                    final targetUid = _searchedUser!['uid'] as String?;
                    if (targetUid != null) {
                      try {
                        await ref.read(firestoreServiceProvider).sendFriendRequest(targetUid);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Friend request sent to @${_searchedUser!['username']}')),
                          );
                          setState(() {
                            _searchedUser = null;
                            widget.searchController.clear();
                          });
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppErrorHandler.toFriendlyMessage(e))),
                          );
                        }
                      }
                    }
                  },
                  child: Text(
                    '+ ADD FRIEND',
                    style: AppTypography.mono.copyWith(fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
              ],
            ),
          )
        else if (_searchedUserNotFound && query.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No registered user found with username "@$query"',
              style: AppTypography.bodySmall.copyWith(color: AppColors.inkFaint, fontSize: 12),
            ),
          ),

        // Leaderboard List
        if (filteredLeaderboard.isEmpty && query.isNotEmpty)
          _SearchEmpty(query: query)
        else
          ...filteredLeaderboard.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final item = entry.value;
            final count = getExerciseCount(item, exDef.id);
            return _LeaderboardCard(
              rank: rank,
              item: item,
              exDef: exDef,
              activeCount: count,
              ref: ref,
              onCompare: () {
                final orig = item['originalIndex'] as int;
                if (orig >= 0) widget.onCompare(orig);
              },
            );
          }),
      ],
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> item;
  final ExerciseDef exDef;
  final int activeCount;
  final WidgetRef ref;
  final VoidCallback onCompare;

  const _LeaderboardCard({
    required this.rank,
    required this.item,
    required this.exDef,
    required this.activeCount,
    required this.ref,
    required this.onCompare,
  });

  @override
  Widget build(BuildContext context) {
    final isSelf = (item['isSelf'] as bool?) ?? false;
    final username = (item['username'] as String?) ?? '';
    final streak = (item['streak'] as int?) ?? 0;
    final isOnline = (item['isOnline'] as bool?) ?? false;

    // Rank styling
    final (rankColor, rankLabel) = switch (rank) {
      1 => (const Color(0xFFFFD700), '#1 👑'),
      2 => (const Color(0xFFC0C0C0), '#2'),
      3 => (const Color(0xFFCD7F32), '#3'),
      _ => (AppColors.inkFaint, '#$rank'),
    };

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onCompare,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelf ? const Color(0xFF1B1816) : AppColors.panel,
          border: Border.all(
            color: isSelf ? AppColors.signal : (rank == 1 ? const Color(0xFFFFD700) : AppColors.lineStrong),
            width: isSelf || rank == 1 ? 1.5 : 1.0,
          ),
        ),
      child: Column(
        children: [
          Row(
            children: [
              // Rank badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: rankColor.withValues(alpha: 0.15),
                  border: Border.all(color: rankColor),
                ),
                alignment: Alignment.center,
                child: Text(
                  rankLabel,
                  style: AppTypography.monoSmall.copyWith(
                    color: rankColor,
                    fontWeight: FontWeight.w900,
                    fontSize: rank == 1 ? 11 : 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '@$username',
                            style: AppTypography.heading.copyWith(
                              color: isSelf ? AppColors.signal : AppColors.ink,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelf) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            color: AppColors.signal,
                            child: Text(
                              'YOU',
                              style: AppTypography.monoTiny.copyWith(
                                color: const Color(0xFF160D09),
                                fontWeight: FontWeight.w900,
                                fontSize: 7,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${isOnline ? 'active today' : 'last seen recently'} · $streak day line',
                      style: TextStyle(fontSize: 8, color: AppColors.inkFaint),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Dynamic Exercise Stat readout
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$activeCount',
                    style: AppTypography.statLarge.copyWith(
                      color: activeCount > 0 ? exDef.color : AppColors.inkFaint,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    exDef.name.toUpperCase(),
                    style: AppTypography.monoSmall.copyWith(
                      color: AppColors.inkFaint,
                      fontSize: 7,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Actions row (for friends)
          if (!isSelf) ...[
            const SizedBox(height: 8),
            Container(height: 1, color: AppColors.line),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: onCompare,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.signal)),
                    child: Text(
                      'COMPARE',
                      style: AppTypography.mono.copyWith(
                        color: AppColors.signal,
                        fontWeight: FontWeight.w800,
                        fontSize: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () async {
                    final targetUid = (item['uid'] as String?) ?? '';
                    try {
                      await ref.read(firestoreServiceProvider).sendNudge(targetUid, username);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Nudge sent to @$username!')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppErrorHandler.toFriendlyMessage(e))),
                        );
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.panel2,
                      border: Border.all(color: AppColors.lineStrong),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active_outlined, size: 10, color: AppColors.ink),
                        const SizedBox(width: 4),
                        Text(
                          'NUDGE',
                          style: AppTypography.mono.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    final origIndex = item['originalIndex'] as int;
                    if (origIndex >= 0) {
                      ref.read(appStateProvider.notifier).removeFriend(origIndex);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
                    child: Text(
                      'REMOVE',
                      style: AppTypography.mono.copyWith(
                        color: AppColors.inkFaint,
                        fontWeight: FontWeight.w800,
                        fontSize: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}
}

class _SearchEmpty extends StatelessWidget {
  final String query;
  const _SearchEmpty({required this.query});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 10),
      child: Column(
        children: [
          Text('No friend found', style: AppTypography.heading.copyWith(color: AppColors.ink, fontSize: 11)),
          const SizedBox(height: 5),
          Text('Nothing matches "@$query".', style: TextStyle(fontSize: 8, color: AppColors.inkFaint)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Requests Panel ──────────────────────────────────────────────
class _RequestsPanel extends StatelessWidget {
  final AppState state;
  final WidgetRef ref;
  const _RequestsPanel({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    final count = state.requests.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const KickerLabel('Social Connections'),
                const SizedBox(height: 4),
                Text(
                  'Incoming Requests',
                  style: AppTypography.titleSmall.copyWith(color: AppColors.ink),
                ),
              ],
            ),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.signal.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.signal),
                ),
                child: Text(
                  '$count PENDING',
                  style: AppTypography.monoSmall.copyWith(
                    color: AppColors.signal,
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Workout partners requesting to connect with your commitment stream.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.inkFaint, fontSize: 11),
        ),
        const SizedBox(height: 14),

        if (count == 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.panel,
              border: Border.all(color: AppColors.lineStrong),
            ),
            child: Column(
              children: [
                const Icon(Icons.inbox_outlined, size: 32, color: AppColors.inkFaint),
                const SizedBox(height: 10),
                Text(
                  'NO PENDING REQUESTS',
                  style: AppTypography.mono.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'When partners search your handle or send connection invites, they will appear here.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.inkFaint, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: count,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, idx) {
              final req = state.requests[idx];
              final username = (req['username'] as String?) ?? 'user';
              final displayName = (req['displayName'] as String?) ?? '';
              final initial = username.isNotEmpty ? username[0].toUpperCase() : 'U';

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  border: Border.all(color: AppColors.lineStrong),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.panel3,
                            border: Border.all(color: AppColors.lineStrong),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initial,
                            style: AppTypography.heading.copyWith(
                              color: AppColors.signal,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '@$username',
                                style: AppTypography.heading.copyWith(
                                  color: AppColors.ink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (displayName.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  displayName,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.inkFaint,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 2),
                              Text(
                                'Pending connection request',
                                style: AppTypography.monoTiny.copyWith(
                                  color: AppColors.signal,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => ref.read(appStateProvider.notifier).acceptRequest(idx),
                            child: Container(
                              height: 36,
                              color: AppColors.signal,
                              alignment: Alignment.center,
                              child: Text(
                                'ACCEPT CONNECTION',
                                style: AppTypography.mono.copyWith(
                                  color: const Color(0xFF160D09),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => ref.read(appStateProvider.notifier).declineRequest(idx),
                            child: Container(
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.panel2,
                                border: Border.all(color: AppColors.lineStrong),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'DECLINE',
                                style: AppTypography.mono.copyWith(
                                  color: AppColors.inkFaint,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

// ── Compare Panel Overlay & Detailed Exercise Breakdown ─────────
class _ComparePanel extends ConsumerWidget {
  final AppState state;
  final int friendIndex;
  final VoidCallback onClose;

  const _ComparePanel({
    required this.state,
    required this.friendIndex,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friend = state.friends[friendIndex];
    final friendUid = (friend['uid'] as String?) ?? '';
    final friendUsername = (friend['username'] as String?) ?? 'friend';
    final friendDisplayName = (friend['displayName'] as String?) ?? '';
    final friendPushUps = (friend['todayPushUps'] as int?) ?? 0;
    final friendStreak = (friend['streak'] as int?) ?? 0;
    final friendExTotals = Map<String, int>.from(friend['exerciseTotals'] as Map? ?? {});
    if (!friendExTotals.containsKey('pushups') && friendPushUps > 0) {
      friendExTotals['pushups'] = friendPushUps;
    }

    final myUsername = state.username.isEmpty ? 'you' : state.username;
    final myPushUps = state.todayTotal;
    final myStreak = state.currentStreak;
    final now = DateTime.now();
    final todayKey = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final myExTotals = state.dailyStats[todayKey]?.exerciseTotals ?? {'pushups': myPushUps};

    // Combine all exercise keys logged by both users today
    final allExerciseKeys = <String>{...myExTotals.keys, ...friendExTotals.keys}.toList();
    if (allExerciseKeys.isEmpty) {
      allExerciseKeys.addAll(['pushups', 'pullups', 'squats']);
    }

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: const Color(0xDC050606),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: () {}, // Prevent tap close when clicking inside card
          child: Container(
            color: AppColors.panel,
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CREW COMPARISON & BREAKDOWN',
                              style: AppTypography.monoSmall.copyWith(
                                color: AppColors.signal,
                                fontWeight: FontWeight.w900,
                                fontSize: 9,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              friendDisplayName.isNotEmpty ? friendDisplayName : '@$friendUsername',
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@$friendUsername',
                              style: AppTypography.monoSmall.copyWith(
                                color: AppColors.inkFaint,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.close, color: AppColors.inkFaint, size: 20),
                        onPressed: onClose,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Side by Side Summary Card
                  Row(
                    children: [
                      Expanded(
                        child: _CompareColumn(
                          username: '@$myUsername',
                          totalReps: myExTotals.values.fold(0, (sum, v) => sum + v),
                          streak: myStreak,
                          isWinner: myPushUps >= friendPushUps,
                          isSelf: true,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        color: AppColors.signal,
                        child: Text(
                          'VS',
                          style: AppTypography.monoTiny.copyWith(
                            color: const Color(0xFF160D09),
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _CompareColumn(
                          username: '@$friendUsername',
                          totalReps: friendExTotals.values.fold(0, (sum, v) => sum + v),
                          streak: friendStreak,
                          isWinner: friendPushUps > myPushUps,
                          isSelf: false,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  Text(
                    'TODAY\'S EXERCISE BREAKDOWN',
                    style: AppTypography.monoSmall.copyWith(
                      color: AppColors.inkFaint,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Detailed Exercise Table
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.panel3,
                      border: Border.all(color: AppColors.lineStrong),
                    ),
                    child: Column(
                      children: [
                        // Table Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          color: AppColors.panel,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'EXERCISE',
                                  style: AppTypography.monoTiny.copyWith(
                                    color: AppColors.inkFaint,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '@$myUsername',
                                  style: AppTypography.monoTiny.copyWith(
                                    color: AppColors.signal,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 9,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '@$friendUsername',
                                  style: AppTypography.monoTiny.copyWith(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 9,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: AppColors.line),
                        ...allExerciseKeys.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final exId = entry.value;
                          final exName = exId == 'pushups'
                              ? 'Push-ups'
                              : (exId == 'pullups'
                                  ? 'Pull-ups'
                                  : (exId == 'squats' ? 'Squats' : exId[0].toUpperCase() + exId.substring(1)));
                          final myVal = myExTotals[exId] ?? 0;
                          final friendVal = friendExTotals[exId] ?? 0;

                          return Container(
                            color: idx % 2 == 1 ? AppColors.panel.withValues(alpha: 0.4) : Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    exName,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                                    decoration: BoxDecoration(
                                      color: myVal > 0 ? AppColors.signal.withValues(alpha: 0.12) : AppColors.panel,
                                      border: Border.all(
                                        color: myVal > 0 ? AppColors.signal : AppColors.line,
                                      ),
                                    ),
                                    child: Text(
                                      '$myVal',
                                      style: AppTypography.mono.copyWith(
                                        color: myVal > 0 ? AppColors.signal : AppColors.inkFaint,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                                    decoration: BoxDecoration(
                                      color: friendVal > 0 ? AppColors.panel2 : AppColors.panel,
                                      border: Border.all(
                                        color: friendVal > 0 ? AppColors.ink : AppColors.line,
                                      ),
                                    ),
                                    child: Text(
                                      '$friendVal',
                                      style: AppTypography.mono.copyWith(
                                        color: friendVal > 0 ? AppColors.ink : AppColors.inkFaint,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  // Nudge Action Button
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      try {
                        await ref.read(firestoreServiceProvider).sendNudge(friendUid, friendUsername);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Nudge sent to @$friendUsername!')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppErrorHandler.toFriendlyMessage(e))),
                          );
                        }
                      }
                    },
                    child: Container(
                      height: 44,
                      color: AppColors.signal,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.notifications_active_outlined, size: 16, color: Color(0xFF160D09)),
                          const SizedBox(width: 6),
                          Text(
                            'SEND INSTANT NUDGE ⚡',
                            style: AppTypography.mono.copyWith(
                              color: const Color(0xFF160D09),
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompareColumn extends StatelessWidget {
  final String username;
  final int totalReps;
  final int streak;
  final bool isWinner;
  final bool isSelf;

  const _CompareColumn({
    required this.username,
    required this.totalReps,
    required this.streak,
    required this.isWinner,
    required this.isSelf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isSelf ? AppColors.panel : AppColors.panel2,
        border: Border.all(
          color: isWinner ? AppColors.signal : AppColors.lineStrong,
          width: isWinner ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            username,
            style: AppTypography.heading.copyWith(
              color: isSelf ? AppColors.signal : AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            '$totalReps',
            style: AppTypography.statLarge.copyWith(
              color: isWinner ? AppColors.signal : AppColors.inkFaint,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'REPS TODAY',
            style: AppTypography.monoTiny.copyWith(
              color: AppColors.inkFaint,
              fontSize: 8,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '🔥 $streak-day streak',
            style: AppTypography.monoSmall.copyWith(
              color: isWinner ? AppColors.signal : AppColors.inkFaint,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
