import 'package:flutter/material.dart';
import 'package:chat_ui/models/chat_item.dart';
import 'package:chat_ui/utils/enums.dart';

class ChatItemTile extends StatelessWidget {
  final ChatItem chat;
  final VoidCallback onTap;

  const ChatItemTile({
    super.key,
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey.shade800,
            child: Text(
              chat.name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: _buildModeIndicator(),
          ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chat.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (chat.pinned)
            const Icon(Icons.push_pin, size: 14, color: Colors.grey),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              chat.lastMessage,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (chat.unread > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                chat.unread.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildModeIndicator() {
    IconData iconData;
    Color color;

    switch (chat.chatMode) {
      case ChatMode.textOnly:
        iconData = Icons.text_snippet;
        color = Colors.blue;
        break;
      case ChatMode.voiceOnly:
        iconData = Icons.mic;
        color = Colors.orange;
        break;
      case ChatMode.callsOnly:
        iconData = Icons.phone;
        color = Colors.green;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Icon(iconData, size: 12, color: color),
    );
  }
}
