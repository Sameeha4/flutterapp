// ignore_for_file: use_build_context_synchronously, unnecessary_to_list_in_spreads
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({super.key});

  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final _ctrl = TextEditingController();
  final _fs = FirestoreService();
  final _auth = AuthService();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    try {
      final res = await _fs.searchUserByEmail(q.trim());

      final me = _auth.currentUser;
      // Separate logged-in user
      final otherUsers = res.where((u) => u['uid'] != me?.uid).toList();

      setState(() {
        _results = otherUsers;
      });
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
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Search user')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: 'Enter email or number',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _search(_ctrl.text),
                ),
              ),
              onSubmitted: _search,
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child: ListView(
                children: [
                  // Show logged-in user at top
                  if (me != null)
                    ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(me.email ?? 'You'),
                      subtitle: const Text('This is you'),
                      enabled: false,
                    ),

                  // Then show other users
                  ..._results.map((u) {
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(u['email'] ?? 'Unknown'),
                      subtitle: const Text('Tap to chat'),
                      onTap: () async {
                        final chatId = await _fs.getOrCreateChat(
                          me!.uid,
                          u['uid'],
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ChatScreen(chatId: chatId, otherUid: u['uid']),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
