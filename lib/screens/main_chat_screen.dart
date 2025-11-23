// lib/screens/main_chat_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/chat_model.dart';
import '../widgets/chat_tile.dart';
import 'chat_screen.dart';
import 'new_chat_screen.dart';
import 'friend_requests_screen.dart';
import 'search_user_screen.dart'; // Import your SearchUserScreen

class MainChatScreen extends StatefulWidget {
  const MainChatScreen({super.key});

  @override
  State<MainChatScreen> createState() => _MainChatScreenState();
}

class _MainChatScreenState extends State<MainChatScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _userResults = [];
  bool _loading = false;

  final _auth = AuthService();
  final _fs = FirestoreService();

  Future<void> _searchUsers(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _userResults = []);
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await _fs.searchUserByEmail(q.trim());
      setState(() => _userResults = res);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Search error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(25),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) {
              setState(() => _searchQuery = v.toLowerCase());
              _searchUsers(v);
            },
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: "Search users or messages",
              icon: Icon(Icons.search),
            ),
          ),
        ),
      ),

      body: me == null
          ? const Center(child: Text("Not logged in"))
          : _searchQuery.isNotEmpty
          ? _buildUserSearchResults(me)
          : _buildChatsList(me),

      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Person button → New Chat
          FloatingActionButton(
            heroTag: "person_btn",
            mini: true,
            child: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewChatScreen()),
              );
            },
          ),
          const SizedBox(height: 10),

          // Notification button → Friend Requests
          FloatingActionButton(
            heroTag: "noti_btn",
            mini: true,
            child: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FriendRequestsScreen()),
              );
            },
          ),
          const SizedBox(height: 10),

          // Plus button → Search Users
          FloatingActionButton(
            heroTag: "search_btn",
            mini: true,
            child: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchUserScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // ------------------ USER SEARCH RESULTS ------------------
  Widget _buildUserSearchResults(me) {
    if (_loading) return const LinearProgressIndicator();
    if (_userResults.isEmpty) {
      return const Center(child: Text("No users found"));
    }

    return ListView.separated(
      itemCount: _userResults.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, i) {
        final u = _userResults[i];
        final isMe = me.uid == u['uid'];

        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(u['email'] ?? 'Unknown'),
          subtitle: Text(isMe ? 'This is you' : 'Tap to chat'),
          enabled: !isMe,
          onTap: isMe
              ? null
              : () async {
                  final chatId = await _fs.getOrCreateChat(me.uid, u['uid']);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ChatScreen(chatId: chatId, otherUid: u['uid']),
                    ),
                  );
                },
        );
      },
    );
  }

  // ------------------ CHATS LIST ------------------
  Widget _buildChatsList(me) {
    return StreamBuilder<List<ChatModel>>(
      stream: _fs.getChats(me.uid),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        List<ChatModel> chats = snap.data!;

        if (chats.isEmpty) return const Center(child: Text("No chats found."));

        return ListView.separated(
          itemCount: chats.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final chat = chats[i];
            final otherUid = chat.users.firstWhere((u) => u != me.uid);

            return FutureBuilder<String>(
              future: _fs.getUserEmail(otherUid),
              builder: (context, esnap) {
                final email = esnap.data ?? "Loading…";
                return ChatTile(
                  chatId: chat.chatId,
                  otherEmail: email,
                  lastMessage: chat.lastMessage,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ChatScreen(chatId: chat.chatId, otherUid: otherUid),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
