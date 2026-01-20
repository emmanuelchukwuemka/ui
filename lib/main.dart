import 'package:flutter/material.dart';
import 'package:chat_ui/screens/chats_home.dart';
import 'package:chat_ui/utils/themes.dart';
import 'package:chat_ui/utils/constants.dart';

void main() {
  runApp(const ChatUIApp());
}

class ChatUIApp extends StatelessWidget {
  const ChatUIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppThemes.defaultDark,
      home: const ChatsHome(),
    );
  }
}
