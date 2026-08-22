import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/daily_stats.dart';
import '../data/services/auth_service.dart';
import '../data/services/firestore_service.dart';
import '../data/services/heatmap_calculator.dart';
import '../data/services/stats_calculator.dart';
import '../data/services/notification_service.dart';

// ── Services (singletons) ─────────────────────────────────────────
final authServiceProvider = Provider((_) => AuthService());
final firestoreServiceProvider = Provider((_) => FirestoreService());
final heatmapCalculatorProvider = Provider((_) => const HeatmapCalculator());
final statsCalculatorProvider = Provider((_) => const StatsCalculator());

/// Whether Firebase was successfully initialized.
bool get _firebaseReady {
  try {
    Firebase.app();
    return true;
  } catch (_) {
    return false;
  }
}

// ── Auth State ────────────────────────────────────────────────────
/// Stream of the current Firebase user — drives auth routing.
/// Returns Stream.empty() if Firebase isn't initialized.
final authStateProvider = StreamProvider<User?>((ref) {
  if (!_firebaseReady) return Stream.value(null);
  return FirebaseAuth.instance.authStateChanges();
});

/// Whether onboarding (username selection) is complete.
final onboardingCompleteProvider = StateProvider<bool>((ref) => false);

/// Check if user has completed onboarding.
final hasUsernameProvider = FutureProvider<bool>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return false;

  final firestore = ref.read(firestoreServiceProvider);
  return firestore.hasUsername();
});

// ── Real-time Data ────────────────────────────────────────────────

/// Stream of ALL daily stats from Firestore.
final dailyStatsStreamProvider = StreamProvider<Map<String, DailyStats>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return const Stream.empty();

  final firestore = ref.read(firestoreServiceProvider);
  return firestore.allDailyStatsStream();
});

/// Stream of today's push logs.
final todayLogsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return const Stream.empty();

  final firestore = ref.read(firestoreServiceProvider);
  return firestore.todayPushLogsStream();
});

/// Stream of user profile.
final userProfileStreamProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return const Stream.empty();

  final firestore = ref.read(firestoreServiceProvider);
  return firestore.userProfileStream();
});

/// Stream of friends.
final friendsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return const Stream.empty();

  final firestore = ref.read(firestoreServiceProvider);
  return firestore.friendsStream();
});

/// Stream of incoming requests.
final requestsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return const Stream.empty();

  final firestore = ref.read(firestoreServiceProvider);
  return firestore.incomingRequestsStream();
});

/// Stream of squads.
final squadsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return const Stream.empty();

  final firestore = ref.read(firestoreServiceProvider);
  return firestore.squadsStream();
});

// ── Derived State ─────────────────────────────────────────────────

/// Today's push-up total derived from daily stats stream.
final todayTotalProvider = Provider<int>((ref) {
  final statsMap = ref.watch(dailyStatsStreamProvider).valueOrNull ?? {};
  final now = DateTime.now();
  final key = _dateKey(now);
  return statsMap[key]?.totalPushUps ?? 0;
});

/// Daily target from user profile.
final dailyTargetProvider = Provider<int>((ref) {
  final profile = ref.watch(userProfileStreamProvider).valueOrNull;
  return (profile?['dailyTarget'] as int?) ?? 60;
});

/// Current streak computed from daily stats.
final currentStreakProvider = Provider<int>((ref) {
  final statsMap = ref.watch(dailyStatsStreamProvider).valueOrNull ?? {};
  return _calculateStreak(statsMap, DateTime.now());
});

/// Best streak ever.
final bestStreakProvider = Provider<int>((ref) {
  final statsMap = ref.watch(dailyStatsStreamProvider).valueOrNull ?? {};
  return _calculateBestStreak(statsMap);
});

/// Username from profile.
final usernameProvider = Provider<String>((ref) {
  final profile = ref.watch(userProfileStreamProvider).valueOrNull;
  return (profile?['username'] as String?) ?? '';
});

