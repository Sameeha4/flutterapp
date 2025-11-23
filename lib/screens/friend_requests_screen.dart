// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/friend_service.dart';
import '../services/firestore_service.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  _FriendRequestsScreenState createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  final _auth = FirebaseAuth.instance;
  final _friendService = FriendService();
  final _fs = FirestoreService(); // to get user email

  String get uid => _auth.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Friend Requests')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _friendService.incomingRequestsStream(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;
          if (requests.isEmpty) return const Center(child: Text('No requests'));

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              final fromUid = req['fromUserId'];

              return FutureBuilder<String>(
                future: _fs.getUserEmail(fromUid),
                builder: (context, emailSnap) {
                  final email = emailSnap.data ?? 'Loading...';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      title: Text(email),
                      subtitle: Text('Status: ${req['status']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () async {
                              try {
                                await _friendService.respondToRequest(
                                  requestId: req.id,
                                  fromUserId: fromUid,
                                  toUserId: uid,
                                  accept: true,
                                );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Friend request accepted'),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () async {
                              try {
                                await _friendService.respondToRequest(
                                  requestId: req.id,
                                  fromUserId: fromUid,
                                  toUserId: uid,
                                  accept: false,
                                );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Friend request rejected'),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
