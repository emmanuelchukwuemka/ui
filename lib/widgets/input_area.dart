import 'package:flutter/material.dart';
import 'package:chat_ui/utils/enums.dart';

class InputArea extends StatefulWidget {
  final ChatMode chatMode;
  final Function(String) onSendText;
  final VoidCallback onStartVoice;
  final VoidCallback onStopVoice;

  const InputArea({
    super.key,
    required this.chatMode,
    required this.onSendText,
    required this.onStartVoice,
    required this.onStopVoice,
  });

  @override
  State<InputArea> createState() => _InputAreaState();
}

class _InputAreaState extends State<InputArea> {
  final TextEditingController _controller = TextEditingController();
  bool _isRecording = false;

  @override
  Widget build(BuildContext context) {
    if (widget.chatMode == ChatMode.callsOnly) {
      return _buildCallsOnlyInput();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.teal),
              onPressed: () {},
            ),
            Expanded(
              child: widget.chatMode == ChatMode.voiceOnly
                  ? _buildVoicePrompt()
                  : TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
            ),
            if (widget.chatMode != ChatMode.voiceOnly)
              IconButton(
                icon: const Icon(Icons.send, color: Colors.teal),
                onPressed: () {
                  if (_controller.text.isNotEmpty) {
                    widget.onSendText(_controller.text);
                    _controller.clear();
                  }
                },
              ),
            if (widget.chatMode != ChatMode.textOnly)
              GestureDetector(
                onLongPressStart: (_) {
                  setState(() => _isRecording = true);
                  widget.onStartVoice();
                },
                onLongPressEnd: (_) {
                  setState(() => _isRecording = false);
                  widget.onStopVoice();
                },
                child: CircleAvatar(
                  backgroundColor: _isRecording ? Colors.red : Colors.teal,
                  child: Icon(
                    _isRecording ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoicePrompt() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: const Text(
        "Hold mic to record voice note",
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCallsOnlyInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.phone),
                label: const Text("Voice Call"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.videocam),
                label: const Text("Video Call"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
