import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final bool isMe;
  final String text;
  final String time;
  final Color? bgColor;
  final Color? textColor;

  const MessageBubble({
    super.key,
    required this.isMe,
    required this.text,
    required this.time,
    this.bgColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(16);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: bgColor ?? (isMe ? Colors.blue : Colors.grey.shade200),
          borderRadius: BorderRadius.only(
            topLeft: radius,
            topRight: radius,
            bottomLeft: isMe ? radius : Radius.zero,
            bottomRight: isMe ? Radius.zero : radius,
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: textColor ?? (isMe ? Colors.white : Colors.black87),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: (textColor ?? (isMe ? Colors.white : Colors.black87))
                    // ignore: deprecated_member_use
                    .withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
