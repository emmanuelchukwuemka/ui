import 'package:flutter/material.dart';
import 'package:chat_ui/models/chat_item.dart';
import 'package:chat_ui/models/message.dart';
import 'package:chat_ui/widgets/message_bubble.dart';
import 'package:chat_ui/widgets/input_area.dart';
import 'package:chat_ui/widgets/profile_panel.dart';
import 'package:chat_ui/utils/themes.dart';
import 'package:chat_ui/utils/enums.dart';

class ChatScreen extends StatefulWidget {
  final ChatItem chat;

  const ChatScreen({super.key, required this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ChatItem _chat;
  late List<Message> _messages;

  @override
  void initState() {
    super.initState();
    _chat = widget.chat;
    _messages = [
      Message(
        id: '1',
        text: 'Hey there! How is it going?',
        me: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      Message(
        id: '2',
        text: 'All good! Just working on the Flutter app.',
        me: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
        viewed: true,
      ),
      Message(
        id: '3',
        text: 'Check out this post!',
        me: false,
        isFeedLink: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 6)),
      ),
      Message(
        id: '4',
        text: 'Private Photo',
        me: false,
        viewOnce: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      Message(
        id: '5',
        text: 'Great! Did you see the new designs?',
        me: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppThemes.getThemeFromIndex(_chat.themeIndex),
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_chat.name, style: const TextStyle(fontSize: 16)),
              Text(
                _chat.chatMode.label,
                style: TextStyle(fontSize: 12, color: Colors.teal.shade200),
              ),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.videocam), onPressed: () {}),
            IconButton(icon: const Icon(Icons.call), onPressed: () {}),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _openProfilePanel(),
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).scaffoldBackgroundColor,
                Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  reverse: true, // New messages at bottom
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[_messages.length - 1 - index];
                    return MessageBubble(
                      message: message,
                      themeIndex: _chat.themeIndex,
                      onTap: () => _handleMessageTap(message),
                    );
                  },
                ),
              ),
              InputArea(
                chatMode: _chat.chatMode,
                onSendText: (text) {
                  setState(() {
                    _messages.add(Message(
                      id: DateTime.now().toString(),
                      text: text,
                      me: true,
                      timestamp: DateTime.now(),
                    ));
                  });
                },
                onStartVoice: () {
                  // Simulate recording
                },
                onStopVoice: () {
                  setState(() {
                    _messages.add(Message(
                      id: DateTime.now().toString(),
                      text: "Voice Note",
                      me: true,
                      isVoice: true,
                      timestamp: DateTime.now(),
                    ));
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMessageTap(Message message) {
    if (message.viewOnce && !message.viewed) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("View Once Message"),
          content: const Text("This message will disappear after you close it."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  final index = _messages.indexWhere((m) => m.id == message.id);
                  if (index != -1) {
                    _messages[index] = _messages[index].copyWith(viewed: true);
                  }
                });
              },
              child: const Text("View"),
            ),
          ],
        ),
      );
    } else if (message.isFeedLink) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Simulating navigation to Feed Post...")),
      );
    }
  }

  void _openProfilePanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfilePanel(
        chat: _chat,
        onUpdate: (updatedChat) {
          setState(() => _chat = updatedChat);
        },
      ),
    ).then((_) {
      // Logic for when modal closes
    });
  }
}
