import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../providers/app_providers.dart';

/// Crew screen with tabbed Friends / Squads / Requests.
class CrewScreen extends ConsumerStatefulWidget {
  const CrewScreen({super.key});

  @override
  ConsumerState<CrewScreen> createState() => _CrewScreenState();
}

class _CrewScreenState extends ConsumerState<CrewScreen> {
  int _activeTab = 0; // 0=Friends, 1=Squads, 2=Requests
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
                      const KickerLabel('Social'),
                      const SizedBox(height: 4),
                      Text(
                        'Your crew, clearly.',
                        style: AppTypography.title.copyWith(color: AppColors.ink),
                      ),
                    ],
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.panel,
                      border: Border.all(color: AppColors.line),
                    ),
                    child: const Center(
                      child: Text('⌁', style: TextStyle(fontSize: 16, color: AppColors.ink)),
                    ),
                  ),
                ],
              ),
            ),
            // Summary bar
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.line),
                  bottom: BorderSide(color: AppColors.line),
                ),
              ),
              child: Row(
                children: [
                  _SummaryCell(value: '${state.friends.length}', label: 'friends'),
                  _SummaryCell(value: '${state.squads.length}', label: 'squads'),
                  _SummaryCell(value: '${state.requests.length}', label: 'requests', isLast: true),
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
                  _TabButton(label: 'Friends', isActive: _activeTab == 0, onTap: () => setState(() => _activeTab = 0)),
                  _TabButton(label: 'Squads', isActive: _activeTab == 1, onTap: () => setState(() => _activeTab = 1)),
                  _TabButton(label: 'Requests', isActive: _activeTab == 2, onTap: () => setState(() => _activeTab = 2), isLast: true),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 102),
                child: switch (_activeTab) {
                  0 => _FriendsPanel(
                      state: state,
                      searchController: _searchController,
                      onCompare: (i) => setState(() => _compareIndex = i),
                      onSearchChanged: () => setState(() {}),
                    ),
                  1 => _SquadsPanel(state: state),
                  2 => _RequestsPanel(state: state, ref: ref),
                  _ => const SizedBox.shrink(),
                },
              ),
            ),
          ],
        ),
        // Compare overlay
        if (_compareIndex != null)
          _ComparePanel(
            state: state,
            friendIndex: _compareIndex!,
            onClose: () => setState(() => _compareIndex = null),
          ),
      ],
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String value;
  final String label;
  final bool isLast;
  const _SummaryCell({required this.value, required this.label, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(right: BorderSide(color: AppColors.line)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTypography.statLarge.copyWith(color: AppColors.ink, fontSize: 19)),
            const SizedBox(height: 2),
            Text(label, style: AppTypography.monoSmall.copyWith(color: AppColors.inkFaint)),
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
  const _TabButton({required this.label, required this.isActive, required this.onTap, this.isLast = false});

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

// ── Friends Panel ───────────────────────────────────────────────
class _FriendsPanel extends ConsumerStatefulWidget {
  final AppState state;
  final TextEditingController searchController;
  final void Function(int) onCompare;
  final VoidCallback onSearchChanged;

  const _FriendsPanel({
    required this.state,
    required this.searchController,
    required this.onCompare,
    required this.onSearchChanged,
  });

  @override
  ConsumerState<_FriendsPanel> createState() => _FriendsPanelState();
}

class _FriendsPanelState extends ConsumerState<_FriendsPanel> {
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
    final user = await firestore.findUserByUsername(cleanQuery);

    if (mounted && _lastQuery == cleanQuery) {
      setState(() {
        _isSearching = false;
        if (user != null && (user['username'] as String?)?.toLowerCase() == cleanQuery) {
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
    final query = widget.searchController.text.trim().toLowerCase().replaceFirst('@', '');
    final visible = widget.state.friends.asMap().entries
        .where((e) => query.isEmpty || ((e.value['username'] as String?) ?? '').toLowerCase().contains(query))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Friends', style: AppTypography.titleSmall.copyWith(color: AppColors.ink)),
            const SizedBox(height: 3),
            Text(
              'People you trust to keep showing up.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.inkFaint),
            ),
          ],
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
                    hintText: 'Search username to add friend...',
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
              'Checking username @$query in Firestore...',
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@${_searchedUser!['username']}',
                        style: AppTypography.heading.copyWith(color: AppColors.ink, fontSize: 15),
                      ),
                      if ((_searchedUser!['displayName'] as String?)?.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Text(
                          _searchedUser!['displayName'] as String,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.inkFaint),
                        ),
                      ],
                      const SizedBox(height: 3),
                      Text(
                        'Verified user found',
                        style: AppTypography.monoSmall.copyWith(color: AppColors.mint, fontSize: 10),
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

        // Friend list
        if (visible.isEmpty && query.isNotEmpty && !_searchedUserNotFound && !_isSearching && _searchedUser == null)
          _SearchEmpty(query: query)
        else if (visible.isEmpty && query.isEmpty)
          const EmptyState(message: 'Your crew starts with one person.')
        else
          ...visible.map((entry) => _FriendCard(
                friend: entry.value,
                index: entry.key,
                ref: ref,
                onCompare: () => widget.onCompare(entry.key),
              )),
      ],
    );
  }
}

class _FriendCard extends StatelessWidget {
  final Map<String, dynamic> friend;
  final int index;
  final WidgetRef ref;
  final VoidCallback onCompare;

  const _FriendCard({
    required this.friend,
    required this.index,
    required this.ref,
    required this.onCompare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.panel3,
                  border: Border.all(color: AppColors.lineStrong),
                ),
                alignment: Alignment.center,
                child: Text(
                  ((friend['username'] as String?) ?? '?')[0].toUpperCase(),
                  style: AppTypography.mono.copyWith(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 9),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('@${(friend['username'] as String?) ?? ''}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    const SizedBox(height: 3),
                    Text(
                      '${(friend['isOnline'] as bool? ?? false) ? 'pushing today' : 'last active yesterday'} · ${(friend['streak'] as int?) ?? 0} day line',
                      style: TextStyle(fontSize: 8, color: AppColors.inkFaint),
                    ),
                  ],
                ),
              ),
              Text(
                '${(friend['todayPushUps'] as int?) ?? 0} push-ups',
                style: AppTypography.mono.copyWith(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 39),
              GestureDetector(
                onTap: onCompare,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.signal)),
                  child: Text('COMPARE', style: AppTypography.mono.copyWith(color: AppColors.signal, fontWeight: FontWeight.w800, fontSize: 7)),
                ),
              ),
              const SizedBox(width: 5),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Nudge sent to @${(friend['username'] as String?) ?? ''}')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
                  child: Text('NUDGE', style: AppTypography.mono.copyWith(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 7)),
                ),
              ),
              const SizedBox(width: 5),
              GestureDetector(
                onTap: () {
                  ref.read(appStateProvider.notifier).removeFriend(index);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.line)),
                  child: Text('REMOVE', style: AppTypography.mono.copyWith(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 7)),
                ),
              ),
            ],
          ),
        ],
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
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Friend request sent to @$query')),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              decoration: BoxDecoration(border: Border.all(color: AppColors.signal)),
              child: Text('+ ADD @$query', style: AppTypography.mono.copyWith(color: AppColors.signal, fontWeight: FontWeight.w900, fontSize: 7)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Squads Panel ────────────────────────────────────────────────
class _SquadsPanel extends ConsumerWidget {
  final AppState state;
  const _SquadsPanel({required this.state});

  void _showCreateSquadModal(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final targetController = TextEditingController(text: '1000');
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.panel,
            border: Border(top: BorderSide(color: AppColors.signal, width: 2)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CREATE A NEW SQUAD',
                style: AppTypography.heading.copyWith(color: AppColors.ink, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Gather your crew and tackle a shared push-up goal together.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.inkFaint, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                autofocus: true,
                style: AppTypography.body.copyWith(color: AppColors.ink, fontSize: 14),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Squad Name (e.g., 1000 Push-Up Challenge)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                style: AppTypography.body.copyWith(color: AppColors.ink, fontSize: 14),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Target Push-ups (e.g., 1000)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: AppTypography.body.copyWith(color: AppColors.ink, fontSize: 14),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Description / Motto',
                ),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () async {
                  final name = nameController.text.trim();
                  final desc = descController.text.trim();
                  final target = int.tryParse(targetController.text) ?? 1000;
                  if (name.isNotEmpty) {
                    await ref.read(firestoreServiceProvider).createSquad(
                      name: name,
                      description: desc,
                      target: target,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Squad "$name" created!')),
                      );
                    }
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.signal,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: AppColors.lineStrong),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'CREATE SQUAD',
                    style: AppTypography.heading.copyWith(
                      color: const Color(0xFF150D08),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Squads', style: AppTypography.titleSmall.copyWith(color: AppColors.ink, fontSize: 16)),
                const SizedBox(height: 3),
                Text(
                  'Shared goals, shared contribution field.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.inkFaint, fontSize: 11),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => _showCreateSquadModal(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.signal,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: AppColors.lineStrong),
                ),
                child: Text(
                  '+ CREATE SQUAD',
                  style: AppTypography.mono.copyWith(
                    color: const Color(0xFF150D08),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (state.squads.isEmpty)
          const EmptyState(
            message: 'No active squads yet. Create one to challenge your friends!',
          )
        else
          ...state.squads.map((squad) => _SquadCard(squad: squad, ref: ref)),
      ],
    );
  }
}

class _SquadCard extends StatelessWidget {
  final Map<String, dynamic> squad;
  final WidgetRef ref;

  const _SquadCard({required this.squad, required this.ref});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final squadId = (squad['id'] as String?) ?? '';
    final squadTarget = (squad['target'] as int?) ?? 1000;
    final squadProgress = (squad['progress'] as int?) ?? 0;
    final squadName = (squad['name'] as String?) ?? 'Squad';
    final squadDesc = (squad['description'] as String?) ?? '';
    final membersList = (squad['members'] as List<dynamic>?)?.cast<String>() ?? [];
    final isMember = uid != null && membersList.contains(uid);
    final progress = squadTarget > 0 ? (squadProgress / squadTarget).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.lineStrong),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      squadName,
                      style: AppTypography.heading.copyWith(color: AppColors.ink, fontSize: 16),
                    ),
                    if (squadDesc.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        squadDesc,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.inkFaint, fontSize: 11),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${membersList.length} members',
                      style: AppTypography.monoSmall.copyWith(color: AppColors.signal, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Text(
                '$squadProgress / $squadTarget',
                style: AppTypography.mono.copyWith(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          Container(
            height: 6,
            color: const Color(0xFF242824),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(color: AppColors.mint),
            ),
          ),
          const SizedBox(height: 12),
          // Action button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).round()}% complete',
                style: AppTypography.monoSmall.copyWith(color: AppColors.inkFaint, fontSize: 11),
              ),
              GestureDetector(
                onTap: () async {
                  final firestore = ref.read(firestoreServiceProvider);
                  if (isMember) {
                    await firestore.leaveSquad(squadId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Left $squadName')),
                      );
                    }
                  } else {
                    await firestore.joinSquad(squadId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Joined $squadName!')),
                      );
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isMember ? AppColors.panel3 : AppColors.signal,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: AppColors.lineStrong),
                  ),
                  child: Text(
                    isMember ? 'LEAVE SQUAD' : 'JOIN SQUAD',
                    style: AppTypography.mono.copyWith(
                      color: isMember ? AppColors.ink : const Color(0xFF150D08),
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Requests', style: AppTypography.titleSmall.copyWith(color: AppColors.ink)),
                const SizedBox(height: 2),
                Text('People asking to connect with you.',
                    style: TextStyle(fontSize: 8, color: AppColors.inkFaint)),
              ],
            ),
            KickerLabel('${state.requests.length}'),
          ],
        ),
        const SizedBox(height: 10),
        if (state.requests.isEmpty)
          const EmptyState(message: 'Your inbox is clear.')
        else
          ...state.requests.asMap().entries.map((entry) =>
              _RequestCard(request: entry.value, index: entry.key, ref: ref)),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final int index;
  final WidgetRef ref;
  const _RequestCard({required this.request, required this.index, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.panel3,
              border: Border.all(color: AppColors.lineStrong),
            ),
            alignment: Alignment.center,
            child: Text(((request['username'] as String?) ?? '?')[0].toUpperCase(), style: AppTypography.mono.copyWith(color: AppColors.ink, fontWeight: FontWeight.w900, fontSize: 9)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@${(request['username'] as String?) ?? ''}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const SizedBox(height: 3),
                Text((request['message'] as String?) ?? 'Wants to join your crew', style: TextStyle(fontSize: 8, color: AppColors.inkFaint)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => ref.read(appStateProvider.notifier).acceptRequest(index),
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              color: AppColors.mint,
              alignment: Alignment.center,
              child: Text('Accept', style: AppTypography.mono.copyWith(
                color: const Color(0xFF101513), fontWeight: FontWeight.w800, fontSize: 8,
              )),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => ref.read(appStateProvider.notifier).declineRequest(index),
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(border: Border.all(color: AppColors.lineStrong)),
              alignment: Alignment.center,
              child: Text('×', style: TextStyle(color: AppColors.inkFaint)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Compare Panel ───────────────────────────────────────────────
class _ComparePanel extends StatelessWidget {
  final AppState state;
  final int friendIndex;
  final VoidCallback onClose;
  const _ComparePanel({required this.state, required this.friendIndex, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final friend = state.friends[friendIndex];
    final youScore = state.todayTotal;
    final friendPushUps = (friend['todayPushUps'] as int?) ?? 0;
    final friendUsername = (friend['username'] as String?) ?? '';
    final lead = youScore > friendPushUps
        ? 'You are ahead today.'
        : youScore < friendPushUps
            ? '@$friendUsername is ahead today.'
            : 'You are even today.';

    return Positioned.fill(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 58, 12, 58),
        decoration: BoxDecoration(
          color: AppColors.panel,
          border: Border.all(color: AppColors.lineStrong),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.line)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Compare with @$friendUsername', style: AppTypography.heading.copyWith(color: AppColors.ink, fontSize: 15)),
                    GestureDetector(
                      onTap: onClose,
                      child: Text('×', style: TextStyle(fontSize: 18, color: AppColors.inkFaint)),
                    ),
                  ],
                ),
              ),
              // Score grid
              Row(
                children: [
                  _CompareCol(name: 'YOU', score: youScore),
                  _CompareCol(name: '@$friendUsername', score: friendPushUps, hasBorder: true),
                ],
              ),
              // Stat rows
              _CompareStatRow(
                youLabel: '${state.currentStreak}d', youSub: 'current line',
                otherLabel: '${(friend['streak'] as int?) ?? 0}d', otherSub: 'current line',
              ),
              _CompareStatRow(
                youLabel: '${state.bestSetEver}', youSub: 'best set',
                otherLabel: '${(friendPushUps + 12).clamp(20, 99)}', otherSub: 'best set',
              ),
              // Conclusion
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  border: Border(left: BorderSide(color: AppColors.mint, width: 2)),
                  color: AppColors.panel2,
                ),
                child: Text(
                  '$lead Compare volume here, then tap into the Squad if you want to turn the rivalry into a shared goal.',
                  style: TextStyle(fontSize: 8, height: 1.45, color: AppColors.inkDim),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompareCol extends StatelessWidget {
  final String name;
  final int score;
  final bool hasBorder;
  const _CompareCol({required this.name, required this.score, this.hasBorder = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border(
            bottom: const BorderSide(color: AppColors.line),
            left: hasBorder ? const BorderSide(color: AppColors.line) : BorderSide.none,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: AppTypography.mono.copyWith(color: AppColors.inkFaint, fontWeight: FontWeight.w900, fontSize: 10)),
            const SizedBox(height: 5),
            Text('$score', style: AppTypography.displaySmall.copyWith(color: AppColors.ink, fontSize: 26)),
            const SizedBox(height: 2),
            Text('PUSH-UPS TODAY', style: AppTypography.monoSmall.copyWith(color: AppColors.inkFaint)),
          ],
        ),
      ),
    );
  }
}

class _CompareStatRow extends StatelessWidget {
  final String youLabel;
  final String youSub;
  final String otherLabel;
  final String otherSub;
  const _CompareStatRow({required this.youLabel, required this.youSub, required this.otherLabel, required this.otherSub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(child: _CompareStat(label: youLabel, sub: youSub)),
          const SizedBox(width: 8),
          Expanded(child: _CompareStat(label: otherLabel, sub: otherSub)),
        ],
      ),
    );
  }
}

class _CompareStat extends StatelessWidget {
  final String label;
  final String sub;
  const _CompareStat({required this.label, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      color: AppColors.panel2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.heading.copyWith(color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(sub.toUpperCase(), style: AppTypography.monoSmall.copyWith(color: AppColors.inkFaint)),
        ],
      ),
    );
  }
}
