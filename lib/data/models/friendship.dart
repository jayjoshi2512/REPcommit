/// Friendship relationship model.
///
/// Tracks bidirectional friend connections with status transitions.
class Friendship {
  final String id;
  final String requesterId;
  final String receiverId;
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const Friendship({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  factory Friendship.fromMap(Map<String, dynamic> map) {
    return Friendship(
      id: map['id'] as String? ?? '',
      requesterId: map['requesterId'] as String? ?? '',
      receiverId: map['receiverId'] as String? ?? '',
      status: FriendshipStatus.fromString(map['status'] as String? ?? 'pending'),
      createdAt: _parseTimestamp(map['createdAt']),
      respondedAt: _tryParse(map['respondedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requesterId': requesterId,
      'receiverId': receiverId,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
    };
  }

  /// Returns the uid of the "other" user relative to [myUid].
  String otherUserId(String myUid) {
    return requesterId == myUid ? receiverId : requesterId;
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  static DateTime? _tryParse(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

enum FriendshipStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  removed('removed');

  const FriendshipStatus(this.value);
  final String value;

  static FriendshipStatus fromString(String s) {
    return FriendshipStatus.values.firstWhere(
      (e) => e.value == s,
      orElse: () => FriendshipStatus.pending,
    );
  }
}
