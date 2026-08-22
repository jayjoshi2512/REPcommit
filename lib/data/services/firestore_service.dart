import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/daily_stats.dart';

/// Firestore data service — all reads/writes for push-ups, stats, profile.
///
/// Collection structure:
///   users/{uid}
///   users/{uid}/pushLogs/{logId}
///   users/{uid}/dailyStats/{YYYY-MM-DD}
///   usernames/{username} → { uid }
///   friendships/{id}
///   squads/{squadId}
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ── User Profile ──────────────────────────────────────────────

  /// Check if a username is available.
  Future<bool> isUsernameAvailable(String username) async {
    final doc = await _db.collection('usernames').doc(username.toLowerCase()).get();
    return !doc.exists;
  }

  /// Reserve a username for the current user.
  Future<void> reserveUsername(String username) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in');

    final cleanName = username.toLowerCase().trim().replaceAll(' ', '');

    // Double-check availability right before writing.
    final existing = await _db.collection('usernames').doc(cleanName).get();
    if (existing.exists) throw Exception('Username taken');

    final batch = _db.batch();
    // Reserve username in the global usernames collection.
    batch.set(_db.collection('usernames').doc(cleanName), {
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Update user doc (merge in case it doesn't exist yet).
    batch.set(_db.collection('users').doc(uid), {
      'username': cleanName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  /// Create or update the user document after sign-in.
  Future<void> createOrUpdateUser(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final doc = await ref.get();

    if (!doc.exists) {
      // First-time user.
      await ref.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'photoUrl': user.photoURL ?? '',
        'username': '', // Set during onboarding.
        'dailyTarget': 60,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
        'settings': {
          'notifications': true,
          'publicProfile': true,
        },
      });
    } else {
      // Returning user — update last active.
      await ref.update({
        'lastActiveAt': FieldValue.serverTimestamp(),
        'displayName': user.displayName ?? doc.data()?['displayName'] ?? '',
        'photoUrl': user.photoURL ?? doc.data()?['photoUrl'] ?? '',
      });
    }
  }

  /// Get user profile data.
  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = _uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  /// Stream user profile for real-time updates.
  Stream<Map<String, dynamic>?> userProfileStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db.collection('users').doc(uid).snapshots().map((s) => s.data());
  }

  /// Check if user has completed onboarding (has a username).
  Future<bool> hasUsername() async {
    final profile = await getUserProfile();
    if (profile == null) return false;
    final username = profile['username'] as String? ?? '';
    return username.isNotEmpty;
  }

  /// Update goals (daily, weekly, long-term).
  Future<void> updateGoals({int? dailyTarget, int? weeklyGoal, int? longTermGoal}) async {
    final uid = _uid;
    if (uid == null) return;
    final updates = <String, dynamic>{};
    if (dailyTarget != null) updates['dailyTarget'] = dailyTarget;
    if (weeklyGoal != null) updates['weeklyGoal'] = weeklyGoal;
    if (longTermGoal != null) updates['longTermGoal'] = longTermGoal;
    if (updates.isNotEmpty) {
      await _db.collection('users').doc(uid).set(updates, SetOptions(merge: true));
    }
  }

  // ── Push Logs ─────────────────────────────────────────────────

  /// Log a push-up set.
  ///
  /// Creates a pushLog document AND updates/creates the dailyStats aggregate.
  Future<void> logPushUps(int count) async {
    final uid = _uid;
    if (uid == null) return;
    final now = DateTime.now();
    final dateKey = _dateKey(now);

    final batch = _db.batch();

    // 1. Create push log.
    final logRef = _db.collection('users').doc(uid).collection('pushLogs').doc();
    batch.set(logRef, {
      'id': logRef.id,
      'count': count,
      'loggedAt': Timestamp.fromDate(now),
      'source': 'manual',
    });

    // 2. Update daily stats (upsert).
    final statsRef = _db.collection('users').doc(uid).collection('dailyStats').doc(dateKey);
    final statsDoc = await statsRef.get();

    if (statsDoc.exists) {
      final data = statsDoc.data()!;
      final currentTotal = (data['totalPushUps'] as int?) ?? 0;
      final currentSetCount = (data['setCount'] as int?) ?? 0;
      final currentBestSet = (data['bestSet'] as int?) ?? 0;

      batch.update(statsRef, {
        'totalPushUps': currentTotal + count,
        'setCount': currentSetCount + 1,
        'bestSet': count > currentBestSet ? count : currentBestSet,
        'lastLogAt': Timestamp.fromDate(now),
      });
    } else {
      batch.set(statsRef, {
        'date': dateKey,
        'totalPushUps': count,
        'setCount': 1,
        'bestSet': count,
        'firstLogAt': Timestamp.fromDate(now),
        'lastLogAt': Timestamp.fromDate(now),
      });
    }

    // 3. Update user's lastActiveAt.
    batch.update(_db.collection('users').doc(uid), {
      'lastActiveAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Stream today's push logs (ordered by time).
  Stream<List<Map<String, dynamic>>> todayPushLogsStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    final dateKey = _dateKey(DateTime.now());

    // Get logs for today.
    final startOfDay = DateTime.parse('$dateKey 00:00:00');
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _db
        .collection('users')
        .doc(uid)
        .collection('pushLogs')
        .where('loggedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('loggedAt', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('loggedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  // ── Daily Stats ───────────────────────────────────────────────

  /// Stream ALL daily stats for the current user.
  Stream<Map<String, DailyStats>> allDailyStatsStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(uid)
        .collection('dailyStats')
        .orderBy('date')
        .snapshots()
        .map((snap) {
      final map = <String, DailyStats>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final date = data['date'] as String;
        final now = DateTime.now();
        map[date] = DailyStats(
          date: date,
          totalPushUps: (data['totalPushUps'] as int?) ?? 0,
          sessionCount: (data['setCount'] as int?) ?? 0,
          firstLoggedAt: (data['firstLogAt'] as Timestamp?)?.toDate(),
          lastLoggedAt: (data['lastLogAt'] as Timestamp?)?.toDate(),
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? now,
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? now,
        );
      }
      return map;
    });
  }

  /// Get daily stats for a specific date.
  Future<DailyStats?> getDailyStats(String dateKey) async {
    final uid = _uid;
    if (uid == null) return null;

    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('dailyStats')
        .doc(dateKey)
        .get();

    if (!doc.exists) return null;
    final data = doc.data()!;
    final now = DateTime.now();
    return DailyStats(
      date: data['date'] as String,
      totalPushUps: (data['totalPushUps'] as int?) ?? 0,
      sessionCount: (data['setCount'] as int?) ?? 0,
      firstLoggedAt: (data['firstLogAt'] as Timestamp?)?.toDate(),
      lastLoggedAt: (data['lastLogAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? now,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? now,
    );
  }

  // ── Friends ───────────────────────────────────────────────────

  /// Send a friend request.
  Future<void> sendFriendRequest(String toUid) async {
    final uid = _uid;
    if (uid == null) return;

    await _db.collection('friendships').add({
      'fromUid': uid,
      'toUid': toUid,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Accept a friend request.
  Future<void> acceptFriendRequest(String friendshipId) async {
    await _db.collection('friendships').doc(friendshipId).update({
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Decline/remove a friendship.
  Future<void> removeFriendship(String friendshipId) async {
    await _db.collection('friendships').doc(friendshipId).delete();
  }

  /// Stream incoming friend requests with populated user profiles.
  Stream<List<Map<String, dynamic>>> incomingRequestsStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();

    return _db
        .collection('friendships')
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .asyncMap((snap) async {
      final list = <Map<String, dynamic>>[];
      for (final d in snap.docs) {
        final data = d.data();
        final fromUid = data['fromUid'] as String?;
        Map<String, dynamic>? senderProfile;
        if (fromUid != null && fromUid.isNotEmpty) {
          final senderDoc = await _db.collection('users').doc(fromUid).get();
          senderProfile = senderDoc.data();
        }
        list.add({
          'id': d.id,
          ...data,
          'fromUid': fromUid ?? '',
          'username': senderProfile?['username'] as String? ?? '',
          'displayName': senderProfile?['displayName'] as String? ?? '',
          'photoUrl': senderProfile?['photoUrl'] as String? ?? '',
        });
      }
      return list;
    });
  }

  /// Stream accepted friends with populated user profiles and today's stats.
  Stream<List<Map<String, dynamic>>> friendsStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();

    final now = DateTime.now();
    final todayKey = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    return _db
        .collection('friendships')
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .asyncMap((snap) async {
      final list = <Map<String, dynamic>>[];
      final matchedDocs = snap.docs.where((d) {
        final data = d.data();
        return data['fromUid'] == uid || data['toUid'] == uid;
      });

      for (final d in matchedDocs) {
        final data = d.data();
        final friendUid = (data['fromUid'] == uid ? data['toUid'] : data['fromUid']) as String?;
        if (friendUid == null || friendUid.isEmpty) continue;

        final userDoc = await _db.collection('users').doc(friendUid).get();
        final userData = userDoc.data() ?? {};

        // Fetch friend's today stats
        final todayStatsDoc = await _db
            .collection('users')
            .doc(friendUid)
            .collection('dailyStats')
            .doc(todayKey)
            .get();
        final todayPushUps = (todayStatsDoc.data()?['totalPushUps'] as int?) ?? 0;

        final lastActive = userData['lastActiveAt'] as Timestamp?;
        final isOnline = lastActive != null &&
            now.difference(lastActive.toDate()).inMinutes < 15;

        list.add({
          'id': d.id,
          'uid': friendUid,
          ...data,
          'username': userData['username'] as String? ?? '',
          'displayName': userData['displayName'] as String? ?? '',
          'photoUrl': userData['photoUrl'] as String? ?? '',
          'isOnline': isOnline,
          'todayPushUps': todayPushUps,
          'streak': (userData['currentStreak'] as int?) ?? (todayPushUps > 0 ? 1 : 0),
        });
      }
      return list;
    });
  }

  /// Look up a user by username or email address.
  Future<Map<String, dynamic>?> findUserByUsernameOrEmail(String query) async {
    final clean = query.trim().toLowerCase().replaceFirst('@', '');
    if (clean.isEmpty) return null;

    // 1. Search by username mapping first
    final usernameDoc = await _db.collection('usernames').doc(clean).get();
    if (usernameDoc.exists) {
      final targetUid = usernameDoc.data()?['uid'] as String?;
      if (targetUid != null) {
        final userDoc = await _db.collection('users').doc(targetUid).get();
        if (userDoc.exists) return userDoc.data();
      }
    }

    // 2. Search by email address in users collection
    final emailSnap = await _db
        .collection('users')
        .where('email', isEqualTo: query.trim().toLowerCase())
        .limit(1)
        .get();
    if (emailSnap.docs.isNotEmpty) {
      return emailSnap.docs.first.data();
    }

    // 3. Search by username directly in users collection
    final usernameSnap = await _db
        .collection('users')
        .where('username', isEqualTo: clean)
        .limit(1)
        .get();
    if (usernameSnap.docs.isNotEmpty) {
      return usernameSnap.docs.first.data();
    }

    return null;
  }

  /// Backward-compatible alias for username lookup.
  Future<Map<String, dynamic>?> findUserByUsername(String username) =>
      findUserByUsernameOrEmail(username);

  // ── Squads ────────────────────────────────────────────────────

  /// Create a new squad in Firestore.
  Future<void> createSquad({
    required String name,
    required String description,
    required int target,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    final docRef = _db.collection('squads').doc();
    await docRef.set({
      'id': docRef.id,
      'name': name,
      'description': description,
      'target': target,
      'progress': 0,
      'members': [uid],
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Join an existing squad.
  Future<void> joinSquad(String squadId) async {
    final uid = _uid;
    if (uid == null) return;

    await _db.collection('squads').doc(squadId).update({
      'members': FieldValue.arrayUnion([uid]),
    });
  }

  /// Leave a squad.
  Future<void> leaveSquad(String squadId) async {
    final uid = _uid;
    if (uid == null) return;

    await _db.collection('squads').doc(squadId).update({
      'members': FieldValue.arrayRemove([uid]),
    });
  }

  /// Stream all squads.
  Stream<List<Map<String, dynamic>>> squadsStream() {
    return _db.collection('squads').snapshots().map((snap) {
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    });
  }

  // ── Danger Zone ──────────────────────────────────────────────

  /// Delete all push-up data (logs + daily stats) but keep the account.
  Future<void> deleteAllData() async {
    final uid = _uid;
    if (uid == null) return;

    final batch = _db.batch();

    // Delete all push logs.
    final logs = await _db
        .collection('users')
        .doc(uid)
        .collection('pushLogs')
        .get();
    for (final doc in logs.docs) {
      batch.delete(doc.reference);
    }

    // Delete all daily stats.
    final stats = await _db
        .collection('users')
        .doc(uid)
        .collection('dailyStats')
        .get();
    for (final doc in stats.docs) {
      batch.delete(doc.reference);
    }

    // Reset user doc counters.
    batch.update(_db.collection('users').doc(uid), {
      'totalPushUps': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Delete user account entirely — all data, username, user doc.
  Future<void> deleteAccount() async {
    final uid = _uid;
    if (uid == null) return;

    // Get username to unreserve it.
    final userDoc = await _db.collection('users').doc(uid).get();
    final username = userDoc.data()?['username'] as String?;

    final batch = _db.batch();

    // Delete push logs.
    final logs = await _db
        .collection('users')
        .doc(uid)
        .collection('pushLogs')
        .get();
    for (final doc in logs.docs) {
      batch.delete(doc.reference);
    }

    // Delete daily stats.
    final stats = await _db
        .collection('users')
        .doc(uid)
        .collection('dailyStats')
        .get();
    for (final doc in stats.docs) {
      batch.delete(doc.reference);
    }

    // Delete friendships.
    final friendships = await _db
        .collection('friendships')
        .where('fromUid', isEqualTo: uid)
        .get();
    for (final doc in friendships.docs) {
      batch.delete(doc.reference);
    }
    final friendships2 = await _db
        .collection('friendships')
        .where('toUid', isEqualTo: uid)
        .get();
    for (final doc in friendships2.docs) {
      batch.delete(doc.reference);
    }

    // Delete username reservation.
    if (username != null && username.isNotEmpty) {
      batch.delete(_db.collection('usernames').doc(username));
    }

    // Delete user doc.
    batch.delete(_db.collection('users').doc(uid));

    await batch.commit();
  }

  // ── Helpers ───────────────────────────────────────────────────

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
