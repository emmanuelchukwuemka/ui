import 'package:flutter/material.dart';
import 'package:chat_ui/models/chat_item.dart';
import 'package:chat_ui/widgets/chat_item_tile.dart';
import 'package:chat_ui/screens/chat_screen.dart';
import 'package:chat_ui/utils/enums.dart';

class ChatsHome extends StatefulWidget {
  const ChatsHome({super.key});

  @override
  State<ChatsHome> createState() => _ChatsHomeState();
}

class _ChatsHomeState extends State<ChatsHome> {
  bool _isPinnedExpanded = true;

  // Mock Data
  late List<ChatItem> _chats;

  @override
  void initState() {
    super.initState();
    _chats = [
      ChatItem(
        id: '1',
        name: 'Tech Group',
        lastMessage: 'Let\'s discuss the new architecture.',
        unread: 3,
        pinned: true,
        chatMode: ChatMode.textOnly,
      ),
      ChatItem(
        id: '2',
        name: 'Sarah Connor',
        lastMessage: 'Voice note received',
        pinned: true,
        chatMode: ChatMode.voiceOnly,
      ),
      ChatItem(
        id: '3',
        name: 'James Wilson',
        lastMessage: 'Hey, are we still meeting today?',
        unread: 1,
        chatMode: ChatMode.mixed,
      ),
      ChatItem(
        id: '4',
        name: 'Pizza Hut',
        lastMessage: 'Your order is on the way!',
        chatMode: ChatMode.textOnly,
      ),
      ChatItem(
        id: '5',
        name: 'Company Hotline',
        lastMessage: 'Press 1 for support',
        chatMode: ChatMode.callsOnly,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pinnedChats = _chats.where((c) => c.pinned).toList();
    final regularChats = _chats.where((c) => !c.pinned).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: ListView(
        children: [
          if (pinnedChats.isNotEmpty) ...[
            _buildSectionHeader("PINNED", _isPinnedExpanded, () {
              setState(() => _isPinnedExpanded = !_isPinnedExpanded);
            }),
            if (_isPinnedExpanded)
              ...pinnedChats.map((chat) => ChatItemTile(
                    chat: chat,
                    onTap: () => _navigateToChat(chat),
                  )),
          ],
          _buildSectionHeader("ALL MESSAGES", false, null),
          ...regularChats.map((chat) => ChatItemTile(
                chat: chat,
                onTap: () => _navigateToChat(chat),
              )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.teal,
        child: const Icon(Icons.chat_bubble, color: Colors.white),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isExpanded, VoidCallback? onToggle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          if (onToggle != null)
            IconButton(
              icon: Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: Colors.grey,
              ),
              onPressed: onToggle,
            ),
        ],
      ),
    );
  }

  void _navigateToChat(ChatItem chat) async {
    final updatedChat = await Navigator.push<ChatItem>(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(chat: chat),
      ),
    );

    if (updatedChat != null) {
      setState(() {
        final index = _chats.indexWhere((c) => c.id == updatedChat.id);
        if (index != -1) {
          _chats[index] = updatedChat;
        }
      });
    }
  }
}