// ── App State (unified, for backward compat with screens) ─────────

final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier(ref);
});

class AppState {
  final Map<String, DailyStats> dailyStats;
  final int todayTotal;
  final int dailyTarget;
  final int weeklyGoal;
  final int longTermGoal;
  final int currentStreak;
  final int bestStreak;
  final int bestSetEver;
  final String username;
  final String displayName;
  final String photoUrl;
  final String commitment;
  final List<Map<String, dynamic>> friends;
  final List<Map<String, dynamic>> requests;
  final List<Map<String, dynamic>> squads;
  final Set<String> unlockedAchievements;

  AppState({
    this.dailyStats = const {},
    this.todayTotal = 0,
    this.dailyTarget = 60,
    this.weeklyGoal = 250,
    this.longTermGoal = 5000,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.bestSetEver = 0,
    this.username = '',
    this.displayName = '',
    this.photoUrl = '',
    this.commitment = '20 push-ups before 9 PM',
    this.friends = const [],
    this.requests = const [],
    this.squads = const [],
    this.unlockedAchievements = const {},
  });

  int get todayRemaining => (dailyTarget - todayTotal).clamp(0, 9999);
  double get todayProgress => dailyTarget > 0 ? (todayTotal / dailyTarget).clamp(0.0, 1.0) : 0.0;
  bool get targetReached => todayTotal >= dailyTarget;

  int get thisWeekTotal {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    int total = 0;
    for (var i = 0; i < 7; i++) {
      final date = monday.add(Duration(days: i));
      final dateKey = _dateKey(date);
      total += dailyStats[dateKey]?.totalPushUps ?? 0;
    }
    return total;
  }

  int get allTimeTotal => dailyStats.values.fold<int>(0, (s, d) => s + d.totalPushUps);

  double get weeklyProgress => weeklyGoal > 0 ? (thisWeekTotal / weeklyGoal).clamp(0.0, 1.0) : 0.0;
  double get longTermProgress => longTermGoal > 0 ? (allTimeTotal / longTermGoal).clamp(0.0, 1.0) : 0.0;

  AppState copyWith({
    Map<String, DailyStats>? dailyStats,
    int? todayTotal,
    int? dailyTarget,
    int? weeklyGoal,
    int? longTermGoal,
    int? currentStreak,
    int? bestStreak,
    int? bestSetEver,
    String? username,
    String? displayName,
    String? photoUrl,
    String? commitment,
    List<Map<String, dynamic>>? friends,
    List<Map<String, dynamic>>? requests,
    List<Map<String, dynamic>>? squads,
    Set<String>? unlockedAchievements,
  }) {
    return AppState(
      dailyStats: dailyStats ?? this.dailyStats,
      todayTotal: todayTotal ?? this.todayTotal,
      dailyTarget: dailyTarget ?? this.dailyTarget,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      longTermGoal: longTermGoal ?? this.longTermGoal,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      bestSetEver: bestSetEver ?? this.bestSetEver,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      commitment: commitment ?? this.commitment,
      friends: friends ?? this.friends,
      requests: requests ?? this.requests,
      squads: squads ?? this.squads,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
    );
  }
}

class AppStateNotifier extends StateNotifier<AppState> {
  final Ref _ref;
  final List<void Function()> _unsubs = [];

  AppStateNotifier(this._ref) : super(AppState()) {
    _listenToStreams();
  }

