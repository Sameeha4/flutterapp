import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import 'package:flutter/foundation.dart'; // for debugPrint, kDebugMode

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Save user document (call after registration)
  Future<void> saveUser(String uid, String name, String email) async {
    try {
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) debugPrint("✅ User saved to Firestore: $uid");
    } catch (e) {
      if (kDebugMode) debugPrint("❌ Error saving user: $e");
      rethrow;
    }
  }

  /// Search user by exact email
  Future<List<Map<String, dynamic>>> searchUserByEmail(String email) async {
    try {
      final snap = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      return snap.docs.map((d) => {...d.data(), 'uid': d.id}).toList();
    } catch (e) {
      if (kDebugMode) debugPrint("❌ Error searching user: $e");
      return [];
    }
  }

  /// Return user email by UID
  Future<String> getUserEmail(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.exists ? (doc.data()?['email'] ?? 'Unknown') : 'Unknown';
    } catch (e) {
      if (kDebugMode) debugPrint("❌ Error getting user email: $e");
      return 'Unknown';
    }
  }

  /// Get or create chat between two users (returns chatId)
  Future<String> getOrCreateChat(String currentUid, String otherUid) async {
    if (currentUid.isEmpty || otherUid.isEmpty) {
      throw Exception('UIDs cannot be empty');
    }

    try {
      // look for existing chat
      final q = await _db
          .collection('chats')
          .where('users', arrayContains: currentUid)
          .get();

      for (final doc in q.docs) {
        final users = List<String>.from(doc['users'] ?? []);
        if (users.contains(otherUid)) return doc.id; // existing chat
      }

      // create new chat
      final newChatRef = await _db.collection('chats').add({
        'users': [currentUid, otherUid],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) debugPrint("✅ New chat created: ${newChatRef.id}");
      return newChatRef.id;
    } catch (e) {
      if (kDebugMode) debugPrint("❌ Error in getOrCreateChat: $e");
      rethrow;
    }
  }

  /// Send a message
  Future<void> sendMessage(String chatId, MessageModel message) async {
    try {
      final messagesRef = _db
          .collection('chats')
          .doc(chatId)
          .collection('messages');
      await messagesRef.add(message.toMap());

      // update parent chat
      await _db.collection('chats').doc(chatId).update({
        'lastMessage': message.text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) debugPrint("✅ Message sent in chat: $chatId");
    } catch (e) {
      if (kDebugMode) debugPrint("❌ Error sending message: $e");
      rethrow;
    }
  }

  /// Stream chats for current user
  Stream<List<ChatModel>> getChats(String myUid) {
    try {
      return _db
          .collection('chats')
          .where('users', arrayContains: myUid)
          .orderBy('lastMessageTime', descending: true)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((d) => ChatModel.fromMap(d.id, d.data()))
                .toList(),
          );
    } catch (e) {
      if (kDebugMode) debugPrint("❌ Error streaming chats: $e");
      return const Stream.empty();
    }
  }

  /// Stream messages for a chat
  Stream<List<MessageModel>> getMessages(String chatId) {
    try {
      return _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp')
          .snapshots()
          .map(
            (snap) =>
                snap.docs.map((d) => MessageModel.fromMap(d.data())).toList(),
          );
    } catch (e) {
      if (kDebugMode) debugPrint("❌ Error streaming messages: $e");
      return const Stream.empty();
    }
  }
}
