// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/message_model.dart';
import '../widgets/message_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUid;

  const ChatScreen({super.key, required this.chatId, required this.otherUid});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _fs = FirestoreService();
  final _auth = AuthService();
  final _ctrl = TextEditingController();
  final _scrollController = ScrollController();

  String otherEmail = "";

  @override
  void initState() {
    super.initState();
    _loadOtherUserEmail();
  }

  Future<void> _loadOtherUserEmail() async {
    final snap = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.otherUid)
        .get();

    if (snap.exists) {
      setState(() {
        otherEmail = snap.data()?["email"] ?? "User";
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    DateTime today = DateTime.now();
    DateTime yesterday = today.subtract(const Duration(days: 1));

    if (DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(today)) {
      return "Today";
    } else if (DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(yesterday)) {
      return "Yesterday";
    } else {
      return DateFormat('d MMM yyyy').format(date);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.white, // Chat background is now white
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          otherEmail.isEmpty ? "Chat" : otherEmail,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: _fs.getMessages(widget.chatId),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snap.data ?? [];
                  if (messages.isEmpty) {
                    return const Center(
                      child: Text("No messages yet. Say hi!"),
                    );
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final m = messages[i];
                      final msgDate = DateTime(
                        m.timestamp.year,
                        m.timestamp.month,
                        m.timestamp.day,
                      );

                      bool showDateHeader = false;
                      if (i == 0) {
                        showDateHeader = true;
                      } else {
                        final prev = messages[i - 1];
                        final prevDate = DateTime(
                          prev.timestamp.year,
                          prev.timestamp.month,
                          prev.timestamp.day,
                        );
                        if (msgDate != prevDate) showDateHeader = true;
                      }

                      final isMe = me != null && me.uid == m.senderId;

                      return Column(
                        children: [
                          if (showDateHeader)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _formatDate(m.timestamp),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          MessageBubble(
                            isMe: isMe,
                            text: m.text,
                            time: DateFormat('hh:mm a').format(m.timestamp),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            // MESSAGE INPUT
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: "Message...",
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: () async {
                      final text = _ctrl.text.trim();
                      final meUser = _auth.currentUser;
                      if (text.isEmpty || meUser == null) return;

                      final msg = MessageModel(
                        senderId: meUser.uid,
                        text: text,
                        timestamp: DateTime.now(),
                      );

                      try {
                        await _fs.sendMessage(widget.chatId, msg);
                        _ctrl.clear();
                        _scrollToBottom();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Send failed: $e')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