  void _listenToStreams() {
    // Listen to daily stats.
    _unsubs.add(
      _ref.listen(dailyStatsStreamProvider, (prev, next) {
        final stats = next.valueOrNull ?? {};
        final now = DateTime.now();
        final todayKey = _dateKey(now);
        final todayTotal = stats[todayKey]?.totalPushUps ?? 0;

        // Best set from Firestore bestSet field in daily stats.
        int bestSet = 0;
        for (final d in stats.values) {
          if (d.totalPushUps > bestSet) bestSet = d.totalPushUps;
        }

        NotificationService.instance.updateDailyReminder(todayTotal);

        state = state.copyWith(
          dailyStats: stats,
          todayTotal: todayTotal,
          currentStreak: _calculateStreak(stats, now),
          bestStreak: _calculateBestStreak(stats),
          bestSetEver: bestSet,
          unlockedAchievements: _computeAchievements(stats, todayTotal, bestSet),
        );
      }).close,
    );

    // Listen to profile.
    _unsubs.add(
      _ref.listen(userProfileStreamProvider, (prev, next) {
        final profile = next.valueOrNull;
        final currentUser = FirebaseAuth.instance.currentUser;
        final name = (profile?['displayName'] as String?)?.isNotEmpty == true
            ? profile!['displayName'] as String
            : (currentUser?.displayName ?? '');
        final photo = (profile?['photoUrl'] as String?)?.isNotEmpty == true
            ? profile!['photoUrl'] as String
            : (currentUser?.photoURL ?? '');

        if (profile != null) {
          state = state.copyWith(
            dailyTarget: (profile['dailyTarget'] as int?) ?? 60,
            weeklyGoal: (profile['weeklyGoal'] as int?) ?? 250,
            longTermGoal: (profile['longTermGoal'] as int?) ?? 5000,
            username: (profile['username'] as String?) ?? '',
            displayName: name,
            photoUrl: photo,
          );
        } else if (currentUser != null) {
          state = state.copyWith(
            displayName: name,
            photoUrl: photo,
          );
        }
      }).close,
    );

    // Listen to friends.
    _unsubs.add(
      _ref.listen(friendsStreamProvider, (prev, next) {
        state = state.copyWith(friends: next.valueOrNull ?? []);
      }).close,
    );

    // Listen to requests.
    _unsubs.add(
      _ref.listen(requestsStreamProvider, (prev, next) {
        state = state.copyWith(requests: next.valueOrNull ?? []);
      }).close,
    );

    // Listen to squads.
    _unsubs.add(
      _ref.listen(squadsStreamProvider, (prev, next) {
        state = state.copyWith(squads: next.value ?? []);
      }).close,
    );
  }

  /// Update goals in state and Firestore.
  Future<void> updateGoals({int? dailyTarget, int? weeklyGoal, int? longTermGoal}) async {
    state = state.copyWith(
      dailyTarget: dailyTarget,
      weeklyGoal: weeklyGoal,
      longTermGoal: longTermGoal,
    );
    await _ref.read(firestoreServiceProvider).updateGoals(
      dailyTarget: dailyTarget,
      weeklyGoal: weeklyGoal,
      longTermGoal: longTermGoal,
    );
  }

  /// Log push-ups to Firestore.
  Future<void> logPushUps(int count) async {
    final firestore = _ref.read(firestoreServiceProvider);
    await firestore.logPushUps(count);
  }

  /// Cycle commitment.
  void cycleCommitment() {
    const commitments = [
      '20 push-ups before 9 PM',
      'One set after waking up',
      '30 push-ups, any time',
      'Beat yesterday',
      '50 push-ups in 2 sets',
    ];
    final idx = commitments.indexOf(state.commitment);
    state = state.copyWith(
      commitment: commitments[(idx + 1) % commitments.length],
    );
  }

  /// Accept friend request.
  Future<void> acceptRequest(int index) async {
    if (index >= state.requests.length) return;
    final request = state.requests[index];
    final id = request['id'] as String?;
    if (id == null) return;
    final firestore = _ref.read(firestoreServiceProvider);
    await firestore.acceptFriendRequest(id);
  }

  /// Decline friend request.
  Future<void> declineRequest(int index) async {
    if (index >= state.requests.length) return;
    final request = state.requests[index];
    final id = request['id'] as String?;
    if (id == null) return;
    final firestore = _ref.read(firestoreServiceProvider);
    await firestore.removeFriendship(id);
  }

