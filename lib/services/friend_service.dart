import 'package:cloud_firestore/cloud_firestore.dart';

class FriendService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final CollectionReference _users = FirebaseFirestore.instance.collection(
    'users',
  );
  final CollectionReference _requests = FirebaseFirestore.instance.collection(
    'friend_requests',
  );

  /// Send a friend request
  Future<void> sendFriendRequest({
    required String fromUid,
    required String toUid,
  }) async {
    if (fromUid == toUid) throw Exception("Can't send request to yourself");

    final fromDoc = await _users.doc(fromUid).get();
    final fromData = fromDoc.data() as Map<String, dynamic>? ?? {};
    final friends = fromData['friends'] != null
        ? List<String>.from(fromData['friends'])
        : <String>[];

    if (friends.contains(toUid)) throw Exception("You are already friends");

    // Check pending requests
    final pending = await hasPendingRequestBetween(fromUid, toUid);
    if (pending) throw Exception("Friend request already pending");

    await _requests.add({
      'fromUserId': fromUid,
      'toUserId': toUid,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Stream incoming requests for a user
  Stream<QuerySnapshot> incomingRequestsStream(String uid) {
    return _requests
        .where('toUserId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Accept or reject a friend request
  Future<void> respondToRequest({
    required String requestId,
    required String fromUserId,
    required String toUserId,
    required bool accept,
  }) async {
    final requestRef = _requests.doc(requestId);
    final fromRef = _users.doc(fromUserId);
    final toRef = _users.doc(toUserId);

    await _db.runTransaction((tx) async {
      // 1️⃣ READS first
      final requestSnap = await tx.get(requestRef);
      if (!requestSnap.exists) throw Exception('Request not found');

      if (accept) {
        final fromSnap = await tx.get(fromRef);
        final toSnap = await tx.get(toRef);

        if (!fromSnap.exists || !toSnap.exists) {
          throw Exception('User document missing');
        }

        // Ensure friends arrays exist

        // 2️⃣ WRITES after all reads
        tx.update(fromRef, {
          'friends': FieldValue.arrayUnion([toUserId]),
        });
        tx.update(toRef, {
          'friends': FieldValue.arrayUnion([fromUserId]),
        });
      }

      // Finally, update the request status
      tx.update(requestRef, {'status': accept ? 'accepted' : 'rejected'});
    });
  }

  /// Check if a pending request exists between two users
  Future<bool> hasPendingRequestBetween(String a, String b) async {
    final q1 = await _requests
        .where('fromUserId', isEqualTo: a)
        .where('toUserId', isEqualTo: b)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (q1.docs.isNotEmpty) return true;

    final q2 = await _requests
        .where('fromUserId', isEqualTo: b)
        .where('toUserId', isEqualTo: a)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    return q2.docs.isNotEmpty;
  }

  /// Get list of friend UIDs for a user safely
  Future<List<String>> getFriends(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return [];
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return data['friends'] != null ? List<String>.from(data['friends']) : [];
  }
}
