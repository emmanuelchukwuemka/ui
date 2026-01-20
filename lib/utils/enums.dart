import 'package:flutter/material.dart';

enum ChatMode {
  mixed,
  textOnly,
  voiceOnly,
  callsOnly,
}

enum DisappearingOption {
  off,
  fiveSeconds,
  oneHour,
  oneDay,
}

enum ThemeType {
  defaultDark,
  blueGradient,
  purpleNeon,
  greenDark,
}

extension ChatModeExtension on ChatMode {
  String get label {
    switch (this) {
      case ChatMode.mixed:
        return 'Mixed';
      case ChatMode.textOnly:
        return 'Text Only';
      case ChatMode.voiceOnly:
        return 'Voice Only';
      case ChatMode.callsOnly:
        return 'Calls Only';
    }
  }

  IconData get icon {
    switch (this) {
      case ChatMode.mixed:
        return Icons.chat;
      case ChatMode.textOnly:
        return Icons.text_snippet;
      case ChatMode.voiceOnly:
        return Icons.mic;
      case ChatMode.callsOnly:
        return Icons.phone;
    }
  }
}

extension DisappearingOptionExtension on DisappearingOption {
  String get label {
    switch (this) {
      case DisappearingOption.off:
        return 'Off';
      case DisappearingOption.fiveSeconds:
        return '5 Seconds';
      case DisappearingOption.oneHour:
        return '1 Hour';
      case DisappearingOption.oneDay:
        return '1 Day';
    }
  }

  Duration? get duration {
    switch (this) {
      case DisappearingOption.off:
        return null;
      case DisappearingOption.fiveSeconds:
        return const Duration(seconds: 5);
      case DisappearingOption.oneHour:
        return const Duration(hours: 1);
      case DisappearingOption.oneDay:
        return const Duration(days: 1);
    }
  }
}