  /// Remove friend.
  Future<void> removeFriend(int index) async {
    if (index >= state.friends.length) return;
    final friend = state.friends[index];
    final id = friend['id'] as String?;
    if (id == null) return;
    final firestore = _ref.read(firestoreServiceProvider);
    await firestore.removeFriendship(id);
  }

  /// Update daily target.
  Future<void> updateTarget(int target) async {
    final firestore = _ref.read(firestoreServiceProvider);
    await firestore.updateGoals(dailyTarget: target);
  }

  /// Sign out.
  Future<void> signOut() async {
    final auth = _ref.read(authServiceProvider);
    await auth.signOut();
  }

  /// Delete all push-up data but keep the account.
  Future<void> deleteAllData() async {
    final firestore = _ref.read(firestoreServiceProvider);
    await firestore.deleteAllData();
  }

  /// Delete the entire account — Firestore data + Auth account.
  Future<void> deleteAccount() async {
    final firestore = _ref.read(firestoreServiceProvider);
    final auth = _ref.read(authServiceProvider);

    // Delete Firestore data first.
    await firestore.deleteAccount();
    // Then delete the Firebase Auth account.
    await auth.deleteAccount();
  }

  Set<String> _computeAchievements(Map<String, DailyStats> stats, int todayTotal, int bestSet) {
    final unlocked = <String>{};
    final totalPushUps = stats.values.fold<int>(0, (s, d) => s + d.totalPushUps);
    final activeDays = stats.values.where((d) => d.totalPushUps > 0).length;
    final bestStreak = _calculateBestStreak(stats);

    if (totalPushUps >= 1) unlocked.add('first_push');
    if (todayTotal >= 100 || stats.values.any((d) => d.totalPushUps >= 100)) unlocked.add('century_club');
    if (todayTotal >= 250 || stats.values.any((d) => d.totalPushUps >= 250)) unlocked.add('day_250');
    if (totalPushUps >= 5000) unlocked.add('total_5000');
    if (totalPushUps >= 10000) unlocked.add('total_10000');
    if (bestStreak >= 7) unlocked.add('streak_7');
    if (bestStreak >= 14) unlocked.add('streak_14');
    if (bestStreak >= 30) unlocked.add('streak_30');
    if (activeDays >= 50) unlocked.add('active_50');
    if (activeDays >= 7) unlocked.add('perfect_week');
    if (activeDays >= 365) unlocked.add('full_field');

    return unlocked;
  }

  @override
  void dispose() {
    for (final unsub in _unsubs) {
      unsub();
    }
    super.dispose();
  }
}

// ── Helper Functions ──────────────────────────────────────────────

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

int _calculateStreak(Map<String, DailyStats> stats, DateTime from) {
  int streak = 0;
  var day = from;

  final todayKey = _dateKey(day);
  if (stats[todayKey] == null || stats[todayKey]!.totalPushUps == 0) {
    day = day.subtract(const Duration(days: 1));
  }

  while (true) {
    final key = _dateKey(day);
    final s = stats[key];
    if (s == null || s.totalPushUps == 0) break;
    streak++;
    day = day.subtract(const Duration(days: 1));
  }

  return streak;
}

int _calculateBestStreak(Map<String, DailyStats> stats) {
  if (stats.isEmpty) return 0;

  final keys = stats.keys.toList()..sort();
  int best = 0;
  int current = 0;

  DateTime? prevDate;
  for (final key in keys) {
    final s = stats[key];
    if (s == null || s.totalPushUps == 0) {
      current = 0;
      prevDate = null;
      continue;
    }

    final date = DateTime.tryParse(key);
    if (date == null) continue;

    if (prevDate != null && date.difference(prevDate).inDays == 1) {
      current++;
    } else {
      current = 1;
    }

    if (current > best) best = current;
    prevDate = date;
  }

  return best;
}
