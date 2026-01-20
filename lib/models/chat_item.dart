import 'package:flutter/material.dart';
import 'package:chat_ui/utils/enums.dart';

class ChatItem {
  final String id;
  final String name;
  final String lastMessage;
  final int unread;
  final ChatMode chatMode;
  final bool pinned;
  final bool muted;
  final DisappearingOption disappearing;
  final bool autoClearEnabled;
  final TimeOfDay? autoClearStart;
  final TimeOfDay? autoClearEnd;
  final int themeIndex;
  final String? notificationTone;

  ChatItem({
    required this.id,
    required this.name,
    required this.lastMessage,
    this.unread = 0,
    this.chatMode = ChatMode.mixed,
    this.pinned = false,
    this.muted = false,
    this.disappearing = DisappearingOption.off,
    this.autoClearEnabled = false,
    this.autoClearStart,
    this.autoClearEnd,
    this.themeIndex = 0,
    this.notificationTone,
  });

  ChatItem copyWith({
    String? id,
    String? name,
    String? lastMessage,
    int? unread,
    ChatMode? chatMode,
    bool? pinned,
    bool? muted,
    DisappearingOption? disappearing,
    bool? autoClearEnabled,
    TimeOfDay? autoClearStart,
    TimeOfDay? autoClearEnd,
    int? themeIndex,
    String? notificationTone,
  }) {
    return ChatItem(
      id: id ?? this.id,
      name: name ?? this.name,
      lastMessage: lastMessage ?? this.lastMessage,
      unread: unread ?? this.unread,
      chatMode: chatMode ?? this.chatMode,
      pinned: pinned ?? this.pinned,
      muted: muted ?? this.muted,
      disappearing: disappearing ?? this.disappearing,
      autoClearEnabled: autoClearEnabled ?? this.autoClearEnabled,
      autoClearStart: autoClearStart ?? this.autoClearStart,
      autoClearEnd: autoClearEnd ?? this.autoClearEnd,
      themeIndex: themeIndex ?? this.themeIndex,
      notificationTone: notificationTone ?? this.notificationTone,
    );
  }
}
