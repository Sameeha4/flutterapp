// lib/screens/new_chat_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/friend_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _NewChatScreenState createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final FriendService _friendService = FriendService();

  String get currentUid => _auth.currentUser!.uid;

  Future<void> _sendRequest(String toUid) async {
    try {
      await _friendService.sendFriendRequest(fromUid: currentUid, toUid: toUid);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request sent')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Users')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('users').snapshots(), // no orderBy
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs
              .where((doc) => doc.id != currentUid)
              .toList();

          if (users.isEmpty) {
            return const Center(child: Text('No other users found'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final doc = users[index];
              final uid = doc.id;
              final email = doc['email'] ?? 'No email';

              return ListTile(
                title: Text(email),
                trailing: ElevatedButton(
                  child: const Text('Add'),
                  onPressed: () => _sendRequest(uid),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
