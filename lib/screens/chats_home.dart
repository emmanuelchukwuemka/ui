import 'package:flutter/material.dart';
import 'package:chat_ui/models/chat_item.dart';
import 'package:chat_ui/widgets/chat_item_tile.dart';
import 'package:chat_ui/screens/chat_screen.dart';
import 'package:chat_ui/utils/enums.dart';
import 'package:chat_ui/services/hapztext_api_service.dart';
import 'package:chat_ui/services/chat_api_service.dart';
import 'package:provider/provider.dart';
import 'package:chat_ui/services/auth_provider.dart';

class ChatsHome extends StatefulWidget {
  const ChatsHome({super.key});

  @override
  State<ChatsHome> createState() => _ChatsHomeState();
}

class _ChatsHomeState extends State<ChatsHome> {
  bool _isPinnedExpanded = true;
  final HapzTextApiService _apiService = HapzTextApiService();
  late ChatApiService _chatApiService;

  // Mock Data
  List<ChatItem> _chats = [];

  @override
  void initState() {
    super.initState();
    _chatApiService = ChatApiService(_apiService);
    
    // Initialize with some mock data first or empty
    _chats = [
      ChatItem(
        id: '1',
        name: 'Tech Enthusiasts',
        lastMessage: 'The new Flutter update is amazing! 🚀',
        unread: 3,
        pinned: true,
        chatMode: ChatMode.mixed,
        themeIndex: 0,
      ),
      ChatItem(
        id: '2',
        name: 'Sarah Wilson',
        lastMessage: 'Voice Note (0:45)',
        unread: 1,
        pinned: true,
        chatMode: ChatMode.voiceOnly,
        themeIndex: 1,
      ),
      ChatItem(
        id: '3',
        name: 'Project Alpha',
        lastMessage: 'Meeting moved to 3 PM tomorrow.',
        unread: 0,
        pinned: false,
        chatMode: ChatMode.textOnly,
        themeIndex: 2,
      ),
      ChatItem(
        id: '4',
        name: 'Crypto Chat',
        lastMessage: 'Check out the new market trends! 📈',
        unread: 12,
        pinned: false,
        chatMode: ChatMode.mixed,
        themeIndex: 3,
      ),
      ChatItem(
        id: '5',
        name: 'Family Group',
        lastMessage: 'Dinner at 7?',
        unread: 0,
        pinned: false,
        chatMode: ChatMode.callsOnly,
        themeIndex: 0,
      ),
      ChatItem(
        id: '6',
        name: 'Design Team',
        lastMessage: 'Sent a prototype link.',
        unread: 0,
        pinned: false,
        chatMode: ChatMode.mixed,
        themeIndex: 1,
      ),
    ];
  }

  Future<void> _loadConversations() async {
    try {
      // Assuming we have a logged in user token set in _apiService somewhere globally or passed down
      // For now just fetching
      final conversations = await _chatApiService.getConversations();
      if (mounted) {
        setState(() {
          // Merge or replace. For simplicity, we can append specific API chats
          // preventing duplicates if IDs clash with mocks
          for (var conv in conversations) {
             final index = _chats.indexWhere((c) => c.id == conv.id);
             if (index != -1) {
               _chats[index] = conv;
             } else {
               _chats.add(conv);
             }
          }
        });
      }
    } catch (e) {
      print('Error loading conversations: $e');
    }
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
