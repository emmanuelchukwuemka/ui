import 'package:flutter/material.dart';
import 'package:chat_ui/models/message.dart';
import 'package:chat_ui/utils/themes.dart';
import 'package:chat_ui/utils/constants.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final int themeIndex;
  final VoidCallback? onTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.themeIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.me ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: () => _showMessageMenu(context),
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppConstants.hPadding,
            vertical: 4,
          ),
          padding: const EdgeInsets.all(AppConstants.messagePadding),
          decoration: BoxDecoration(
            color: AppThemes.getBubbleColor(themeIndex, message.me),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(AppConstants.bubbleRadius),
              topRight: const Radius.circular(AppConstants.bubbleRadius),
              bottomLeft: Radius.circular(message.me ? AppConstants.bubbleRadius : 0),
              bottomRight: Radius.circular(message.me ? 0 : AppConstants.bubbleRadius),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment:
                message.me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (message.isVoice)
                _buildVoiceMessage()
              else if (message.viewOnce)
                _buildViewOnceMessage()
              else if (message.isFeedLink)
                _buildFeedLink()
              else
                Text(
                  message.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                  if (message.me) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.viewed ? Icons.done_all : Icons.done,
                      size: 14,
                      color: message.viewed ? Colors.blueAccent : Colors.grey,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text("Reply"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text("Copy Text"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Delete", style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceMessage() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.play_arrow, color: Colors.white),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 2,
            color: Colors.white.withValues(alpha: 0.3),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.6,
              child: Container(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          "0:42",
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildViewOnceMessage() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          message.viewed ? Icons.visibility_off : Icons.visibility,
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          message.viewed ? "Opened" : "Tap to view",
          style: const TextStyle(
            color: Colors.white,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildFeedLink() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.link, color: Colors.blueAccent, size: 16),
              SizedBox(width: 8),
              Text(
                "View on Feed",
                style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
